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

            around do |example|
              File.open(config_file, 'w') { |file| file.puts({ render_style: style }.to_yaml) }
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
  end
end
