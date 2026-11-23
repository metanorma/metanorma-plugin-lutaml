# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "metanorma/plugin/lutaml/xml_data_loader"

RSpec.describe Metanorma::Plugin::Lutaml::XmlDataLoader do
  subject(:loader) { described_class.new }

  let(:fixtures) do
    File.expand_path("../../../fixtures/lutaml/xml_data/unit", __dir__)
  end
  let(:schema) { File.join(fixtures, "catalog.xsd") }
  let(:xml) { File.join(fixtures, "catalog.xml") }
  let(:source) { File.read(xml) }
  let(:temporary_xml) { Tempfile.new(["xml-data", ".xml"]) }
  let(:temporary_schema) { Tempfile.new(["xml-schema", ".xsd"]) }

  after do
    temporary_xml.close!
    temporary_schema.close!
  end

  it "hydrates imported enum collections and attributes into typed objects" do
    model = Dir.chdir(Dir.tmpdir) { loader.load(schema, xml).fetch("Catalog") }
    expect(model).to be_a(Lutaml::Model::Serializable)
    expect(model.category).to eq("navigation")
    expect(model.entry).to eq(%w[active retired])
    expect(model.detail.first.label).to eq("Harbour")
    expect(model.detail.first.code).to eq("H")
    template = Liquid::Template.parse(<<~LIQUID.chomp)
      {{ catalog.category }}:{% for e in catalog.entry %}{{ e }};{% endfor %}
      {% for d in catalog.detail %}{{ d.code }}={{ d.label }}{% endfor %}
    LIQUID
    expect(template.render("catalog" => model.to_liquid))
      .to eq("navigation:active;retired;\nH=Harbour")
  end

  it "validates nested custom types in the private binding register" do
    updated_schema = File.read(schema).sub(
      'name="label" type="xs:string"', 'name="label" type="b:Status"'
    )
    temporary_schema.write(updated_schema)
    temporary_schema.flush
    temporary_xml.write(source.sub("Harbour", "active"))
    temporary_xml.flush
    model = loader.load(temporary_schema.path, temporary_xml.path,
                        location: fixtures).fetch("Catalog")
    expect(model.detail.first.label).to eq("active")
    template = Liquid::Template.parse(
      "{% for detail in catalog.detail %}{{ detail.label }}{% endfor %}",
    )
    expect(template.render("catalog" => model.to_liquid)).to eq("active")
    temporary_xml.rewind
    temporary_xml.truncate(0)
    temporary_xml.write(source.sub("Harbour", "bogus"))
    temporary_xml.flush
    expect do
      loader.load(temporary_schema.path, temporary_xml.path, location: fixtures)
    end.to raise_error(described_class::Error, /enumeration.*bogus/m)
  end

  it "resolves an anonymous root with an equivalent default namespace" do
    model = loader.load(schema,
                        File.join(fixtures, "inline.xml")).fetch("Inline")
    expect(model.label).to eq("Harbour")
  end

  it "binds by namespace URI when instance prefixes change" do
    temporary_xml.write(source.gsub("fc:", "equivalent:")
      .sub("xmlns:fc=", "xmlns:equivalent="))
    temporary_xml.flush
    model = loader.load(schema, temporary_xml.path).fetch("Catalog")
    expect(model.entry).to eq(%w[active retired])
    expect(model.detail.first.code).to eq("H")
  end

  it "resolves imports from an explicit local directory" do
    temporary_xml.write(File.read(schema))
    temporary_xml.flush
    model = loader.load(temporary_xml.path, xml, location: fixtures)
      .fetch("Catalog")
    expect(model.entry).to eq(%w[active retired])
    expect(model.detail.first.label).to eq("Harbour")
  end

  it "rejects invalid enumerations with file context" do
    temporary_xml.write(source.sub("active", "bogus"))
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error,
                      /#{Regexp.escape(schema)}.*bogus/m)
  end

  it "enforces required attributes independently of model validation" do
    temporary_xml.write(source.sub(' category="navigation"', ""))
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error, /category.*required/m)
  end

  it "enforces maximum collection cardinality" do
    detail = "<fc:detail><fc:label>Extra</fc:label></fc:detail>"
    temporary_xml.write(source.sub("</fc:Catalog>",
                                   "#{detail * 2}</fc:Catalog>"))
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error, /detail.*not expected/m)
  end

  it "enforces minimum collection cardinality" do
    temporary_xml.write(source.gsub(%r{<fc:entry>.*?</fc:entry>}, ""))
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error, /Expected is.*entry/)
  end

  it "rejects an undeclared root QName" do
    temporary_xml.write(source.gsub("urn:fc", "urn:wrong"))
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error, /No matching global declaration/)
  end

  it "reports malformed XML and both paths" do
    temporary_xml.write("<Catalog>")
    temporary_xml.flush
    expect { loader.load(schema, temporary_xml.path) }
      .to raise_error(described_class::Error,
                      /Premature/m) do |error|
        expect(error.message).to include(temporary_xml.path, schema)
      end
  end

  it "reports malformed schemas" do
    temporary_xml.write("<xs:schema>")
    temporary_xml.flush
    expect { loader.load(temporary_xml.path, xml) }
      .to raise_error(described_class::Error, /XML data.*XSD.*schema/m)
  end

  it "reports missing files" do
    expect { loader.load(schema, "#{xml}.absent") }
      .to raise_error(described_class::Error,
                      /catalog.xml.absent.*catalog.xsd.*No such file/m)
  end

  it "preserves models from independent schemas with overlapping root names" do
    first = loader.load(schema, xml).fetch("Catalog")
    second = loader.load(File.join(fixtures, "other.xsd"),
                         File.join(fixtures, "other.xml")).fetch("Catalog")
    expect(second.number).to eq(42)
    expect(first.detail.first.label).to eq("Harbour")
    expect(first.entry).to eq(%w[active retired])
  end

  it "cleans private bindings and preserves caller registers" do
    external = Lutaml::Model::GlobalContext.create_context(
      id: :xml_loader_preservation,
    )
    default = Lutaml::Model::GlobalRegister.lookup(:default)
    contexts = Lutaml::Model::GlobalContext.context_ids
    constants = Object.constants.grep(/^LutamlXmlData/)
    features = $LOADED_FEATURES.grep(/lutamlxmldata/)
    3.times { loader.load(schema, xml) }
    expect(Lutaml::Model::GlobalRegister.lookup(:default)).to equal(default)
    expect(Lutaml::Model::GlobalContext.context_ids).to eq(contexts)
    expect(Object.constants.grep(/^LutamlXmlData/)).to eq(constants)
    expect($LOADED_FEATURES.grep(/lutamlxmldata/)).to eq(features)
    expect(Lutaml::Model::GlobalContext.context(:xml_loader_preservation))
      .to equal(external)
  ensure
    Lutaml::Model::GlobalRegister.remove(:xml_loader_preservation)
  end
end
