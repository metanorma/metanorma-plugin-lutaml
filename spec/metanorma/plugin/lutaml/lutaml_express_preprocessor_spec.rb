require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "#process" do
    context "when lutaml-express-index keyword used with yaml index file " \
            "(suma schema_attachment)" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :lutaml-express-index: express_index; #{fixtures_path('lutaml_exp_arm_svgmap_index.yaml')}

          [#{macro},express_index,context]
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

      context "when using macro lutaml_express_liquid" do
        let(:macro) { "lutaml_express_liquid" }

        it "correctly renders input from yaml index file" do
          expect(xml_string_content(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "when using macro lutaml_express" do
        let(:macro) { "lutaml_express" }

        it "correctly renders input from yaml index file" do
          expect(xml_string_content(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end
    end

    context "when lutaml-express-index keyword used with yaml index file " \
            "(suma schema_document)" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :lutaml-express-index: express_index; #{fixtures_path('lutaml_exp_arm_svgmap_index.yaml')}

          [#{macro},express_index,context]
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

      context "when using macro lutaml_express_liquid" do
        let(:macro) { "lutaml_express_liquid" }

        it "correctly renders input from yaml index file" do
          File.open("test-1.html", "w") do |file|
            file.write(metanorma_process(input))
          end

          expect(xml_string_content(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "when using macro lutaml_express" do
        let(:macro) { "lutaml_express" }

        it "correctly renders input from yaml index file" do
          File.open("test-2.html", "w") do |file|
            file.write(metanorma_process(input))
          end

          expect(xml_string_content(metanorma_process(input)))
            .to(be_equivalent_to(output))
        end
      end
    end
  end
end
