require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "#process" do
    context "when lutaml-express-index keyword used with yaml index file" do
      context "with macro: lutaml_express_liquid" do
        context "with content like: suma schema_attachment" do
          let(:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :lutaml-express-index: express_index; #{fixtures_path('lutaml_exp_arm_svgmap_index.yaml')}

              [lutaml_express_liquid,express_index,context]
              ----
              {% for schema in context.schemas %}

              [%unnumbered]
              == {{ schema.id }}

              [source%unnumbered]
              --
              {{ schema.formatted }}
              --
              {% endfor %}
              ----
            TEXT
          end

          let(:output) do
            <<~TEXT
              #{BLANK_HDR}<sections>
                <clause id="_" unnumbered="true" inline-header="false" obligation="normative">
                <title>Activity_method_assignment_arm</title>
                <sourcecode id="_" unnumbered="true">SCHEMA Activity_method_assignment_arm;

                USE FROM Activity_method_arm;

                TYPE activity_method_item = EXTENSIBLE GENERIC_ENTITY SELECT;
                END_TYPE;

                ENTITY Activity_method_relationship;
                  name : STRING;
                  description : OPTIONAL STRING;
                  relating_method : Activity_method;
                  related_method : Activity_method;
                END_ENTITY;

                ENTITY Applied_activity_method_assignment;
                  assigned_activity_method : Activity_method;
                  items : SET [1:?] OF activity_method_item;
                  role : STRING;
                END_ENTITY;

                END_SCHEMA;</sourcecode>
                </clause>
              </sections>
              </standard-document>
            TEXT
          end

          it "correctly renders input" do
            expect(xml_string_content(metanorma_process(input)))
              .to(be_equivalent_to(output))
          end
        end

        context "with content like: suma schema_document" do
          let(:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :lutaml-express-index: express_index; #{fixtures_path('lutaml_exp_arm_svgmap_index.yaml')}

              [lutaml_express_liquid,express_index,context]
              ----
              {% for schema in context.schemas %}

              [[#{@id}]]
              [%unnumbered,type=express]
              == #{@id} #{schema_anchors.gsub(%r{//[^\r\n]+}, '').gsub(/[\n\r]+/, '').gsub(/^[\n\r]/, '')}

              [source%unnumbered]
              --
              {{ schema.formatted }}
              --
              {% endfor %}
              ----
            TEXT
          end

          let(:output) do
            <<~TEXT
                 #{BLANK_HDR}<sections>
                   <clause id="_" unnumbered="true" type="express" inline-header="false" obligation="normative">
                       <title>
                          <bookmark id="_"/>
                          [[.types]][[.activity_method_item]][[.entities]][[.Activity_method_relationship]][[.Applied_activity_method_assignment]]
                       </title>
                       <sourcecode id="_" unnumbered="true">SCHEMA Activity_method_assignment_arm;

              USE FROM Activity_method_arm;

              TYPE activity_method_item = EXTENSIBLE GENERIC_ENTITY SELECT;
              END_TYPE;

              ENTITY Activity_method_relationship;
                name : STRING;
                description : OPTIONAL STRING;
                relating_method : Activity_method;
                related_method : Activity_method;
              END_ENTITY;

              ENTITY Applied_activity_method_assignment;
                assigned_activity_method : Activity_method;
                items : SET [1:?] OF activity_method_item;
                role : STRING;
              END_ENTITY;

              END_SCHEMA;</sourcecode>
                    </clause>
                 </sections>
                 </standard-document>
            TEXT
          end

          def bookmark(anchor)
            a = anchor.gsub(/\}\}/, ' | replace: "\", "-"}}')
            "[[#{@id}.#{a}]]"
          end

          def schema_anchors
            <<~HEREDOC
              // _fund_cons.liquid
              [[#{@id}_funds]]

              // _constants.liquid
              {% if schema.constants.size > 0 %}
              #{bookmark('constants')}
              {% for thing in schema.constants %}
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}

              // _types.liquid
              {% if schema.types.size > 0 %}
              #{bookmark('types')}
              // _type.liquid
              {% for thing in schema.types %}
              #{bookmark('{{thing.id}}')}
              {% if thing.items.size > 0 %}
              // _type_items.liquid
              #{bookmark('{{thing.id}}.items')}
              {% for item in thing.items %}
              #{bookmark('{{thing.id}}.items.{{item.id}}')}
              {% endfor %}
              {% endif %}
              {% endfor %}
              {% endif %}

              // _entities.liquid
              {% if schema.entities.size > 0 %}
              #{bookmark('entities')}
              {% for thing in schema.entities %}
              // _entity.liquid
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}

              // _subtype_constraints.liquid
              {% if schema.subtype_constraints.size > 0 %}
              #{bookmark('subtype_constraints')}
              // _subtype_constraint.liquid
              {% for thing in schema.subtype_constraints %}
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}

              // _functions.liquid
              {% if schema.functions.size > 0 %}
              #{bookmark('functions')}
              // _function.liquid
              {% for thing in schema.functions %}
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}

              // _procedures.liquid
              {% if schema.procedures.size > 0 %}
              #{bookmark('procedures')}
              // _procedure.liquid
              {% for thing in schema.procedures %}
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}

              // _rules.liquid
              {% if schema.rules.size > 0 %}
              #{bookmark('rules')}
              // _rule.liquid
              {% for thing in schema.rules %}
              #{bookmark('{{thing.id}}')}
              {% endfor %}
              {% endif %}
            HEREDOC
          end

          it "correctly renders input" do
            expect(xml_string_content(metanorma_process(input)))
              .to(be_equivalent_to(output))
          end
        end

        context "with config_yaml" do
          let(:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :lutaml-express-index: express_index; #{fixtures_path('lutaml_exp_index.yaml')}

              [lutaml_express_liquid,express_index,context,config_yaml=#{fixtures_path('lutaml_exp_arm_svgmap_index.yaml')}]
              ----
              {% assign selected = context.schemas | where: "selected" %}
              {% for schema in selected %}

              [%unnumbered]
              == {{ schema.id }}

              [source%unnumbered]
              --
              {{ schema.formatted }}
              --

              {% endfor %}
              ----
            TEXT
          end

          let(:output) do
            <<~TEXT
              #{BLANK_HDR}<sections>
                <clause id="_" unnumbered="true" inline-header="false" obligation="normative">
                <title>Activity_method_assignment_arm</title>
                <sourcecode id="_" unnumbered="true">SCHEMA Activity_method_assignment_arm;

                USE FROM Activity_method_arm;

                TYPE activity_method_item = EXTENSIBLE GENERIC_ENTITY SELECT;
                END_TYPE;

                ENTITY Activity_method_relationship;
                  name : STRING;
                  description : OPTIONAL STRING;
                  relating_method : Activity_method;
                  related_method : Activity_method;
                END_ENTITY;

                ENTITY Applied_activity_method_assignment;
                  assigned_activity_method : Activity_method;
                  items : SET [1:?] OF activity_method_item;
                  role : STRING;
                END_ENTITY;

                END_SCHEMA;</sourcecode>
                </clause>
              </sections>
              </standard-document>
            TEXT
          end

          it "correctly renders input" do
            expect(xml_string_content(metanorma_process(input)))
              .to(be_equivalent_to(output))
          end
        end

        context "when additional options passed" do
          let(:example_file) do
            fixtures_path("test_relative_includes_svgmap.exp")
          end

          let(:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              [lutaml_express_liquid,#{example_file},my_context]
              ----

              {% for schema in my_context.schemas %}
              == {{schema.id}}

              {% for remark in schema.remarks %}
              {{ remark }}
              {% endfor %}
              {% endfor %}

              ----


              [lutaml_express_liquid,#{example_file},my_context]
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
              #{BLANK_HDR}<sections><clause id="_" inline-header="false" obligation="normative"><title>annotated_3d_model_data_quality_criteria_schema</title>
              <p id="_">Mine text</p>
              <svgmap><figure id="_">
              <image src="#{File.expand_path(fixtures_path('measure_schemaexpg5.svg'))}" id="_" mimetype="image/svg+xml" height="auto" width="auto"></image>
              </figure><target href="1"><eref style="short" bibitemid="express_measure_schema" citeas="">measure_schema</eref></target><target href="2"><eref style="short" bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref></target><target href="3"><eref style="short" bibitemid="express_measure_schema" citeas="">measure_schema</eref></target></svgmap></clause>
              <clause id="_" inline-header="false" obligation="normative">
              <title>annotated_3d_model_data_quality_criteria_schema</title>
              <p id="_">Mine text</p>
              <svgmap>
                <figure id="_">
                  <image
                    src="#{File.expand_path(fixtures_path('measure_schemaexpg5.svg'))}"
                    id="_" mimetype="image/svg+xml" height="auto" width="auto"></image>
                </figure>
                <target href="1">
                  <eref style="short" bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
                <target href="2">
                  <eref style="short" bibitemid="express_measure_schemaexpg4" citeas="">measure_schemaexpg4</eref>
                </target>
                <target href="3">
                  <eref style="short" bibitemid="express_measure_schema" citeas="">measure_schema</eref>
                </target>
              </svgmap>
              </clause></sections>
              <bibliography><references hidden="true" normative="false"><bibitem id="express_measure_schema" type="internal">
              <docidentifier type="repository">express/measure_schema</docidentifier>
              </bibitem>
              <bibitem id="express_measure_schemaexpg4" type="internal">
              <docidentifier type="repository">express/measure_schemaexpg4</docidentifier>
              </bibitem>
              </references></bibliography></standard-document>
            TEXT
          end

          it "correctly renders input" do
            expect(xml_string_content(metanorma_process(input)))
              .to(be_equivalent_to(output))
          end
        end
      end
    end
  end
end
