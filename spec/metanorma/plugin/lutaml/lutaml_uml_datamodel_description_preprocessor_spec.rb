require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("large_test.xmi") }
    let(:config_file) do
      fixtures_path("lutaml_uml_datamodel_description_config.yml")
    end

    context "when there is an options file" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
          --
          [.diagram_include_block, base_path="requirements/"]
          ...
          Diagram text
          ...

          [.include_block, package="Another", base_path="spec/fixtures/"]
          ...
          my text
          ...

          [.include_block, base_path="spec/fixtures/"]
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
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          #{File.read(fixtures_path('datamodel_description_sections.xml'))}
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end

      context "when there is an section_depth option supplied" do
        let(:config_file) do
          fixtures_path(
            "lutaml_uml_datamodel_description_config_section_depth.yml")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :docfile: test.adoc
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
            --
            [.diagram_include_block, base_path="requirements/"]
            ...
            Diagram text
            ...

            [.include_block, package="Another", base_path="spec/fixtures/"]
            ...
            my text
            ...

            [.include_block, base_path="spec/fixtures/"]
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
        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
            #{File.read(fixtures_path('datamodel_description_sections_section_depth.xml'))}
            </standard-document>
            </body></html>
          TEXT
        end

        it "correctly renders input" do
          expect(xml_string_conent(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "when there is an render_style option supplied" do
        %w[random entity_list data_dictionary].each do |style|
          context "when #{style}" do
            let(:config_file) do
              fixtures_path('temporary_datamodel_description_config.yml')
            end
            let(:input) do
              <<~TEXT
                = Document title
                Author
                :docfile: test.adoc
                :nodoc:
                :novalid:
                :no-isobib:
                :imagesdir: spec/assets

                [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
                --
                --
              TEXT
            end
            let(:output) do
              <<~TEXT
                #{BLANK_HDR}
                #{File.read(fixtures_path("datamodel_description_sections_render_style_#{style}.xml"))}
                </standard-document>
                </body></html>
              TEXT
            end

            context 'when render_style' do
              around do |example|
                File.open(config_file, 'w') { |file| file.puts({ 'render_style' => style }.to_yaml) }
                example.run
                FileUtils.rm_f(config_file)
              end

              it "correctly renders input" do
                expect(xml_string_conent(metanorma_process(input)))
                  .to(be_equivalent_to(output))
              end
            end
          end
        end
      end

      context "when there is an `external_classes` option supplied" do
        let(:example_file) { fixtures_path("test.xmi") }
        let(:config_file) do
          fixtures_path('temporary_datamodel_description_config.yml')
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :docfile: test.adoc
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
            --
            --
          TEXT
        end

        around do |example|
          File.open(config_file, 'w') do |file|
            file.puts({ 'render_style' => render_style, 'external_classes' => external_classes }.to_yaml)
          end
          example.run
          FileUtils.rm_f(config_file)
        end

        context "when render_style equal `data_dictionary`" do
          subject(:xml_convert) { xml_string_conent(metanorma_process(input)) }

          let(:render_style) { "data_dictionary" }
          let(:example_file) { fixtures_path("test.xmi") }
          let(:config_file) do
            fixtures_path('temporary_datamodel_description_config.yml')
          end
          let(:input) do
            <<~TEXT
              = Document title
              Author
              :docfile: test.adoc
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
              --
              --
            TEXT
          end
          let(:external_classes) do
            {
              "Register" => "My-custom-Register-section",
              "RE_ReferenceSource" => "custom-RE_ReferenceSource"
            }
          end

          it "correctly maps external and internal refs" do
            expect(xml_convert).to(include('<xref target="My-custom-Register-section">Register</xref>'))
            expect(xml_convert).to_not(include('<xref target="Register-section">Register</xref>'))

            expect(xml_convert).to_not(include('<xref target="RE_ReferenceSource-section">RE_ReferenceSource</xref>'))
            expect(xml_convert).to(include('<xref target="custom-RE_ReferenceSource">RE_ReferenceSource</xref>'))
          end
        end

        context "when render_style equal `entity_list`" do
          subject(:xml_convert) { xml_string_conent(metanorma_process(input)) }

          let(:render_style) { "entity_list" }
          let(:external_classes) do
            {
              "RE_Register" => "My-custom-RE_Register-section"
            }
          end

          it "correctly maps external and internal refs" do
            expect(xml_convert).to(include('<xref target="My-custom-RE_Register-section">RE_Register</xref>'))
            expect(xml_convert).to_not(include('<xref target="RE_Register-section">RE_Register</xref>'))
          end
        end
      end
    end

    context "when there is no options file" do
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
          [.diagram_include_block, base_path="requirements/"]
          ...
          Diagram text
          ...

          [.include_block, package="Another", base_path="spec/fixtures/"]
          ...
          my text
          ...

          [.include_block, base_path="spec/fixtures/"]
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
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          #{File.read(fixtures_path('datamodel_description_sections_tree.xml'))}
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when there nested tags" do
      let(:example_file) { fixtures_path("test.xmi") }
      let(:nested_config_file) do
        fixtures_path('temporary_datamodel_description_config.yml')
      end
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
          [.include_block, package="Wrapper nested package", base_path="spec/fixtures/"]
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
          [lutaml_uml_datamodel_description,#{example_file},#{nested_config_file}]
          ---
          [.before]
          ....
          Nested datamodel mine text
          ....
          ---
          ....
          --
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          #{File.read(fixtures_path("datamodel_description_sections_nested_macroses.xml"))}
          </standard-document>
          </body></html>
        TEXT
      end

      around do |example|
        File.open(nested_config_file, 'w') { |file| file.puts({ 'render_style' => 'entity_list' }.to_yaml) }
        example.run
        FileUtils.rm_f(nested_config_file)
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when `render_entities` option supplied" do
      let(:example_file) { fixtures_path("test_2.xmi") }
      let(:config_file) do
        fixtures_path('lutaml_uml_datamodel_description_config_package_entities.yml')
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          .Classes in test2
          [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
          ---
          ---
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          #{File.read(fixtures_path("datamodel_description_sections_package_entities.xml"))}
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when `skip_tables` option supplied" do
      let(:example_file) { fixtures_path("test_2.xmi") }
      let(:config_file) do
        fixtures_path('lutaml_uml_datamodel_description_config_render_tables.yml')
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          .Classes in test2
          [lutaml_uml_datamodel_description,#{example_file},#{config_file}]
          ---
          ---
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          #{File.read(fixtures_path("datamodel_description_sections_skip_tables.xml"))}
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end
  end
end
