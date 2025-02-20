require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEaXmiPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("large_test.xmi") }
    let(:config_file) do
      fixtures_path("lutaml_uml_datamodel_description_config.yml")
    end

    context "when there is an options file" do
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_ea_xmi,#{example_file},#{config_file}]
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
          --
        TEXT
      end

      subject (:output) { metanorma_process(input) }

      context "correctly renders input" do
        include_examples "should contain preface"
        include_examples "should contain sections"
        include_examples "should contain text", "Diagram text"
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

      context "when there is an section_depth option supplied" do
        let(:config_file) do
          fixtures_path(
            "lutaml_uml_datamodel_description_config_section_depth.yml",
          )
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_ea_xmi,#{example_file},#{config_file}]
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
            --
          TEXT
        end
        subject (:output) { metanorma_process(input) }

        # @note datamodel_description_sections_section_depth.xml
        context "correctly renders input" do
          include_examples "should contain preface"
          include_examples "should contain sections"
          include_examples "should contain text", "Diagram text"
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

          include_examples "should contain package content",
                           "Wrapper nested package"

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
              id: "EAID_6687F0F3_483C_4d13_B082_DF4736E1421F",
              name: "Elements of(.*)CityTML::AbstractFillingSurface",
            },
            {
              id: "EAID_1AA08CC8_682B_4697_830B_C3E10EC012D9",
              name: "Elements of(.*)Dynamizer::TabulatedFileTimeseries",
            },
            {
              id: "EAID_B2C49F64_6095_4f8c_8FA3_492EA57A263F",
              name: "Definition table of(.*)" \
                    "CityTML::ConditionOfConstructionValue",
            },
            {
              id: "EAID_81A5B9B1_B8C6_47b1_A58E_94EBD9C94867",
              name: "Definition table of(.*)CityTML::HeightStatusValue",
            },
            {
              id: "EAID_9255FD68_C2A9_4ef6_B532_7537C3BBE509",
              name: "Definition table of(.*)CityTML::RelationToConstruction",
            },
            {
              id: "EAID_1F4FA76D_0945_46f0_B222_3C4E92196351",
              name: "Definition table of(.*)Dynamizer::ADEOfAbstractTimeseries",
            },
            {
              id: "EAID_0DBF7AD4_080D_4238_9949_1CDB34142A59",
              name: "Definition table of(.*)" \
              "Dynamizer::ADEOfCompositeTimeseries",
            },
          ]
          include_examples "should contain table", table

          figure = [
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
              id: "EAID_05A815AC_1EAE_4c98_A8F7_C178E3C1DF9C",
              name: "Construction - Code lists",
              src: "spec/assets/requirements//" \
              "EAID_05A815AC_1EAE_4c98_A8F7_C178E3C1DF9C.png",
            },
          ]
          include_examples "should contain figure", figure
        end
      end

      context "when there is an render_style option supplied" do
        %w[random entity_list data_dictionary].each do |style|
          context "when #{style}" do
            let(:config_file) do
              fixtures_path("temporary_datamodel_description_config.yml")
            end
            let(:input) do
              <<~TEXT
                = Document title
                Author
                :nodoc:
                :novalid:
                :no-isobib:
                :imagesdir: spec/assets

                [lutaml_ea_xmi,#{example_file},#{config_file}]
                --
                --
              TEXT
            end
            subject(:output) { metanorma_process(input) }

            context "when render_style" do
              around do |example|
                File.open(config_file, "w") do |file|
                  file.puts({ "render_style" => style }.to_yaml)
                end
                example.run
                FileUtils.rm_f(config_file)
              end

              # @note datamodel_description_sections_render_style_#{style}.xml
              context "correctly renders input (render_style: #{style})" do
                include_examples "should contain sections"
                case style
                when "random"
                  include_examples "should contain table title"
                  include_examples "should contain table headers"
                  include_examples "should contain package content", "CityGML"
                  include_examples "should contain package content", "Another"
                  include_examples "should contain package content",
                                   "Wrapper nested package"

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
                      name: "Definition table of(.*)" \
                            "Another::TimeseriesTypeValue",
                    },
                    {
                      id: "EAID_1D8715F2_4E4A_4f36_A414_1326B6DC1EDD",
                      name: "Definition table of(.*)" \
                            "Another::ADEOfAbstractAtomicTimeseries",
                    },
                    {
                      id: "EAID_1F4FA76D_0945_46f0_B222_3C4E92196351",
                      name: "Definition table of(.*)" \
                            "Another::ADEOfAbstractTimeseries",
                    },
                    {
                      id: "EAID_0DBF7AD4_080D_4238_9949_1CDB34142A59",
                      name: "Definition table of(.*)" \
                            "ADEOfCompositeTimeseries",
                    },
                    {
                      id: "EAID_6AE198DA_9848_4e6c_B17E_C1004F90782A",
                      name: "Definition table of(.*)" \
                            "ADEOfDynamizer",
                    },
                    {
                      id: "EAID_561520A7_886A_4f79_852A_FC1DFD122B66",
                      name: "Definition table of(.*)" \
                            "Another::ADEOfGenericTimeseries",
                    },
                    {
                      id: "EAID_021B99FF_A404_4c54_B785_600CA37348C1",
                      name: "Definition table of(.*)" \
                            "Another::ADEOfStandardFileTimeseries",
                    },
                    {
                      id: "EAID_A197050C_E2CB_4d86_B69E_5B5E96E37FDE",
                      name: "Definition table of(.*)" \
                            "Another::ADEOfTabulatedFileTimeseries",
                    },
                    {
                      id: "EAID_084E218B_32C6_41f2_A710_ADA8A5A8462C",
                      name: "Definition table of(.*)" \
                            "Another::SensorConnection",
                    },
                    {
                      id: "EAID_8E506B76_0A77_4672_A50B_B82A9AF2A416",
                      name: "Definition table of(.*)" \
                            "Another::TimeseriesComponent",
                    },
                    {
                      id: "EAID_2ECE65B5_3620_4c27_B3A9_2D705C545692",
                      name: "Definition table of(.*)Another::TimeValuePair",
                    },
                  ]
                  include_examples "should contain table", table

                when "entity_list"
                  clause_title = [
                    {
                      clause_id: "section-" \
                      "EAPK_9C96A88B_E98B_490b_8A9C_24AEDAC64293",
                      title: "Wrapper nested package",
                    },
                    {
                      clause_id: "section-" \
                      "EAPK_369E0123_00FC_4098_BEF2_3BB506B2012A",
                      title: "CityGML",
                    },
                    {
                      clause_id: "section-" \
                      "EAPK_15C00628_ED51_4a92_8216_10ADF1613D98",
                      title: "Another",
                    },
                  ]
                  include_examples "should contain clause title", clause_title

                  xref = [
                    {
                      id: "EAID_3BCEAE64_F977_46b5_A08C_A29D52216B04",
                      name: "AbstractAtomicTimeseries",
                    },
                    {
                      id: "EAID_C92B844A_C582_4644_8991_61AB0610C8E3",
                      name: "AbstractTimeseries",
                    },
                    {
                      id: "EAID_29876515_22A7_4b7f_8F83_4F16D87F3025",
                      name: "AuthenticationTypeValue",
                    },
                    {
                      id: "EAID_DE7B3315_7E78_4d50_A7A5_80F520716EDC",
                      name: "CompositeTimeseries",
                    },
                    {
                      id: "EAID_D8E4EAFC_9DAF_4cba_9169_984738657435",
                      name: "AbstractConstruction",
                    },
                  ]
                  include_examples "should contain xref objects", xref

                when "data_dictionary"
                  it "should contain table headers" do
                    [
                      "Description",
                      "Parent package",
                      "Stereotype",
                      "Subclass of",
                    ].each do |th|
                      expect(subject).to have_tag("th"), text: /#{th}:/
                    end
                  end

                  it "should contain name - Metadata" do
                    expect(subject).to have_tag("table") do
                      with_tag "name", text:
                        /Metadata\ of\ Wrapper\ nested\ package/
                    end
                  end

                  it "should contain notes" do
                    expect(subject).to have_tag("note")
                  end

                  xref = [
                    {
                      id: "EAID_1D8715F2_4E4A_4f36_A414_1326B6DC1EDD",
                      name: "ADEOfAbstractAtomicTimeseries",
                    },
                    {
                      id: "EAID_0A614EA9_13B7_4ebe_85ED_AA187D27CBD1",
                      name: "CharacterString",
                    },
                    {
                      id: "EAID_1F4FA76D_0945_46f0_B222_3C4E92196351",
                      name: "ADEOfAbstractTimeseries",
                    },
                    {
                      id: "EAID_2D0C03FB_FF62_4979_A2EB_A40C043B097E",
                      name: "TM_Position",
                    },
                    {
                      id: "EAID_0DBF7AD4_080D_4238_9949_1CDB34142A59",
                      name: "ADEOfCompositeTimeseries",
                    },
                  ]
                  include_examples "should contain xref objects", xref
                end
              end
            end
          end
        end
      end

      context "when there is an `external_classes` option supplied" do
        let(:example_file) { fixtures_path("test.xmi") }
        let(:config_file) do
          fixtures_path("temporary_datamodel_description_config.yml")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_ea_xmi,#{example_file},#{config_file}]
            --
            --
          TEXT
        end

        around do |example|
          File.open(config_file, "w") do |file|
            file.puts({ "render_style" => render_style,
                        "external_classes" => external_classes }.to_yaml)
          end
          example.run
          FileUtils.rm_f(config_file)
        end

        context "when render_style equal `data_dictionary`" do
          subject(:xml_convert) { xml_string_content(metanorma_process(input)) }

          let(:render_style) { "data_dictionary" }
          let(:example_file) { fixtures_path("test.xmi") }
          let(:config_file) do
            fixtures_path("temporary_datamodel_description_config.yml")
          end
          let(:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_xmi,#{example_file},#{config_file}]
              --
              --
            TEXT
          end
          let(:external_classes) do
            {
              "Register" => "My-custom-Register-section",
              "RE_ReferenceSource" => "custom-RE_ReferenceSource",
            }
          end

          it "correctly maps external and internal refs" do
           xml_output = remove_xml_whitespaces(xml_convert)

            expect(xml_output)
              .to_not(include('<xref target="My-custom-Register-section" style="short"><display-text>Register</display-text></xref>'))
            expect(xml_output)
              .to_not(include('<xref target="Register-section" style="short"><display-text>Register</display-text></xref>'))
            expect(xml_output)
              .to_not(include('<xref target="RE_ReferenceSource-section" style="short"><display-text>RE_ReferenceSource</display-text></xref>'))
            expect(xml_output)
              .to(include('<xref target="custom-RE_ReferenceSource" style="short"><display-text>RE_ReferenceSource</display-text></xref>'))
          end
        end

        context "when render_style equal `entity_list`" do
          subject(:xml_convert) { xml_string_content(metanorma_process(input)) }

          let(:render_style) { "entity_list" }
          let(:external_classes) do
            {
              "RE_Register" => "My-custom-RE_Register-section",
            }
          end

          it "correctly maps external and internal refs" do
            xml_output = remove_xml_whitespaces(xml_convert)
            expect(xml_output)
              .to(include('<xref target="My-custom-RE_Register-section" style="short"><display-text>RE_Register</display-text></xref>'))
            expect(xml_output)
              .to_not(include('<xref target="RE_Register-section" style="short"><display-text>RE_Register</display-text></xref>'))
          end
        end
      end
    end

    context "when there is no options file" do
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
          --
        TEXT
      end
      subject(:output) { metanorma_process(input) }

      # @note datamodel_description_sections_tree.xml
      context "correctly renders input" do
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
    end

    context "when there nested tags" do
      let(:example_file) { fixtures_path("test.xmi") }
      let(:nested_config_file) do
        fixtures_path("temporary_datamodel_description_config.yml")
      end
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
          [.include_block, package="Wrapper nested package", base_path="spec/fixtures/lutaml/"]
          ...
          my text
          ...

          [.before]
          ...
          mine text
          ...

          [.before, package="Wrapper nested package"]
          ...
          text before Wrapper nested package package
          ...

          [.after]
          ...
          footer text
          ...

          [.package_text, position="after"]
          ....
          [lutaml_ea_xmi,#{example_file},#{nested_config_file}]
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
      subject(:output) { metanorma_process(input) }

      around do |example|
        File.open(nested_config_file, "w") do |file|
          file.puts({ "render_style" => "entity_list" }.to_yaml)
        end
        example.run
        FileUtils.rm_f(nested_config_file)
      end

      # @note datamodel_description_sections_nested_macroses.xml
      context "correctly renders input" do
        include_examples "should contain preface"
        clause_title = [
          {
            clause_id: "section-EAPK_9C96A88B_E98B_490b_8A9C_24AEDAC64293",
            title: "Wrapper nested package",
          },
          {
            clause_id: "section-EAPK_9C96A88B_E98B_490b_8A9C_24AEDAC64293",
            title: "ISO 19135 Procedures for item registration XML",
          },
        ]
        include_examples "should contain clause title", clause_title
        include_examples "should contain table headers"

        xref = [
          {
            id: "EAID_82206E96_8D23_48dd_AC2F_31939C484AF2",
            name: "RE_Register",
          },
          {
            id: "EAID_82206E96_8D23_48dd_AC2F_92839C484AF2",
            name: "RE_Register_enum",
          },
        ]
        include_examples "should contain xref objects", xref

        table = [
          {
            id: "EAID_82206E96_8D23_48dd_AC2F_31939C484AF2",
            name: "Elements of(.*)ISO 19135 Procedures for item " \
                  "registration XML::RE_Register",
          },
          {
            id: "EAID_82206E96_8D23_48dd_AC2F_92839C484AF2",
            name: "Definition table of(.*)ISO 19135 Procedures for item " \
                  "registration",
          },
        ]
        include_examples "should contain table", table
      end
    end

    context "when `render_entities` option supplied" do
      let(:example_file) { fixtures_path("test_2.xmi") }
      let(:config_file) do
        fixtures_path(
          "lutaml_uml_datamodel_description_config_package_entities.yml",
        )
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          .Classes in test2
          [lutaml_ea_xmi,#{example_file},#{config_file}]
          ---
          ---
        TEXT
      end
      subject(:output) { metanorma_process(input) }

      # @note datamodel_description_sections_package_entities.xml
      context "correctly renders input" do
        include_examples "should contain sections"
        it "should contain table name" do
          expect(subject).to have_tag("table") do
            with_tag "name", text: /Classes in test2/
          end
        end

        it "should contain table headers" do
          %w[Class Description].each do |th|
            expect(subject).to have_tag("th", text: th)
          end
        end
      end
    end

    context "when `skip_tables` option supplied" do
      let(:example_file) { fixtures_path("test_2.xmi") }
      let(:config_file) do
        fixtures_path(
          "lutaml_uml_datamodel_description_config_render_tables.yml",
        )
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          .Classes in test2
          [lutaml_ea_xmi,#{example_file},#{config_file}]
          ---
          ---
        TEXT
      end
      subject(:output) { metanorma_process(input) }

      # @note datamodel_description_sections_skip_tables.xml
      context "correctly renders input" do
        include_examples "should contain sections"

        it "should contain table name" do
          expect(subject).to have_tag("table") do
            with_tag "name", text:
              /Enumerated classes defined in Another Wrapper nested package/
          end
        end

        it "should contain table headers" do
          %w[Name Description].each do |th|
            expect(subject).to have_tag("th", text: th)
          end
        end

        xref = [
          {
            id: "EAID_82206E96_8D23_48dd_AC2F_92839C484AF2",
            name: "RE_Register_enum",
          },
        ]
        include_examples "should contain xref objects", xref
      end
    end

    context "when `template_path` option supplied" do
      let(:config_file) do
        fixtures_path(
          "lutaml_uml_datamodel_description_config_template_path.yml",
        )
      end
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_ea_xmi,#{example_file},#{config_file}]
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
          --
        TEXT
      end

      subject (:output) { metanorma_process(input) }

      context "correctly renders input" do
        include_examples "should contain preface"
        include_examples "should contain sections"
        include_examples "should contain text", "Diagram text"
        include_examples "should contain text", "my text"
        include_examples "should contain text", "mine text"
        include_examples "should contain package content", "Another"
        # include_examples "should contain table title"
        include_examples "should contain table headers"
        include_examples "should contain package content", "CityGML"
        include_examples "should contain text after package",
                         "Additional information",
                         "text after Another package"
        include_examples "should contain text after package",
                         "Additional information",
                         "text after CityGML package"
        include_examples "should contain footer text"

        it "should contain table headers defined in the templates" do
          [
            "New\ Name",
            "New\ Definition",
            "New\ Stereotype",
            "Abstract",
            "Associations",
            "Public\ attributes",
            "Constraints",
            "Values",
          ].each do |th|
            expect(subject).to have_tag("th", text: /#{th}/)
          end
        end

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
    end

    context "when `guidance` option supplied" do
      let(:example_file) { fixtures_path("plateau_all_packages_export.xmi") }
      let(:config_file) do
        fixtures_path(
          "lutaml_uml_datamodel_description_config_guidance.yml",
        )
      end
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_ea_xmi,#{example_file},#{config_file}]
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
          --
        TEXT
      end

      subject (:output) { metanorma_process(input) }

      context "correctly renders input" do
        include_examples "should contain text", "Diagram text"
        include_examples "should contain text", "my text"
        include_examples "should contain text", "mine text"
        include_examples "should contain footer text"

        table = [
          {
            name: "Elements of(.*)bldg::_AbstractBuilding",
          },
          {
            name: "Elements of(.*)bldg::Building",
          },
          {
            name: "Elements of(.*)bldg::BuildingPart",
          },
        ]
        include_examples "should contain table", table

        it "should contain Used and Guidance" do
          [
            {
              name: "gml:boundedBy",
              type: "gml::Envelope [0..1]",
              desc: "建築物の範囲及び適用される空間参照系。",
              used: "false",
              guidance: "この属性は使用されていません。",
            },
            {
              name: "gml:description",
              type: "gml::StringOrRefType [0..1]",
              desc: "土地利用の概要。",
              used: "true",
              guidance: "",
            },
          ].each do |i|
            expect(subject).to have_tag("tr") do
              with_tag "td", text: /#{i[:name]}/
              with_tag "td", text: i[:type]
              with_tag "td", text: i[:desc]
              with_tag "td", text: i[:used]
              with_tag "td", text: i[:guidance]
            end
          end
        end
      end
    end
  end
end
