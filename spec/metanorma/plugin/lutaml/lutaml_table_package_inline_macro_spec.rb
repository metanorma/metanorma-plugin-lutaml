require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlTablePackageInlineMacro do
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

        This is lutaml_table_package::[package="Wrapper nested package"] class
      TEXT
    end
    let(:output) do
      '<xref target="section-EAPK_9C96A88B_E98B_490b_8A9C_24AEDAC64293">'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_conent(metanorma_process(input))))
        .to(include(output))
    end
  end
end
