require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlTableInlineMacro do
  describe "#process" do
    context 'when package referenced' do
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

          This is lutaml_table::[package="Wrapper nested package"] package
        TEXT
      end
      let(:output) do
        '<xref target="section-EAPK_9C96A88B_E98B_490b_8A9C_24AEDAC64293"/>'
      end

      it "correctly renders input" do
        expect(strip_src(xml_string_content(metanorma_process(input))))
          .to(include(output))
      end
    end
  end

  context 'when class referenced' do
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

        This is lutaml_table::[package="ISO 19135 Procedures for item registration XML", class="RE_Register"] class
      TEXT
    end
    let(:output) do
      '<xref target="section-EAID_82206E96_8D23_48dd_AC2F_31939C484AF2"/>'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_content(metanorma_process(input))))
        .to(include(output))
    end
  end

  context 'when enum referenced' do
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

        This is lutaml_table::[package="ISO 19135 Procedures for item registration XML", enum="RE_Register_enum"] enum
      TEXT
    end
    let(:output) do
      '<xref target="section-EAID_82206E96_8D23_48dd_AC2F_92839C484AF2"/>'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_content(metanorma_process(input))))
        .to(include(output))
    end
  end

  context 'when data_type referenced' do
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

        This is lutaml_table::[package="ISO 19135 Procedures for item registration XML", data_type="RE_Register_data_type"] data type
      TEXT
    end
    let(:output) do
      '<xref target="section-ABCD_82206E96_8D23_48dd_AC2F_31939C484AF2"/>'
    end

    it "correctly renders input" do
      expect(strip_src(xml_string_content(metanorma_process(input))))
        .to(include(output))
    end
  end
end
