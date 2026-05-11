require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor do
  describe "#process" do
    let(:schema_path) { fixtures_path("xsd_schemas/person.xsd") }
    let(:schema_dir) { File.dirname(schema_path) }
    let(:rendered_xml) { xml_string_content(metanorma_convert(input)) }

    context "with macro: lutaml_xsd" do
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

      it "renders XSD schema components and lutaml-model helpers" do
        expected_fragments.each do |fragment|
          expect(rendered_xml).to(include(fragment))
        end
      end

      it "uses the schema directory as the default include/import location" do
        expect(::Lutaml::Xml::Schema::Xsd).to receive(:parse)
          .with(kind_of(String), location: schema_dir)
          .and_call_original

        rendered_xml
      end

      context "with a location option" do
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

          rendered_xml
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
          expect { rendered_xml }.to raise_error(
            StandardError,
            /Unable to load XSD file for `missing.xsd`/,
          )
        end
      end

      def expected_fragments
        File
          .readlines(fixtures_path("expected/xsd_person_fragments.xml"), chomp: true)
          .reject(&:empty?)
      end
    end
  end
end
