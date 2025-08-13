require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEnumTableBlockMacro do
  describe "#process" do
    subject(:output) { metanorma_convert(input) }

    context "specify xmi file by path" do
      let(:example_file) do
        fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
      end

      context "with built-in templates" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            TextureTypeType

            lutaml_enum_table::#{example_file}[name="TextureTypeType"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "th", text: "Enumeration: TextureTypeType"
            with_tag "td", text: "Subtype of: app"
            with_tag "td", text: "Stereotypes: «Enumeration»"
            with_tag "td", text: "specific"
            with_tag "td", text: "typical"
            with_tag "td", text: "unknown"
          end
        end
      end

      context "with user-specific template" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            TextureTypeType

            lutaml_enum_table::#{example_file}[name="TextureTypeType",template="spec/fixtures/lutaml/liquid_templates/_enum_table.liquid"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "th", text: "NewClass: TextureTypeType"
            with_tag "td", text: "Subtype of: app"
            with_tag "td", text: "Stereotypes: «Enumeration»"
            with_tag "td", text: "specific"
            with_tag "td", text: "typical"
            with_tag "td", text: "unknown"
          end
        end
      end
    end
  end
end
