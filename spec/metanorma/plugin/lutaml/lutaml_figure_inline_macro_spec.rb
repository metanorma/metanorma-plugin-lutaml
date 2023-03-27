require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlFigureInlineMacro do
  describe "#process" do
    let(:example_file) { fixtures_path("test.xmi") }
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

        This is lutaml_figure::[package="Wrapper root package", name="Fig B1 Full model"] figure
      TEXT
    end
    let(:output) do
      '<xref target="figure-EAID_0E029ABF_C35A_49e3_9EEA_FFD4F32780A8"/>'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_content(metanorma_process(input))))
        .to(include(output))
    end
  end
end
