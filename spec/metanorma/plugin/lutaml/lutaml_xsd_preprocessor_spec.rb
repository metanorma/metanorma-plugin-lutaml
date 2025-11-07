require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor do
  describe "#process" do
    subject(:output) { File.read("spec/fixtures/lutaml/#{file_name}") }

    context "with macro: lutaml_xsd" do
      context "with content Elements and ComplexTypes of UnitsML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for element in unitsml.element %}

            Name: *{{ element.name }}*

            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for complex_type in unitsml.complex_type %}

            Name: *{{ complex_type.name }}*

            Description: {{ complex_type.annotation.documentation.first.content }}
            {% endfor %}
            ----
          TEXT
        end

        let(:file_name) { "first-unitsml-expected-output-v1.0-csd04.xml" }

        it "correctly renders input" do
          expect(xml_string_content(metanorma_convert(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "with content Elements and ComplexTypes of OMML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},omml, location=https://raw.githubusercontent.com/t-yuki/ooxml-xsd/refs/heads/master]
            ----
            {% for element in omml.element %}

            Name: *{{ element.name }}*
            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},omml]
            ----
            {% for complex_type in omml.complex_type %}

            Name: *{{ complex_type.name }}*
            Description: {{ complex_type.annotation.documentation.first.content }}
            {% endfor %}
            ----
          TEXT
        end

        let(:file_name) { "minimal-unitsml-expected-output-v1.0-csd04.xml" }

        it "correctly renders input" do
          expect(xml_string_content(metanorma_convert(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "with content Elements and ComplexTypes of UnitsML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            [#top]
            = Units Markup language (UnitsML) Schema Documentation unitsml-v1.0

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for element in unitsml.element %}

            [#element_{{element.name}}]

            *Element:* {{ element.name }}

            *Type:* <<complex_type_{{element.type}},{{ element.type }}>>

            *Description:* {{ element.annotation.documentation.first.content }}

            <<#top, &#x2303;>>

            ---
            {% endfor %}

            = Complex Types
            {% for complex_type in unitsml.complex_type %}

            [#complex_type_{{complex_type.name}}]

            *Complex Type:* {{ complex_type.name }}

            *Description:* {{ complex_type.annotation.documentation.first.content }}

            <<#top, &#x2303;>>

            ---
            {% endfor %}

            = Attribute Groups
            {% for attribute_group in unitsml.attribute_group %}

            [#attribute_group_{{attribute_group.name}}]

            *Attribute Group:* {{ attribute_group.name }}

            *Description:* {{ attribute_group.annotation.documentation.first.content }}

            <<#top, &#x2303;>>

            ---
            {% endfor %}
            ----
          TEXT
        end

        let(:file_name) { "unitsml-expected-output-v1.0-csd04.xml" }

        let(:text_regex) do
          %r(Element containing various unit symbols\. Examples[^\.]+\.)
        end

        it "correctly renders input" do
          processed_input = xml_string_content(metanorma_convert(input))
          expect(processed_input).to match(text_regex)
          processed_input.sub!(/\s+#{text_regex}\s+/, "")
          expect(processed_input).to(be_equivalent_to(output))
        end
      end

      context "with UnitsML XSD documentation generation" do
        let(:input) do
          <<~TEXT
            [#top]
            = XSD Templates

            lutaml_xsd::spec/fixtures/lutaml/xsd_schemas/unitsml-v1.0-csd04.xsd[schema, spec/fixtures/lutaml/unitsml_liquid_templates/schema.adoc, templates_dir=spec/fixtures/lutaml/unitsml_liquid_templates]
          TEXT
        end

        let(:file_name) { "unitsml_expected.xml" }

        it "correctly renders input" do
          processed_input = xml_string_content(metanorma_convert(input))
          expect(processed_input).to(be_equivalent_to(output))
        end
      end
    end
  end
end
