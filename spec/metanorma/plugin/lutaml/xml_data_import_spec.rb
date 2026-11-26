# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "metanorma/plugin/lutaml/xml_data_loader"

# Schemas assembled from several files: which file a reference names, and
# markup in annotations that is not part of the schema.
# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Metanorma::Plugin::Lutaml::XmlDataLoader do
  subject(:loader) { described_class.new }

  let(:xs) { 'xmlns:xs="http://www.w3.org/2001/XMLSchema"' }
  let(:data) do
    '<a:R xmlns:a="urn:a" xmlns:b="urn:b"><b:x>007</b:x></a:R>'
  end

  def load_files(files, xml, root: "main.xsd")
    Dir.mktmpdir("xml-import") do |dir|
      files.each { |name, content| File.write(File.join(dir, name), content) }
      File.write(File.join(dir, "data.xml"), xml)
      loader.load(File.join(dir, root), File.join(dir, "data.xml")).fetch("R")
    end
  end

  def importing_schema(location)
    <<~XSD
      <xs:schema #{xs} targetNamespace="urn:a" xmlns:a="urn:a"
        xmlns:b="urn:b" elementFormDefault="qualified">
        <xs:import namespace="urn:b" schemaLocation="#{location}"/>
        <xs:element name="R"><xs:complexType><xs:sequence>
          <xs:element ref="b:x"/>
        </xs:sequence></xs:complexType></xs:element>
      </xs:schema>
    XSD
  end

  def imported_schema(type)
    <<~XSD
      <xs:schema #{xs} targetNamespace="urn:b" elementFormDefault="qualified">
        <xs:element name="x" type="#{type}"/>
      </xs:schema>
    XSD
  end

  describe "a percent-encoded schemaLocation" do
    it "opens the file the decoded location names" do
      files = { "main.xsd" => importing_schema("b%20c.xsd"),
                "b c.xsd" => imported_schema("xs:string"),
                "b%20c.xsd" => imported_schema("xs:integer") }
      expect(load_files(files, data).x).to eq("007")
    end

    it "opens a file that exists only under the decoded name" do
      files = { "main.xsd" => importing_schema("b%20c.xsd"),
                "b c.xsd" => imported_schema("xs:string") }
      expect(load_files(files, data).x).to eq("007")
    end
  end

  describe "an element inside xs:appinfo" do
    let(:schema) do
      <<~XSD
        <xs:schema #{xs}>
          <xs:element name="R">
            <xs:annotation><xs:appinfo><xs:element name="tool"/></xs:appinfo>
            </xs:annotation>
            <xs:complexType><xs:sequence>
              <xs:element name="a" type="xs:string"/>
            </xs:sequence></xs:complexType>
          </xs:element>
        </xs:schema>
      XSD
    end

    it "is not part of the schema" do
      model = load_files({ "main.xsd" => schema }, "<R><a>x</a></R>")
      expect(model.a).to eq("x")
    end
  end
end
