require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("test_relative_includes_svgmap.exp") }

    context "Array of hashes" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:

          [lutaml_express,#{example_file},my_context]
          ----

          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for entity in schema.entities %}
          === {{entity.id}}
          supertypes -> {{entity.supertypes.id}}
          explicit -> {{entity.explicit.first.id}}

          {% endfor %}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_data_quality_criteria_representation</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_data_quality_criterion</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_data_quality_criterion_specific_applied_value</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_data_quality_target_accuracy_association</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_detailed_report_request</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
          <title>a3m_summary_report_request_with_representative_value</title>
          <p id="_">supertypes →
          explicit → </p>
          </clause></clause>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when additional options passed" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          [lutaml_express,#{example_file},my_context, leveloffset=+2]
          ----

          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}
          {% endfor %}

          ----


          [lutaml_express,#{example_file},my_context, leveloffset=-1]
          ----

          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}
          {% endfor %}
          ----
        TEXT
      end

      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
            <sections><clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
            <p id="_">Mine text</p>
            <svgmap><figure id="_">
            <image src="#{File.expand_path(fixtures_path("measure_schemaexpg5.svg"))}" id="_" mimetype="image/svg+xml" height="auto" width="auto"></image>
            </figure><target href="1"><eref bibitemid="express_measure_schema" citeas="">measure_schema</eref></target><target href="2"><eref bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref></target><target href="3"><eref bibitemid="express_measure_schema" citeas="">measure_schema</eref></target></svgmap></clause>
            <clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
            <p id="_">Mine text</p>
            <p id="_">===
            image::#{File.expand_path(fixtures_path("measure_schemaexpg5.svg"))}[]</p>
            <ul id="_">
            <li>
            <p id="_"><eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>; 1</p>
            </li>
            <li>
            <p id="_"><eref bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref>; 2</p>
            </li>
            <li>
            <p id="_"><eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>; 3
            ===</p>
            </li>
            </ul></clause></sections>
            <bibliography><references hidden="true" normative="false"><bibitem id="express_measure_schema" type="internal">
            <docidentifier type="repository">express/measure_schema</docidentifier>
            </bibitem>
            <bibitem id="express_measure_schemaexpg4" type="internal">
            <docidentifier type="repository">express/measure_schemaexpg4</docidentifier>
            </bibitem>
            </references></bibliography></standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when relative paths exists in doc" do
      let(:example_file) { fixtures_path("test_relative_includes.exp") }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:

          [lutaml_express,#{example_file},my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}
          {% endfor %}
          ----
        TEXT
      end
      let(:doc_path) { File.dirname(example_file) }
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
            <p id="_">Mine text</p>
            <p id="_">
            <link target="#{fixtures_path('/downloads/report.pdf')}">Get Report
            </p>
            <p id="_">
            <link target="http://test.com/include1.csv">
            </p>


            <p id="_">header1,header2,header3
            one,two,three</p>
            <p id="_">Unresolved directive in &lt;stdin&gt;&#8201;&#8212;&#8201;include::#{fixtures_path('test/include1.csv')}[]</p>
            <p id="_">
            <link target="http://test.com/include1.csv">
            </p></clause>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end

      context "when loaded from a cache file" do
        let(:cache_path) do
          fixtures_path('expressir_realtive_paths/test_relative_includes_cache.yaml')
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :docfile: test.adoc
            :nodoc:
            :novalid:
            :no-isobib:
            :lutaml-express-index: express_index; #{fixtures_path('expressir_realtive_paths')}; cache=#{cache_path}

            [lutaml_express,express_index,my_context]
            ----
            {% for schema in my_context.schemas %}
            == {{schema.id}}

            {% for remark in schema.remarks %}
            {{ remark }}
            {% endfor %}
            {% endfor %}
            ----
          TEXT
        end
        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
            <sections>
              <clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
              <p id="_">My text</p>
              <p id="_">
              <link target="#{fixtures_path('/expressir_realtive_paths/downloads/report.pdf')}">Get Report
              </p>
              <p id="_">
              <link target="http://test.com/include1.csv">
              </p>
              <p id="_">Unresolved directive in &lt;stdin&gt;&#8201;&#8212;&#8201;include::#{fixtures_path('/expressir_realtive_paths/include1.csv')}[]</p>
              <p id="_">Unresolved directive in &lt;stdin&gt;&#8201;&#8212;&#8201;include::#{fixtures_path('expressir_realtive_paths/test/include1.csv')}[]</p>
              <p id="_">
              <link target="http://test.com/include1.csv">
              </p></clause>
            </sections>
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

    context "when svgmap anchors are used" do
      let(:example_file) { fixtures_path("test_relative_includes_svgmap.exp") }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:

          [lutaml_express,#{example_file},my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}
          {% endfor %}
          ----
        TEXT
      end
      let(:doc_path) { File.dirname(example_file) }
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative">
              <title>annotated_3d_model_data_quality_criteria_schema</title>
              <p id="_">Mine text</p>
              <svgmap>
                <figure id="_">
                  <image src="#{File.expand_path(fixtures_path('measure_schemaexpg5.svg'))}" id="_" mimetype="image/svg+xml"
                    height="auto" width="auto"></image>
                </figure>
                <target href="1">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
                <target href="2">
                  <eref bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref>
                </target>
                <target href="3">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
              </svgmap>
            </clause>
          </sections>
          <bibliography><references hidden="true" normative="false"><bibitem id="express_measure_schema" type="internal">
          <docidentifier type="repository">express/measure_schema</docidentifier>
          </bibitem>
          <bibitem id="express_measure_schemaexpg4" type="internal">
          <docidentifier type="repository">express/measure_schemaexpg4</docidentifier>
          </bibitem>
          </references></bibliography>
          </standard-document>
          </body>

          </html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when lutaml-express-index keyword used with folder path" do
      let(:cache_file_path) { fixtures_path("express_temp_cache_#{SecureRandom.uuid}.yaml") }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :lutaml-express-index: first-express-set; #{fixtures_path('expressir_index_1')};
          :lutaml-express-index: second-express-set; #{fixtures_path('expressir_index_2')}; cache=#{cache_file_path}

          [lutaml_express,first-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----

          [lutaml_express,second-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_mim</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_characterized_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_characterized_mim</title>
            </clause>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      around do |example|
        FileUtils.remove_file(cache_file_path, true)
        example.run
        FileUtils.remove_file(cache_file_path, true)
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end

      it "creates a valid cache file for supplied path" do
        expect { metanorma_process(input) }
          .to(change { File.file?(cache_file_path) }.from(false).to(true))
        expect(::Lutaml::Parser
                .parse(File.new(cache_file_path),
                        Lutaml::Parser::EXPRESS_CACHE_PARSE_TYPE)
                .to_liquid["schemas"]
                .map {|n| n["id"] }
                .sort)
              .to(eq(["Activity_method_characterized_arm", "Activity_method_characterized_mim"]))
      end

      context "when the cache file exists and index folder is not" do
        let(:cache_path) { fixtures_path('lutaml_exp_index_cache.yaml') }
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :docfile: test.adoc
            :nodoc:
            :novalid:
            :no-isobib:
            :lutaml-express-index: express-set; #{fixtures_path('none_existing_path')}; cache=#{cache_path}

            [lutaml_express,express-set,my_context]
            ----
            {% for schema in my_context.schemas %}
            == {{schema.id}}
            {% endfor %}
            ----
          TEXT
        end
        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
            <sections>
              <clause id="_" inline-header="false" obligation="normative">
                <title>annotated_3d_model_data_quality_criteria_schema</title>
              </clause>
            </sections>
            </standard-document>
            </body>

            </html>
          TEXT
        end

        before do
          repository = Expressir::Express::Parser.from_files([File.new(fixtures_path("test.exp"))])
          Expressir::Express::Cache.to_file(cache_path, repository)
        end

        after do
          FileUtils.rm_rf(cache_path)
        end

        it "correctly renders input from cache" do
          expect(xml_string_conent(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end

      # TODO test expressir cache invalidation after the new expressir release
      context "when the cache file is corrupted" do
        let(:cache_path_original) { fixtures_path('lutaml_exp_old_cache_original.yaml') }
        let(:cache_path) { fixtures_path('lutaml_exp_corrupted_cache.yaml') }
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :docfile: test.adoc
            :nodoc:
            :novalid:
            :no-isobib:
            :lutaml-express-index: express-set; #{fixtures_path('expressir_realtive_paths')}; cache=#{cache_path}

            [lutaml_express,express-set,my_context]
            ----
            {% for schema in my_context.schemas %}
            == {{schema.id}}
            {% endfor %}
            ----
          TEXT
        end
        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
            <sections>
              <clause id="_" inline-header="false" obligation="normative">
                <title>annotated_3d_model_data_quality_criteria_schema</title>
              </clause>
            </sections>
            </standard-document>
            </body>

            </html>
          TEXT
        end

        around do |example|
          FileUtils.cp(cache_path_original, cache_path)
          example.run
          FileUtils.rm_rf(cache_path)
        end

        it "fallbacks to the original folder and renders from it" do
          expect(xml_string_conent(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end

        # TODO: metanorma/metanorma-plugin-lutaml#27
        unless Gem.win_platform?
          it "recreates the cache file with the correct data" do
            expect { xml_string_conent(metanorma_process(input)) }
              .to(change do
                wraper = Metanorma::Plugin::Lutaml::Utils.express_from_cache(cache_path) rescue nil
                wraper&.to_liquid&.length
              end.from(nil).to(2))
          end
        end
      end
    end

    context "when lutaml-express-index keyword used with yaml index file" do
      let(:index_file_root_path) { fixtures_path('lutaml_exp_index_root_path.yaml') }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :lutaml-express-index: first-express-set; #{fixtures_path('lutaml_exp_index.yaml')}
          :lutaml-express-index: second-express-set; #{fixtures_path('lutaml_exp_index_2.yaml')};
          :lutaml-express-index: third-express-set; #{index_file_root_path};

          [lutaml_express,first-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----

          [lutaml_express,second-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----

          [lutaml_express,third-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_mim</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_characterized_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_characterized_mim</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_arm</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>annotated_3d_model_data_quality_criteria_schema</title>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>annotated_3d_model_data_quality_criteria_schema</title>
            </clause>
          </sections>
          </standard-document>
          </body>

          </html>
        TEXT
      end

      around do |example|
        FileUtils.remove_file(index_file_root_path, true)
        file = File.new(index_file_root_path, 'w')
        file.puts(File.read(fixtures_path('lutaml_exp_index_root_path_template.yaml')) % { root_path: fixtures_path('') })
        file.close
        example.run
        FileUtils.remove_file(index_file_root_path, true)
      end

      it "correctly renders input from cached index and supplied file" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when multiply files supplied to macro" do
      let(:express_files_list) do
        [
          fixtures_path("test_relative_includes_svgmap.exp"),
          fixtures_path("expressir_index_1/arm_svgmap.exp"),
          fixtures_path("expressir_index_2/mim.exp"),
        ]
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:

          [lutaml_express, #{express_files_list.join('; ')}, my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative">
              <title>annotated_3d_model_data_quality_criteria_schema</title>
              <p id="_">Mine text</p>
              <svgmap>
                <figure id="_">
                  <image
                    src="#{File.expand_path(fixtures_path('measure_schemaexpg5.svg'))}"
                    id="_" mimetype="image/svg+xml" height="auto" width="auto"></image>
                </figure>
                <target
                  href="1">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
                <target
                  href="2">
                  <eref bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref>
                </target>
                <target
                  href="3">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
              </svgmap>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_assignment_arm</title>
              <p id="_">Mine text</p>
              <svgmap>
                <figure id="_">
                  <image
                    src="#{File.expand_path(fixtures_path('expressir_index_1/measure_schemaexpg5.svg'))}"
                    id="_" mimetype="image/svg+xml" height="auto" width="auto"></image>
                </figure>
                <target
                  href="1">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
                <target
                  href="2">
                  <eref bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref>
                </target>
                <target
                  href="3">
                  <eref bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
              </svgmap>
            </clause>
            <clause id="_" inline-header="false" obligation="normative">
              <title>Activity_method_characterized_mim</title>
            </clause>
          </sections>
          <bibliography><references hidden="true" normative="false"><bibitem id="express_measure_schema" type="internal">
          <docidentifier type="repository">express/measure_schema</docidentifier>
          </bibitem>
          <bibitem id="express_measure_schemaexpg4" type="internal">
          <docidentifier type="repository">express/measure_schemaexpg4</docidentifier>
          </bibitem>
          </references></bibliography>
          </standard-document>
          </body>

          </html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when dynamic include block used" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:

          [lutaml_express, #{example_file}, my_context]
          ----
          {% assign my_include = "include" %}
          {{ my_include }}::#{fixtures_path("include_test.adoc")}[]
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
          <title>Test</title>
          <p id="_">My content</p>
          </clause>
          </sections>
          </standard-document>
          </body>
          </html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end
  end
end
