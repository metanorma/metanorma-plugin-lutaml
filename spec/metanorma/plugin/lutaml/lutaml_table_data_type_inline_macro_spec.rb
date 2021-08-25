require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlTableDataTypeInlineMacro do
  describe "#process" do
    let(:example_file) { fixtures_path("test.xmi") }
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        --

        This is lutaml_table_data_type::[package="ISO 19135 Procedures for item registration XML", name="RE_Register_data_type"] data type
      TEXT
    end
    let(:output) do
      '<xref target="section-ABCD_82206E96_8D23_48dd_AC2F_31939C484AF2">'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_conent(metanorma_process(input))))
        .to(include(output))
    end
  end
end
