require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor do
  before do
    described_class.class_variable_set(:@@xsd_cache, {})
  end

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
        allow(Lutaml::Xml::Schema::Xsd).to receive(:parse)
          .and_call_original

        rendered_xml

        expect(Lutaml::Xml::Schema::Xsd).to have_received(:parse)
          .with(kind_of(String), location: schema_dir)
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
          allow(Lutaml::Xml::Schema::Xsd).to receive(:parse)
            .and_call_original

          rendered_xml

          expect(Lutaml::Xml::Schema::Xsd).to have_received(:parse)
            .with(kind_of(String), location: schema_dir)
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

      context "with caching" do
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,#{schema_path},schema]
            ----
            Elements: {{ schema.element.size }}
            ----

            [lutaml_xsd,#{schema_path},schema]
            ----
            Types: {{ schema.complex_type.size }}
            ----
          TEXT
        end

        it "parses the XSD once for duplicate file references" do
          allow(Lutaml::Xml::Schema::Xsd).to receive(:parse)
            .and_call_original

          rendered_xml

          expect(Lutaml::Xml::Schema::Xsd).to have_received(:parse).once
        end

        it "renders both blocks correctly from the cached result" do
          expect(rendered_xml).to include("Elements: 1")
          expect(rendered_xml).to include("Types: 2")
        end
      end

      context "with a Liquid syntax error" do
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,#{schema_path},schema]
            ----
            {% for element in schema.elements_sorted_by_name %
            {{ element.name }}
            {% endfor %}
            ----
          TEXT
        end

        it "raises a parsing error" do
          expect { rendered_xml }.to raise_error(StandardError)
        end
      end

      context "with an empty Liquid template" do
        let(:input) do
          <<~TEXT
            = Document title

            [lutaml_xsd,#{schema_path},schema]
            ----

            ----
          TEXT
        end

        it "renders without error" do
          expect { rendered_xml }.not_to raise_error
        end
      end

      def expected_fragments
        File.readlines(
          fixtures_path("expected/xsd_person_fragments.xml"),
          chomp: true,
        ).reject(&:empty?)
      end
    end

    context "with UnitsML schema elements and complex types" do
      let(:unitsml_path) { fixtures_path("xsd_schemas/unitsml-v1.0-csd04.xsd") }

      let(:input) do
        <<~TEXT
          = Document title

          = Elements
          [lutaml_xsd,#{unitsml_path},unitsml]
          ----
          {% for element in unitsml.element %}

          Name: *{{ element.name }}*

          Type: *{{ element.type }}*
          {% endfor %}
          ----

          = ComplexTypes
          [lutaml_xsd,#{unitsml_path},unitsml]
          ----
          {% for complex_type in unitsml.complex_type %}

          Name: *{{ complex_type.name }}*

          Description: {{ complex_type.annotation.documentation.first.content }}
          {% endfor %}
          ----
        TEXT
      end

      let(:expected_output) do
        File.read(fixtures_path("first-unitsml-expected-output-v1.0-csd04.xml"))
      end

      it "correctly renders input" do
        expect_equivalent_document(
          xml_string_content(metanorma_convert(input)),
          expected_output,
        )
      end
    end

    context "with OMML schema elements and complex types" do
      let(:omml_path) { fixtures_path("xsd_schemas/omml.xsd") }
      let(:omml_dir) { File.dirname(omml_path) }

      let(:input) do
        <<~TEXT
          = Document title

          = Elements
          [lutaml_xsd,#{omml_path},omml, location=#{omml_dir}]
          ----
          {% for element in omml.element %}

          Name: *{{ element.name }}*
          Type: *{{ element.type }}*
          {% endfor %}
          ----

          = ComplexTypes
          [lutaml_xsd,#{omml_path},omml]
          ----
          {% for complex_type in omml.complex_type %}

          Name: *{{ complex_type.name }}*
          Description: {{ complex_type.annotation.documentation.first.content }}
          {% endfor %}
          ----
        TEXT
      end

      let(:expected_output) do
        File.read(fixtures_path("minimal-unitsml-expected-output-v1.0-csd04.xml"))
      end

      it "correctly renders input" do
        expect_equivalent_document(
          xml_string_content(metanorma_convert(input)),
          expected_output,
        )
      end
    end

    context "with UnitsML schema documentation via block syntax" do
      let(:unitsml_path) { fixtures_path("xsd_schemas/unitsml-v1.0-csd04.xsd") }

      let(:input) do
        <<~TEXT
          = Document title

          [#top]
          = Units Markup language (UnitsML) Schema Documentation unitsml-v1.0

          = Elements
          [lutaml_xsd,#{unitsml_path},unitsml]
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

      let(:expected_output) do
        File.read(fixtures_path("unitsml-expected-output-v1.0-csd04.xml"))
      end

      it "correctly renders input" do
        expect_equivalent_document(
          xml_string_content(metanorma_convert(input)),
          expected_output,
        )
      end
    end

    context "with XSD direct block syntax (lutaml_xsd::)" do
      let(:unitsml_path) do
        fixtures_path("xsd_schemas/unitsml-v1.0-csd04.xsd")
      end
      let(:template_path) do
        fixtures_path("unitsml_liquid_templates/schema.adoc")
      end
      let(:include_path) do
        fixtures_path("unitsml_liquid_templates")
      end

      let(:input) do
        <<~TEXT
          = Document title

          [#top]
          = XSD Templates

          lutaml_xsd::#{unitsml_path}[schema, #{template_path}, include_path=#{include_path}]
        TEXT
      end

      let(:expected_output) do
        File.read(fixtures_path("unitsml_expected.xml"))
      end

      it "correctly renders input using external Liquid template" do
        expect_equivalent_document(
          xml_string_content(metanorma_convert(input)),
          expected_output,
        )
      end

      context "with a missing template file" do
        let(:input) do
          <<~TEXT
            = Document title

            lutaml_xsd::#{unitsml_path}[schema, nonexistent.adoc]
          TEXT
        end

        it "raises a file-not-found error" do
          expect { metanorma_convert(input) }.to raise_error(Errno::ENOENT)
        end
      end

      context "when a block header follows a direct block" do
        let(:input) do
          <<~TEXT
            = Document title

            lutaml_xsd::#{unitsml_path}[schema, #{template_path}, include_path=#{include_path}]

            [lutaml_xsd,#{fixtures_path('xsd_schemas/person.xsd')},person]
            ----
            Person element count: {{ person.element.size }}
            ----
          TEXT
        end

        it "renders both syntaxes in the same document" do
          rendered = xml_string_content(metanorma_convert(input))
          expect(rendered).to include("Element:")
          expect(rendered).to include("Person element count: 1")
        end
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
  end
end
