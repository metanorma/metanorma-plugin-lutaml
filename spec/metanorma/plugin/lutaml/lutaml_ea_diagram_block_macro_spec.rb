require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEaDiagramBlockMacro do
  describe "#process" do
    context "when package referenced" do
      let(:example_file) do
        # fixtures_path("plateau_uml_20240708_all_packages_export.xmi")
        fixtures_path("test.xmi")
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_uml_datamodel_description,#{example_file}]
          --
          --

          lutaml_ea_diagram::[name="Fig B1 Full model",base_path="./xmi-images",format="png"]
        TEXT
      end
      let(:output) do
        [
          "<name>Fig B1 Full model</name>",
          "<image src=\"_\" mimetype=\"image/png\" " \
          "id=\"_4c0bc330-4360-7c06-2130-27690748fb69\" " \
          "height=\"auto\" width=\"auto\"/>",
        ]
      end

      it "correctly renders input" do
        expect(strip_src(metanorma_process(input)))
          .to(include(output.join("\n")))
      end
    end
  end
end
