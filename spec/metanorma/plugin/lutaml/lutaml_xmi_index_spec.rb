require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEaXmiPreprocessor do
  describe "#process" do
    let(:example_file_1) { fixtures_path("large_test.xmi") }
    let(:example_file_2) { fixtures_path("test.xmi") }
    let(:config_file) { fixtures_path("lutaml_xmi_index_config.yml") }

    context "when using lutaml-xmi-index" do
      context "with lutaml_ea_xmi" do
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            :lutaml-xmi-index:first-xmi-index;#{example_file_1}
            :lutaml-xmi-index:second-xmi-index;#{example_file_2};config=#{config_file}

            [lutaml_ea_xmi,index=first-xmi-index]
            --
            [.diagram_include_block, base_path="requirements/"]
            ...
            Diagram text
            ...

            [.include_block, package="Another", base_path="spec/fixtures/lutaml/"]
            ...
            my text
            ...

            [.include_block, base_path="spec/fixtures/lutaml/"]
            ...
            my text
            ...

            [.before]
            ...
            mine text
            ...

            [.before, package="Another"]
            ...
            text before Another package
            ...

            [.after, package="Another"]
            ...
            text after Another package
            ...

            [.after, package="CityGML"]
            ...
            text after CityGML package
            ...

            [.after]
            ...
            footer text
            ...

            [.package_text, position="after"]
            ....
            [lutaml_ea_xmi,index=second-xmi-index]
            ---
            [.before]
            ......
            Nested datamodel mine text
            ......
            ---
            ....
            --
          TEXT
        end
        subject(:output) { metanorma_convert(input) }

        context "correctly renders" do
          context "data in first-xmi-index" do
            include_examples "should contain sections"
            include_examples "should contain text", "my text"
            include_examples "should contain text", "mine text"
            include_examples "should contain package content", "Another"
            include_examples "should contain table title"
            include_examples "should contain table headers"
            include_examples "should contain package content", "CityGML"
            include_examples "should contain text after package",
                             "Additional information",
                             "text after Another package"
            include_examples "should contain text after package",
                             "Additional information",
                             "text after CityGML package"
            include_examples "should contain footer text"

            table = [
              {
                id: "EAID_3BCEAE64_F977_46b5_A08C_A29D52216B04",
                name: "Elements of(.*)Another::AbstractAtomicTimeseries",
              },
              {
                id: "EAID_C92B844A_C582_4644_8991_61AB0610C8E3",
                name: "Elements of(.*)Another::AbstractTimeseries",
              },
              {
                id: "EAID_29876515_22A7_4b7f_8F83_4F16D87F3025",
                name: "Elements of(.*)Another::AuthenticationTypeValue",
              },
              {
                id: "EAID_DE7B3315_7E78_4d50_A7A5_80F520716EDC",
                name: "Elements of(.*)Another::CompositeTimeseries",
              },
              {
                id: "EAID_BD4BEEEE_BBD5_4b33_9CF9_4A2ABA430756",
                name: "Elements of(.*)Another::Dynamizer",
              },
              {
                id: "EAID_CDE3D132_C627_4fdd_A6BD_6B6C1555E878",
                name: "Elements of(.*)Another::GenericTimeseries",
              },
              {
                id: "EAID_8C1FCCE9_A408_4b86_A5D7_532F28277ACE",
                name: "Elements of(.*)Another::SensorConnectionTypeValue",
              },
              {
                id: "EAID_FDF538F9_ECA6_43b2_9EFA_8AFAAA95AB62",
                name: "Elements of(.*)Another::StandardFileTimeseries",
              },
              {
                id: "EAID_BE99CC5F_DEFB_459f_BE53_B8F12C8B8149",
                name: "Elements of(.*)Another::StandardFileTypeValue",
              },
              {
                id: "EAID_1AA08CC8_682B_4697_830B_C3E10EC012D9",
                name: "Elements of(.*)Another::TabulatedFileTimeseries",
              },
              {
                id: "EAID_18357CC9_C00A_410a_9043_E05BEA22B6A7",
                name: "Elements of(.*)Another::TabulatedFileTypeValue",
              },
              {
                id: "EAID_20B7542F_5EE7_44c6_8AC5_055508241A3B",
                name: "Definition table of(.*)Another::TimeseriesTypeValue",
              },
              {
                id: "EAID_1D8715F2_4E4A_4f36_A414_1326B6DC1EDD",
                name: "Definition table of(.*)" \
                      "Another::ADEOfAbstractAtomicTimeseries",
              },
              {
                id: "EAID_1F4FA76D_0945_46f0_B222_3C4E92196351",
                name: "Definition table of(.*)Another::ADEOfAbstractTimeseries",
              },
              {
                id: "EAID_0DBF7AD4_080D_4238_9949_1CDB34142A59",
                name: "Definition table of(.*)ADEOfCompositeTimeseries",
              },
              {
                id: "EAID_6AE198DA_9848_4e6c_B17E_C1004F90782A",
                name: "Definition table of(.*)ADEOfDynamizer",
              },
              {
                id: "EAID_561520A7_886A_4f79_852A_FC1DFD122B66",
                name: "Definition table of(.*)Another::ADEOfGenericTimeseries",
              },
              {
                id: "EAID_021B99FF_A404_4c54_B785_600CA37348C1",
                name: "Definition table of(.*)Another::ADEOfStandardFileTimeseries",
              },
              {
                id: "EAID_A197050C_E2CB_4d86_B69E_5B5E96E37FDE",
                name: "Definition table of(.*)" \
                "Another::ADEOfTabulatedFileTimeseries",
              },
              {
                id: "EAID_084E218B_32C6_41f2_A710_ADA8A5A8462C",
                name: "Definition table of(.*)Another::SensorConnection",
              },
              {
                id: "EAID_8E506B76_0A77_4672_A50B_B82A9AF2A416",
                name: "Definition table of(.*)Another::TimeseriesComponent",
              },
              {
                id: "EAID_2ECE65B5_3620_4c27_B3A9_2D705C545692",
                name: "Definition table of(.*)Another::TimeValuePair",
              },
            ]
            include_examples "should contain table", table

            figure = [
              {
                id: "EAID_74DB2087_E1FC_42a7_A349_2D89BED649A5",
                name: "Dynamizer",
                src: "spec/assets/requirements//" \
                     "EAID_74DB2087_E1FC_42a7_A349_2D89BED649A5.png",
              },
              {
                id: "EAID_BE0D44C2_C28B_4b5e_B937_1CA5152CAA6D",
                name: "Dynamizer - Code lists",
                src: "spec/assets/requirements//" \
                     "EAID_BE0D44C2_C28B_4b5e_B937_1CA5152CAA6D.png",
              },
              {
                id: "EAID_904A37DC_3079_4ef4_9DB0_3DC2C3784549",
                name: "Dynamizer - ADE Data types",
                src: "spec/assets/requirements//" \
                     "EAID_904A37DC_3079_4ef4_9DB0_3DC2C3784549.png",
              },
              {
                id: "EAID_ACBB5EE3_3428_40f5_9C7C_E41923419F29",
                name: "CityGML Package Diagram",
                src: "spec/assets/requirements//" \
                     "EAID_ACBB5EE3_3428_40f5_9C7C_E41923419F29.png",
              },
              {
                id: "EAID_938AE961_1C57_4052_B964_997D1894A58D",
                name: "Use of ISO and OASIS standards in CityGML",
                src: "spec/assets/requirements//" \
                     "EAID_938AE961_1C57_4052_B964_997D1894A58D.png",
              },
            ]
            include_examples "should contain figure", figure
          end

          context "data in second-xmi-index" do
            table = [
              name: "Metadata of Wrapper nested package",
            ]
            include_examples "should contain table", table

            it "should contain data in table" do
              expect(subject).to have_tag("th", text: /Parent package/)
              expect(subject).to have_tag("td", text: /Wrapper root package/)
            end
          end
        end
      end
    end
  end
end
