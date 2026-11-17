require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlJsonschemaPreprocessor do
  before do
    described_class::CACHE.clear
  end

  let(:schema_path) { fixtures_path("jsonschema/person.schema.json") }
  let(:template_path) { fixtures_path("jsonschema/person.liquid") }
  let(:rendered_xml) { xml_string_content(metanorma_convert(input)) }

  context "with the default reference: lutaml_jsonschema::path[]" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:

        lutaml_jsonschema::#{schema_path}[]
      TEXT
    end

    it "renders the schema annotations as sections and tables" do
      [
        "Person",
        "A person known to the registry.",
        "Full name of the person",
        "Max length: 200",
        "Age in whole years",
        "Minimum: 0",
        "Allowed: author, editor",
        "Postal address of the person.",
        "City name",
      ].each { |fragment| expect(rendered_xml).to include(fragment) }
    end

    it "renders a properties table and links $ref types to definitions" do
      doc = Nokogiri::XML(rendered_xml)
      doc.remove_namespaces!

      expect(doc.xpath("//table").size).to eq(2)
      expect(doc.at_xpath("//*[@anchor='def-person-schema-Address']"))
        .not_to be_nil
      expect(doc.at_xpath("//xref[@target='def-person-schema-Address']"))
        .not_to be_nil
    end
  end

  context "with a template file: lutaml_jsonschema::path[context, template]" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:

        lutaml_jsonschema::#{schema_path}[schema, #{template_path}]
      TEXT
    end

    it "renders the template with the parsed schema" do
      [
        "A person known to the registry.",
        "Full name of the person.",
        "Age in whole years.",
      ].each { |fragment| expect(rendered_xml).to include(fragment) }
      expect(rendered_xml).to include("<tt>name</tt>")
    end
  end

  context "with a block: [lutaml_jsonschema,path,context]" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:

        [lutaml_jsonschema,#{schema_path},schema]
        ----
        == {{ schema.title }} properties

        {% for entry in schema.property_entries %}
        * {{ entry.name }} ({{ entry.schema.type }})
        {% endfor %}
        ----
      TEXT
    end

    it "renders the inline Liquid template with the parsed schema" do
      expect(rendered_xml).to include("Person properties")
      expect(rendered_xml).to include("name (string)")
      expect(rendered_xml).to include("age (integer)")
    end
  end

  context "with a missing schema file" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:

        lutaml_jsonschema::does-not-exist.json[]
      TEXT
    end

    it "raises a clear error" do
      expect { metanorma_convert(input) }
        .to raise_error(StandardError, /Unable to load JSON Schema file/)
    end
  end

  context "with a context name but no template" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:

        lutaml_jsonschema::#{schema_path}[schema]
      TEXT
    end

    it "raises a usage error" do
      expect { metanorma_convert(input) }
        .to raise_error(StandardError, /needs both a context name/)
    end
  end
end
