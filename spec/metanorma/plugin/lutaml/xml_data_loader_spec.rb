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

  context "with several schema namespaces" do
    def xsd(namespace, body, imports: "")
      <<~XSD
        <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
          xmlns:a="urn:a" xmlns:b="urn:b"
          #{%(targetNamespace="#{namespace}") if namespace}
          elementFormDefault="qualified">#{imports}#{body}</xs:schema>
      XSD
    end

    def load_files(root_body, other_body, instance, include_other: false)
      Dir.mktmpdir do |dir|
        reference = if include_other
                      '<xs:include schemaLocation="other.xsd"/>'
                    else
                      '<xs:import namespace="urn:b" schemaLocation="other.xsd"/>'
                    end
        other_namespace = include_other ? nil : "urn:b"
        File.write(File.join(dir, "root.xsd"),
                   xsd("urn:a", root_body, imports: reference))
        File.write(File.join(dir, "other.xsd"), xsd(other_namespace, other_body))
        File.write(File.join(dir, "data.xml"), instance)
        loader.load(File.join(dir, "root.xsd"), File.join(dir, "data.xml"))
      end
    end

    let(:holder) do
      '<xs:complexType name="Holder"><xs:sequence>' \
        '<xs:element name="entry" type="xs:string" maxOccurs="unbounded"/>' \
        "</xs:sequence></xs:complexType>"
    end

    it "keeps values of elements qualified by an imported namespace" do
      model = load_files(
        '<xs:element name="Catalog" type="b:Holder"/>', holder,
        '<a:Catalog xmlns:a="urn:a" xmlns:b="urn:b"><b:entry>Harbour</b:entry>' \
        "<b:entry>Coastline</b:entry></a:Catalog>"
      ).fetch("Catalog")
      expect(model.entry).to eq(%w[Harbour Coastline])
    end

    it "resolves a root declared in a chameleon include" do
      model = load_files(
        "", "#{holder}<xs:element name=\"Catalog\" type=\"Holder\"/>",
        '<Catalog xmlns="urn:a"><entry>Harbour</entry></Catalog>',
        include_other: true
      ).fetch("Catalog")
      expect(model.entry).to eq(%w[Harbour])
    end

    it "binds a root from an imported namespace to that namespace's type" do
      root = '<xs:complexType name="Holder"><xs:sequence>' \
             '<xs:element name="n" type="xs:string"/></xs:sequence>' \
             '</xs:complexType><xs:element name="Catalog" type="a:Holder"/>'
      other = "#{holder}<xs:element name=\"Catalog\" type=\"b:Holder\"/>"
      model = load_files(
        root, other,
        '<Catalog xmlns="urn:b"><entry>Harbour</entry></Catalog>'
      ).fetch("Catalog")
      expect(model.entry).to eq(%w[Harbour])
    end

    it "rejects one type name used from two namespaces" do
      root = '<xs:complexType name="Holder"><xs:sequence>' \
             '<xs:element name="inner" type="b:Holder"/></xs:sequence>' \
             '</xs:complexType><xs:element name="Catalog" type="a:Holder"/>'
      instance = '<a:Catalog xmlns:a="urn:a" xmlns:b="urn:b"><a:inner>' \
                 "<b:entry>Harbour</b:entry></a:inner></a:Catalog>"
      expect { load_files(root, holder, instance) }
        .to raise_error(described_class::Error, /several namespaces.*Holder/)
    end

    it "rejects one child name used from two namespaces" do
      root = '<xs:complexType name="Pair"><xs:sequence>' \
             '<xs:element name="entry" type="xs:string"/>' \
             '<xs:element ref="b:entry"/></xs:sequence></xs:complexType>' \
             '<xs:element name="Catalog" type="a:Pair"/>'
      instance = '<a:Catalog xmlns:a="urn:a" xmlns:b="urn:b"><a:entry>x' \
                 "</a:entry><b:entry>y</b:entry></a:Catalog>"
      expect do
        load_files(root, '<xs:element name="entry" type="xs:string"/>',
                   instance)
      end.to raise_error(described_class::Error, /entry is in several/)
    end

    it "rejects an attribute qualified by an imported namespace" do
      root = '<xs:complexType name="Marked">' \
             '<xs:attribute ref="b:code"/></xs:complexType>' \
             '<xs:element name="Catalog" type="a:Marked"/>'
      instance = '<a:Catalog xmlns:a="urn:a" xmlns:b="urn:b" b:code="H"/>'
      expect do
        load_files(root, '<xs:attribute name="code" type="xs:string"/>',
                   instance)
      end.to raise_error(described_class::Error, /code is in an imported/)
    end

    it "keeps a built-in date beside a schema type named Date" do
      root = '<xs:complexType name="Info"><xs:sequence>' \
             '<xs:element name="day" type="xs:date"/>' \
             '<xs:element name="stamp" type="b:Date"/></xs:sequence>' \
             '</xs:complexType><xs:element name="Catalog" type="a:Info"/>'
      other = '<xs:complexType name="Date"><xs:sequence>' \
              '<xs:element name="label" type="xs:string"/>' \
              "</xs:sequence></xs:complexType>"
      model = load_files(
        root, other,
        '<a:Catalog xmlns:a="urn:a" xmlns:b="urn:b"><a:day>2014-02-13</a:day>' \
        "<a:stamp><b:label>Issued</b:label></a:stamp></a:Catalog>"
      ).fetch("Catalog")
      expect(model.day).to eq(Date.new(2014, 2, 13))
      expect(model.stamp.label).to eq("Issued")
    end

    it "rejects a wildcard instead of dropping its content" do
      root = '<xs:complexType name="Open"><xs:sequence>' \
             '<xs:any processContents="lax" maxOccurs="unbounded"/>' \
             '</xs:sequence></xs:complexType>' \
             '<xs:element name="Catalog" type="a:Open"/>'
      expect do
        load_files(root, '<xs:element name="unused" type="xs:string"/>',
                   '<a:Catalog xmlns:a="urn:a"><note>kept?</note></a:Catalog>')
      end.to raise_error(described_class::Error, /wildcard or mixed content/)
    end

    it "rejects mixed content instead of dropping its text" do
      root = '<xs:complexType name="Prose" mixed="true"><xs:sequence>' \
             '<xs:element name="em" type="xs:string"/></xs:sequence>' \
             '</xs:complexType><xs:element name="Catalog" type="a:Prose"/>'
      expect do
        load_files(root, '<xs:element name="unused" type="xs:string"/>',
                   '<a:Catalog xmlns:a="urn:a">text<a:em>x</a:em></a:Catalog>')
      end.to raise_error(described_class::Error, /wildcard or mixed content/)
    end

    it "explains a root of a simple type" do
      expect do
        load_files('<xs:element name="Catalog" type="xs:string"/>',
                   '<xs:element name="unused" type="xs:string"/>',
                   '<Catalog xmlns="urn:a">x</Catalog>')
      end.to raise_error(described_class::Error, /does not compile to an XML/)
    end
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
