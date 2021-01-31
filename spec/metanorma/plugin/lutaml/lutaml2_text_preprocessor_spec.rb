require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("test.exp") }

    context "Array of hashes" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml,#{example_file},my_context]
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
          :imagesdir: spec/assets
          [lutaml,#{example_file},my_context, leveloffset=+2]
          ----

          {% for schema in my_context.schemas %}
          == {{schema.id}}

          {% for remark in schema.remarks %}
          {{ remark }}
          {% endfor %}

          {% endfor %}
          ----


          [lutaml,#{example_file},my_context, leveloffset=-1]
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
                <p id="_">$Id: test.exp,v 1.3 2020/07/30 05:18:54 ftanaka Exp $
                  ISO 10303 TC184/SC4/WG12 N10658</p>
                <clause id="_" inline-header="false" obligation="normative">
                  <title>EXPRESS Source:</title>
                  <p id="_">ISO 10303-59 ed3 Quality of product shape data — Annotated 3d model data quality criteria
                    schema</p>
                  <p id="_">The following permission notice and disclaimer shall be included in all copies of this EXPRESS
                    schema (“the Schema”),
                    and derivations of the Schema:</p>
                  <p id="_">Need select eleemnts for measure_value</p>
                </clause>
              </clause>
              <clause id="_" inline-header="false" obligation="normative">
                <title>annotated_3d_model_data_quality_criteria_schema</title>
                <p id="_">$Id: test.exp,v 1.3 2020/07/30 05:18:54 ftanaka Exp $
                  ISO 10303 TC184/SC4/WG12 N10658</p>
                <figure id="_">
                  <pre id="_"> EXPRESS Source:
            ISO 10303-59 ed3 Quality of product shape data - Annotated 3d model data quality criteria schema</pre>
                </figure>
                <p id="_">The following permission notice and disclaimer shall be included in all copies of this EXPRESS
                  schema (“the Schema”),
                  and derivations of the Schema:</p>
                <p id="_">Need select eleemnts for measure_value</p>
            </clause>
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

    context "when relative paths exists in doc" do
      let(:example_file) { fixtures_path("test_relative_includes.exp").gsub(FileUtils.pwd, '')[1..-1] }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml,#{example_file},my_context]
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
            <link target="#{doc_path}/downloads/report.pdf">Get Report
            </p>
            <p id="_">
            <link target="http://test.com/include1.csv">
            </p>


            <p id="_">include::#{doc_path}/include1.csv[]</p>
            <p id="_">include::#{doc_path}/test/include1.csv[]</p>
            <p id="_">include::http://test.com/include1.csv[]</p>
            <figure id="_">
              <pre id="_"></pre>
            </figure>
            </clause>
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


    context "when lutaml-express-index keyword used" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets
          :lutaml-express-index: first-express-set; #{fixtures_path('expressir_index_1')};
          :lutaml-express-index: second-express-set; #{fixtures_path('expressir_index_2')};

          [lutaml,first-express-set,my_context]
          ----
          {% for schema in my_context.schemas %}
          == {{schema.id}}
          {% endfor %}
          ----

          [lutaml,second-express-set,my_context]
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

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when multiply files supplied to macro" do
      let(:express_files_list) do
        [
          fixtures_path("test.exp"),
          fixtures_path("expressir_index_1/arm.exp"),
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
          :imagesdir: spec/assets

          [lutaml, #{express_files_list.join('; ')}, my_context]
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
              <clause id="_" inline-header="false" obligation="normative">
                <title>Activity_method_assignment_arm</title>
              </clause>
              <clause id="_" inline-header="false" obligation="normative">
                <title>Activity_method_characterized_mim</title>
              </clause>
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
end
