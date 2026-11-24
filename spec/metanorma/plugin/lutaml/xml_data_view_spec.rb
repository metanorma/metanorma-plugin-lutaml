require "spec_helper"

# Liquid-facing behaviour of XML data bound through an XSD: what a template
# sees, and what reaches the document.
RSpec.describe Metanorma::Plugin::Lutaml::XmlDataView do
  def convert_to_xml(input)
    xml_string_content(metanorma_convert(input))
  end

  let(:schema) { fixtures_path("xml_data/view/doc.xsd") }
  let(:instance) { "doc.xml" }
  let(:template) { "{{ doc.Doc.title }}" }
  let(:input) do
    <<~TEXT
      = Document title
      Author
      :docfile: test.adoc
      :nodoc:
      :novalid:
      :no-isobib:

      [lutaml_data,#{schema},#{fixtures_path("xml_data/view/#{instance}")},doc]
      ----
      #{template}
      ----
    TEXT
  end

  def render(liquid)
    loaded = Metanorma::Plugin::Lutaml::XmlDataLoader.new.load(
      schema, fixtures_path("xml_data/view/#{instance}")
    )
    Liquid::Template.parse(liquid).render!(
      { "doc" => loaded }, strict_variables: true, strict_filters: true
    )
  end

  describe "text that reads as an AsciiDoc directive" do
    it "does not include the named file when a value starts with include::" do
      output = convert_to_xml(input)
      expect(output).not_to include("SECRET-FILE-CONTENT-7731")
      expect(output).to include("include::spec/fixtures/lutaml/xml_data/view")
    end

    context "when the directive is on a later line of a value" do
      let(:instance) { "multiline.xml" }
      let(:template) { "{{ doc.Doc.note }}" }

      it "does not include the named file" do
        output = convert_to_xml(input)
        expect(output).not_to include("SECRET-FILE-CONTENT-7731")
        expect(output).to include("first line")
      end
    end

    it "leaves ordinary text unchanged" do
      expect(render("{{ doc.Doc.id }}")).to eq("d1")
    end
  end

  describe "optional elements" do
    let(:liquid) do
      "{% if doc.Doc.note %}has{% else %}none{% endif %}|" \
        "{% if doc.Doc.meta %}meta{% else %}nometa{% endif %}"
    end

    it "is false in a condition when absent and true when present" do
      expect(render(liquid)).to eq("none|meta")
    end

    it "keeps the list of values of a present element" do
      expect(render("{{ doc.Doc.meta[0].k }}")).to eq("v")
    end
  end

  describe "a template that does not match the schema" do
    it "raises for a field the schema does not declare" do
      expect { render("{{ doc.Doc.typo }}") }
        .to raise_error(Liquid::UndefinedDropMethod)
    end

    it "raises when a structure is printed" do
      expect { render("{{ doc.Doc.meta[0] }}") }
        .to raise_error(Liquid::Error, /cannot print a structure/)
    end
  end

  describe "a template error in a document" do
    let(:template) { "before {{ doc.Doc.typo }} after" }

    it "fails the block and writes no Liquid error into the document" do
      allow(Metanorma::Util).to receive(:log)
      expect { convert_to_xml(input) }.to raise_error(Liquid::Error)
      expect(Metanorma::Util).to have_received(:log)
        .with(/Failed to parse LutaML data block/, :error)
    end

    context "with an unknown filter" do
      let(:template) { "{{ doc.Doc.title | no_such_filter }}" }

      it "fails the block" do
        allow(Metanorma::Util).to receive(:log)
        expect { convert_to_xml(input) }
          .to raise_error(Liquid::Error, /no_such_filter/)
      end
    end

    context "with a malformed tag" do
      let(:template) { "{% if doc.Doc.title %}never closed" }

      it "fails the block" do
        allow(Metanorma::Util).to receive(:log)
        expect { convert_to_xml(input) }.to raise_error(Liquid::Error)
      end
    end
  end
end
