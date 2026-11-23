# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "metanorma/plugin/lutaml/xml_data_loader"

RSpec.describe Metanorma::Plugin::Lutaml::XmlDataValueCheck do
  let(:loader) { Metanorma::Plugin::Lutaml::XmlDataLoader.new }
  let(:error) { Metanorma::Plugin::Lutaml::XmlDataLoader::Error }

  def load_value(type, text)
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "main.xsd"), schema(type))
      File.write(File.join(dir, "data.xml"),
                 %(<a:Root xmlns:a="urn:a"><a:v>#{text}</a:v></a:Root>))
      loader.load(File.join(dir, "main.xsd"), File.join(dir, "data.xml"))
        .fetch("Root").v
    end
  end

  def schema(type)
    <<~XSD
      <xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
        targetNamespace="urn:a" elementFormDefault="qualified">
        <xs:element name="Root"><xs:complexType><xs:sequence>
          <xs:element name="v" type="#{type}"/>
        </xs:sequence></xs:complexType></xs:element>
      </xs:schema>
    XSD
  end

  describe "text split by comments, instructions and CDATA" do
    {
      "a comment before the text" => ["<!--c-->text", "text"],
      "a comment inside the text" => ["keep<!--x-->this", "keepthis"],
      "a processing instruction" => ["a<?pi x?>b", "ab"],
      "CDATA between text" => ["a<![CDATA[b]]>c", "abc"],
      "CDATA holding markup" => ["x<![CDATA[<y>]]>z", "x<y>z"],
      "CDATA alone" => ["<![CDATA[only]]>", "only"],
    }.each do |name, (source, expected)|
      it "binds #{name} as one value" do
        expect(load_value("xs:string", source)).to eq(expected)
      end
    end

    it "binds an integer split by a comment" do
      expect(load_value("xs:integer", "1<!--x-->2")).to eq(12)
    end
  end

  describe "values the type layer misreads" do
    {
      "an octal-looking integer" => ["xs:integer", "0100"],
      "a larger octal-looking integer" => ["xs:int", "0777"],
      "an integer beyond float precision" =>
        ["xs:integer", "123456789012345678901234567890"],
      "an infinite float" => ["xs:float", "INF"],
      "a negative infinite double" => ["xs:double", "-INF"],
      "a float that is not a number" => ["xs:float", "NaN"],
      "a date in the calendar reform gap" => ["xs:date", "1582-10-10"],
      "a dateTime in the calendar reform gap" =>
        ["xs:dateTime", "1582-10-10T00:00:00Z"],
      "a time of day" => ["xs:time", "13:20:00"],
      "a time of day with a zone" => ["xs:time", "13:20:00Z"],
    }.each do |name, (type, text)|
      it "raises for #{name}, naming the element and value" do
        expect { load_value(type, text) }
          .to raise_error(error, /Element v value "#{Regexp.escape(text)}"/)
      end
    end
  end

  describe "values that bind exactly" do
    {
      "-010" => ["xs:integer", "-010", -10],
      "08" => ["xs:integer", "08", 8],
      "01" => ["xs:integer", "01", 1],
      "a plus sign" => ["xs:int", "+7", 7],
      "zero" => ["xs:integer", "0", 0],
      "an integer beyond 2**53 that floats keep" =>
        ["xs:long", "9007199254740993", 9_007_199_254_740_993],
      "a double in exponent form" => ["xs:double", "0.125e2", 12.5],
      "a decimal" => ["xs:decimal", "12.50", BigDecimal("12.5")],
      "a float" => ["xs:float", "1.5", 1.5],
      "a boolean" => ["xs:boolean", "1", true],
    }.each do |name, (type, text, expected)|
      it "keeps #{name}" do
        expect(load_value(type, text)).to eq(expected)
      end
    end

    it "keeps a normal date" do
      expect(load_value("xs:date", "2024-02-29").iso8601).to eq("2024-02-29")
    end

    it "keeps a dateTime without a zone" do
      expect(load_value("xs:dateTime", "2024-02-29T10:20:30").strftime("%F %T"))
        .to eq("2024-02-29 10:20:30")
    end

    it "keeps a dateTime with a zone" do
      value = load_value("xs:dateTime", "2024-02-29T10:20:30+02:00")
      expect(value.to_time).to eq(Time.utc(2024, 2, 29, 8, 20, 30))
    end
  end
end
