require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor do
  describe "#process" do
    subject(:output) { File.read("spec/fixtures/lutaml/#{file_name}") }

    context "with macro: lutaml_xsd" do
      context "with lutaml-model XSD helpers" do
        let(:schema_path) { fixtures_path("xsd_schemas/person.xsd") }
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{schema_path},schema]
            ----
            {% for element in schema.elements_sorted_by_name %}
            Name: *{{ element.name }}*
            Type: *{{ element.type }}*
            Target prefix: {{ element.target_prefix }}
            Used by: {{ element.used_by | map: "name" | join: ", " }}
            {% endfor %}

            = Complex Types
            {% for complex_type in schema.complex_types_sorted_by_name %}
            Name: *{{ complex_type.name }}*
            Children: {{ complex_type.child_elements | map: "name" | join: ", " }}
            Attributes: {{ complex_type.attribute_elements | map: "name" | join: ", " }}
            Used by: {{ complex_type.used_by | map: "name" | join: ", " }}
            {% endfor %}

            = Attribute Groups
            {% for attribute_group in schema.attribute_groups_sorted_by_name %}
            Attribute Group: *{{ attribute_group.name }}*
            Used by: {{ attribute_group.used_by | map: "name" | join: ", " }}
            {% endfor %}
            ----
          TEXT
        end

        it "renders schema components through lutaml-model Liquid methods" do
          rendered_xml = xml_string_content(metanorma_convert(input))
            .gsub(/\s+/, " ")

          expected_fragments.each do |fragment|
            expect(rendered_xml).to(include(fragment))
          end
        end
      end

      context "with the default import/include location" do
        let(:schema_path) { fixtures_path("xsd_schemas/person.xsd") }
        let(:schema_dir) { File.dirname(schema_path) }
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,#{schema_path},schema]
            ----
            {{ schema.element.size }}
            ----
          TEXT
        end

        it "uses the schema directory" do
          expect(::Lutaml::Xml::Schema::Xsd).to receive(:parse)
            .with(kind_of(String), location: schema_dir)
            .and_call_original

          metanorma_convert(input)
        end
      end

      context "with a location option" do
        let(:schema_path) { fixtures_path("xsd_schemas/person.xsd") }
        let(:schema_dir) { File.dirname(schema_path) }
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,#{schema_path},schema, location=#{schema_dir}]
            ----
            {{ schema.element.size }}
            ----
          TEXT
        end

        it "passes the explicit location to lutaml-model" do
          expect(::Lutaml::Xml::Schema::Xsd).to receive(:parse)
            .with(kind_of(String), location: schema_dir)
            .and_call_original

          metanorma_convert(input)
        end
      end

      context "with a missing XSD file" do
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,missing.xsd,schema]
            ----
            {{ schema.element.size }}
            ----
          TEXT
        end

        it "raises an XSD-specific loading error" do
          expect { metanorma_convert(input) }.to raise_error(
            StandardError,
            /Unable to load XSD file for `missing.xsd`/,
          )
        end
      end

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
          expect_equivalent_document(
            xml_string_content(metanorma_convert(input)),
            output,
          )
        end
      end

      context "with content Elements and ComplexTypes of OMML schema" do
        let(:schema_path) { fixtures_path("xsd_schemas/omml.xsd") }
        let(:schema_dir) { File.dirname(schema_path) }
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{schema_path},omml, location=#{schema_dir}]
            ----
            {% for element in omml.element %}

            Name: *{{ element.name }}*
            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{schema_path},omml]
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
          expect_equivalent_document(
            xml_string_content(metanorma_convert(input)),
            output,
          )
        end
      end

      context "with UnitsML schema documentation content" do
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
          expect_equivalent_document(processed_input, output)
        end
      end

      context "with UnitsML XSD documentation generation" do
        let(:schema_path) do
          "spec/fixtures/lutaml/xsd_schemas/unitsml-v1.0-csd04.xsd"
        end
        let(:template_path) do
          "spec/fixtures/lutaml/unitsml_liquid_templates/schema.adoc"
        end
        let(:include_path) do
          "spec/fixtures/lutaml/unitsml_liquid_templates"
        end
        let(:input) do
          <<~TEXT
            [#top]
            = XSD Templates

            lutaml_xsd::#{schema_path}[schema, #{template_path}, include_path=#{include_path}]
          TEXT
        end

        let(:file_name) { "unitsml_expected.xml" }

        it "correctly renders input" do
          processed_input = xml_string_content(metanorma_convert(input))
          expect_equivalent_document(processed_input, output)
        end
      end

      def expect_equivalent_document(actual, expected)
        expect(normalize_metanorma_header(actual))
          .to(be_equivalent_to(normalize_metanorma_header(expected)))
      end

      def normalize_metanorma_header(xml)
        xml
          .sub(/(<metanorma\b[^>]*\bversion=)"[^"]+"/, '\1"_"')
          .sub(%r{(<copyright>\s*<from>)\d{4}(</from>)}, '\1_\2')
      end

      def expected_fragments
        File
          .readlines(
            fixtures_path("expected/xsd_person_fragments.xml"),
            chomp: true,
          )
          .reject(&:empty?)
          .map { |fragment| fragment.gsub(/\s+/, " ") }
      end
    end
  end
end
