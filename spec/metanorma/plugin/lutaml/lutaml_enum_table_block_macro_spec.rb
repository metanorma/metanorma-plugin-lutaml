require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEnumTableBlockMacro do
  describe "#process" do
    subject(:output) { metanorma_convert(input) }

    context "specify xmi file by path" do
      let(:example_file) { fixtures_path("minimal_test.xmi") }

      context "with built-in templates" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            ObligationType

            lutaml_enum_table::#{example_file}[name="ObligationType"]
          TEXT
        end

        it "renders table" do
          expect(output).to have_tag("table") do
            with_tag "th", text: "Enumeration: ObligationType"
            with_tag "td", text: "Stereotypes: «enumeration»"
            with_tag "td", text: "requirement"
            with_tag "td", text: "recommendation"
            with_tag "td", text: "premission"
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

            ObligationType

            lutaml_enum_table::#{example_file}[name="ObligationType",template="spec/fixtures/lutaml/liquid_templates/_enum_table.liquid"]
          TEXT
        end

        it "renders table" do
          expect(output).to have_tag("table") do
            with_tag "th", text: "NewClass: ObligationType"
            with_tag "td", text: /Package:/
            with_tag "td", text: "Stereotypes: «enumeration»"
            with_tag "td", text: "requirement"
            with_tag "td", text: "recommendation"
            with_tag "td", text: "premission"
          end
        end
      end

      context "with user-specific template and external_data" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            ObligationType

            lutaml_enum_table::#{example_file}[name="ObligationType",template="spec/fixtures/lutaml/liquid_templates_external_data/_enum_table.liquid",external_data="my_data:spec/fixtures/lutaml/external_data/my_data.yaml;second_data:spec/fixtures/lutaml/external_data/my_second_data.yaml"]
          TEXT
        end

        it "renders table" do
          expect(output).to have_tag("table") do
            with_tag "th", text: "NewClass: ObligationType"
            with_tag "td", text: /Package:/
            with_tag "td", text: "Stereotypes: «enumeration»"
            with_tag "td", text: "requirement"
            with_tag "td", text: "recommendation"
            with_tag "td", text: "premission"
          end

          expect(output).to have_tag("tr") do
            with_tag "td", text: /External Data:\sAdministration-test/
          end
        end
      end
    end
  end
end
