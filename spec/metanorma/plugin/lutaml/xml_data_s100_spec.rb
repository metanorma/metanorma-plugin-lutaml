require "spec_helper"
require "digest"
require "json"
require "tmpdir"

# Corpus acceptance lives separately from the synthetic loader unit specs.
# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Metanorma::Plugin::Lutaml::XmlDataLoader do
  let(:schema_path) { File.join(fixtures_path("xml_data/s100"), "S100FC.xsd") }
  let(:xml_path) { File.join(fixtures_path("xml_data/s100"), "S411FC.xml") }
  let(:source) { Nokogiri::XML(File.read(xml_path)) }
  let(:namespaces) do
    { "fc" => "http://www.iho.int/S100FC",
      "base" => "http://www.iho.int/S100Base",
      "ci" => "http://www.iho.int/S100CI" }
  end
  let(:features) { source.xpath("//fc:featureType", namespaces) }
  let(:attributes) do
    source.xpath("//fc:simpleAttribute | //fc:complexAttribute", namespaces)
  end
  let(:template) do
    File.read(File.join(fixtures_path("xml_data/s100"), "catalogue.liquid"))
  end
  let(:rendered) do
    Liquid::Template.parse(template).render!("fc" => described_class.new.load(
      schema_path, xml_path
    ))
  end

  it "preserves the published bytes and complete local schema closure" do
    manifest = JSON.parse(File.read(File.join(fixtures_path("xml_data/s100"),
                                              "manifest.json")))
    manifest.fetch("files").each do |name, entry|
      path = File.join(fixtures_path("xml_data/s100"), name)
      expect(File.size(path)).to eq(entry.fetch("bytes"))
      expect(Digest::SHA256.file(path).hexdigest).to eq(entry.fetch("sha256"))
      entry.fetch("imports_includes_redefines").each do |dependency|
        expect(File).to exist(File.join(fixtures_path("xml_data/s100"),
                                        dependency))
      end
    end
    schema = Nokogiri::XML::Schema.from_document(
      Nokogiri::XML(File.read(schema_path), schema_path),
    )
    expect(schema.validate(source)).to be_empty
  end

  it "accounts independently for all catalogue identities and references" do
    counts = %w[featureType simpleAttribute complexAttribute listedValue
                attributeBinding subAttributeBinding].map do |name|
      source.xpath("//fc:#{name}", namespaces).size
    end
    expect(counts).to eq([28, 51, 6, 406, 131, 12])
    codes = attributes.map { |node| node.at_xpath("fc:code", namespaces).text }
    expect(codes.uniq.size).to eq(57)
    source.xpath("//fc:attribute/@ref", namespaces).each do |reference|
      expect(codes).to include(reference.value)
    end
    feature_codes = features.map do |node|
      node.at_xpath("fc:code", namespaces).text
    end
    expect(feature_codes.uniq.size).to eq(28)
  end

  # Keep typed and source traversal together to compare complete ownership.
  # rubocop:disable-next RSpec/ExampleLength
  it "preserves every binding's owner, reference and multiplicity" do
    catalog = described_class.new.load(schema_path, xml_path).fetch("Catalog")
    source_bounds = source.xpath(
      "//fc:attributeBinding | //fc:subAttributeBinding", namespaces
    ).map do |binding|
      multiplicity = binding.at_xpath("fc:multiplicity", namespaces)
      upper = multiplicity.at_xpath("base:upper", namespaces)
      [binding.parent.at_xpath("fc:code", namespaces).text,
       binding.at_xpath("fc:attribute/@ref", namespaces).value,
       multiplicity.at_xpath("base:lower", namespaces).text,
       upper.text, upper["infinite"]]
    end
    groups = [
      [catalog.feature_types.feature_type, :attribute_binding],
      [catalog.complex_attributes.flat_map(&:complex_attribute),
       :sub_attribute_binding],
    ]
    loaded_bounds = groups.flat_map do |owners, field|
      owners.flat_map do |owner|
        owner.public_send(field).map do |binding|
          multiplicity = binding.multiplicity
          [owner.code, binding.attribute.ref, multiplicity.lower,
           multiplicity.upper.content, multiplicity.upper.infinite]
        end
      end
    end
    expect(loaded_bounds).to match_array(source_bounds)
  end

  it "preserves the catalogue producer data" do
    catalog = described_class.new.load(schema_path, xml_path).fetch("Catalog")
    producer = catalog.catalog_info.producer
    source_producer = source.at_xpath("/fc:Catalog/fc:catalogInfo/fc:producer",
                                      namespaces)
    expect(producer.individual_name).to eq(
      source_producer.xpath("ci:individualName", namespaces).map(&:text),
    )
    expect(producer.organisation_name).to eq(
      source_producer.xpath("ci:organisationName", namespaces).map(&:text),
    )
    expect(producer.role).to eq(
      source_producer.at_xpath("ci:role", namespaces).text,
    )
  end

  it "preserves the catalogue version date as a Date" do
    catalog = described_class.new.load(schema_path, xml_path).fetch("Catalog")
    source_date = Date.iso8601(source.at_xpath(
      "/fc:Catalog/fc:catalogInfo/fc:versionDate", namespaces
    ).text)
    expect(source_date).to eq(Date.new(2014, 2, 13))
    expect(catalog.catalog_info.version_date).to be_an_instance_of(Date)
    expect(catalog.catalog_info.version_date).to eq(source_date)
  end

  # Keep source reference traversal together to assert clause ownership.
  # rubocop:disable RSpec/ExampleLength
  it "renders every feature and its referenced attributes in its own clause" do
    expect(rendered.scan(/^FEATURE (.+)$/).flatten).to eq(
      features.map { |feature| feature.at_xpath("fc:code", namespaces).text },
    )
    identity_fields = %w[name definition]
    value_fields = %w[code label definition]
    features.each do |feature|
      code = feature.at_xpath("fc:code", namespaces).text
      clause = rendered.split("FEATURE #{code}\n", 2).last&.split(
        "END FEATURE", 2
      )&.first
      expect(clause).not_to be_nil, "missing feature #{code}"
      identity_fields.each do |field|
        expect(clause).to include(feature.at_xpath("fc:#{field}",
                                                   namespaces).text)
      end
      references = feature.xpath("fc:attributeBinding/fc:attribute/@ref",
                                 namespaces).map(&:value)
      until references.empty?
        reference = references.shift
        attribute = attributes.find do |node|
          node.at_xpath("fc:code", namespaces).text == reference
        end
        section = clause.split("ATTRIBUTE #{reference}\n", 2)[1]&.split(
          "ATTRIBUTE ", 2
        )&.first
        expect(section).not_to be_nil,
                               "missing attribute #{reference} in #{code}"
        identity_fields.each do |field|
          expect(section).to include(attribute.at_xpath("fc:#{field}",
                                                        namespaces).text)
        end
        attribute.xpath("fc:listedValue", namespaces).each do |value|
          fields = value_fields.map do |field|
            value.at_xpath("fc:#{field}", namespaces).text
          end
          fields[0] = fields[0].to_i.to_s
          expect(section).to include("VALUE #{fields.join('|')}")
        end
        references.concat(attribute.xpath(
          "fc:subAttributeBinding/fc:attribute/@ref", namespaces
        ).map(&:value))
      end
    end
  end

  # rubocop:enable RSpec/ExampleLength

  it "renders every attribute definition and all 406 listed values" do
    index = rendered.split("ATTRIBUTE INDEX", 2).last
    expect(index).not_to be_nil
    identity_fields = %w[name definition]
    value_fields = %w[code label definition]
    attributes.each do |attribute|
      code = attribute.at_xpath("fc:code", namespaces).text
      section = index.split("ATTRIBUTE #{code}\n", 2)[1]&.split("ATTRIBUTE ",
                                                                2)&.first
      expect(section).not_to be_nil, "missing index attribute #{code}"
      identity_fields.each do |field|
        expect(section).to include(attribute.at_xpath("fc:#{field}",
                                                      namespaces).text)
      end
      values = attribute.xpath("fc:listedValue", namespaces)
      expect(section.scan(/^VALUE /).size).to eq(values.size)
      values.each do |value|
        fields = value_fields.map do |field|
          value.at_xpath("fc:#{field}", namespaces).text
        end
        fields[0] = fields[0].to_i.to_s
        expect(section).to include("VALUE #{fields.join('|')}")
      end
    end
  end

  it "renders the standalone Metanorma example with all feature clauses" do
    example = File.join(fixtures_path("xml_data/s100"), "catalogue.adoc")
    output = Asciidoctor.convert_file(
      example, backend: :standoc, header_footer: true, to_file: false,
               safe: :safe, agree_to_terms: true, attributes: ["nodoc"]
    )
    document = Nokogiri::XML(output)
    clauses = document.xpath("//*[local-name()='clause']")
    names = features.map do |feature|
      feature.at_xpath("fc:name", namespaces).text
    end
    titles = clauses.map do |clause|
      clause.at_xpath("./*[local-name()='title']")&.text
    end
    expect(titles.select { |title| names.include?(title) }).to eq(names)
    features.each do |feature|
      name = feature.at_xpath("fc:name", namespaces).text
      clause = clauses.find do |item|
        item.at_xpath("./*[local-name()='title']")&.text == name
      end
      expect(clause).not_to be_nil, "missing example clause #{name}"
      definition = feature.at_xpath("fc:definition", namespaces).text
      expect(clause.text.scan(/[[:alnum:]]+/).join(" ")).to include(
        definition.scan(/[[:alnum:]]+/).join(" "),
      )
    end
  end

  it "rebuilds changed XML without changing a previously loaded document" do
    original = described_class.new.load(schema_path, xml_path)
    Dir.mktmpdir("s411-rebuild") do |temporary|
      changed_path = File.join(temporary, "S411FC.xml")
      File.write(changed_path,
                 File.read(xml_path).sub("Ice Free", "Changed ice description"))
      changed = described_class.new.load(schema_path, changed_path)
      changed_output = Liquid::Template.parse(template).render!("fc" => changed)
      original_output = Liquid::Template.parse(template).render!(
        "fc" => original,
      )
      expect(changed_output).to include("Changed ice description")
      expect(original_output).to include("Ice Free")
      expect(original_output).not_to include("Changed ice description")
      reloaded = described_class.new.load(schema_path, xml_path)
      expect(Liquid::Template.parse(template).render!("fc" => reloaded))
        .to eq(original_output)
    end
  end
end
