require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEaDiagramBlockMacro do
  describe "#process" do
    context "when package referenced" do
      let(:example_file) { fixtures_path("test.xmi") }

      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_ea_xmi,#{example_file}]
          --
          --

          lutaml_ea_diagram::[name="Fig B1 Full model",base_path="./xmi-images",format="png"]
        TEXT
      end
      let(:output) do
        [
          "<name>Fig B1 Full model</name>",
          "<image src=\"_\" mimetype=\"image/png\" " \
          "id=\"_\" " \
          "height=\"auto\" width=\"auto\"/>",
        ]
      end

      it "correctly renders input" do
        expect(strip_guid(strip_src(metanorma_process(input))))
          .to(include(output.join("\n")))
      end
    end

    context "when using with lutaml-xmi-index" do
      let(:example_file_1) { fixtures_path("test.xmi") }
      let(:example_file_2) { fixtures_path("large_test.xmi") }

      context "with lutaml_ea_diagram and without index option" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets
            :lutaml-xmi-index:first-xmi-index;#{example_file_1}
            :lutaml-xmi-index:second-xmi-index;#{example_file_2}

            [lutaml_ea_xmi,index=first-xmi-index]
            --
            --

            lutaml_ea_diagram::[name="Fig B1 Full model",base_path="./xmi-images",format="png"]
          TEXT
        end
        let(:output) do
          [
            "<name>Fig B1 Full model</name>",
            "<image src=\"_\" mimetype=\"image/png\" " \
            "id=\"_\" " \
            "height=\"auto\" width=\"auto\"/>",
          ]
        end

        it "correctly renders input" do
          expect(strip_guid(strip_src(metanorma_process(input))))
            .to(include(output.join("\n")))
        end
      end

      context "with lutaml_ea_diagram and index option" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets
            :lutaml-xmi-index:first-xmi-index;#{example_file_1}
            :lutaml-xmi-index:second-xmi-index;#{example_file_2}

            [lutaml_ea_xmi,index=first-xmi-index]
            --
            --

            lutaml_ea_diagram::[name="CityGML Package Diagram",base_path="./xmi-images",format="png",index="second-xmi-index"]
          TEXT
        end
        let(:output) do
          [
            "<name>CityGML Package Diagram</name>",
            "<image src=\"_\" mimetype=\"image/png\" " \
            "id=\"_\" " \
            "height=\"auto\" width=\"auto\"/>",
          ]
        end

        it "correctly renders input" do
          expect(strip_guid(strip_src(metanorma_process(input))))
            .to(include(output.join("\n")))
        end
      end

      context "with lutaml_ea_diagram, index and package option" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets
            :lutaml-xmi-index:first-xmi-index;#{example_file_1}
            :lutaml-xmi-index:second-xmi-index;#{example_file_2}

            [lutaml_ea_xmi,index=first-xmi-index]
            --
            --

            lutaml_ea_diagram::[package="CityGML",name="CityGML Package Diagram",base_path="./xmi-images",index="second-xmi-index"]
          TEXT
        end
        let(:output) do
          [
            "<name>CityGML Package Diagram</name>",
            "<image src=\"_\" mimetype=\"image/png\" " \
            "id=\"_\" " \
            "height=\"auto\" width=\"auto\"/>",
          ]
        end

        it "correctly renders input" do
          expect(strip_guid(strip_src(metanorma_process(input))))
            .to(include(output.join("\n")))
        end
      end
    end
  end
end
