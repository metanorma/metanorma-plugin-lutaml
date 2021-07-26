# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "metanorma/plugin/lutaml/utils"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      #  @example [lutaml_uml_attributes_table,path/to/lutaml,EntityName]
      class LutamlUmlAttributesTablePreprocessor < Asciidoctor::Extensions::Preprocessor
        MARCO_REGEXP =
          /\[lutaml_uml_attributes_table,([^,]+),?(.+)?,([^,]+),?(.+)?\]/
        # search document for block `datamodel_attributes_table`
        #  read include derectives that goes after that in block and transform
        #  into yaml2text blocks
        def process(document, reader)
          input_lines = reader.readlines.to_enum
          Asciidoctor::Reader.new(processed_lines(document, input_lines))
        end

        private

        def lutaml_document_from_file(document, file_path)
          ::Lutaml::Parser
            .parse(File.new(Utils.relative_file_path(document, file_path),
                            encoding: "UTF-8"))
            .first
        end

        def processed_lines(document, input_lines)
          input_lines.each_with_object([]) do |line, result|
            if match = line.match(MARCO_REGEXP)
              lutaml_path = match[1]
              entity_name = match[3]
              result.push(*parse_marco(lutaml_path, entity_name, document))
            else
              result.push(line)
            end
          end
        end

        def parse_marco(lutaml_path, entity_name, document)
          lutaml_document = lutaml_document_from_file(document, lutaml_path)
            .serialized_document
          entities = [lutaml_document["classes"], lutaml_document["enums"]]
            .compact
            .flatten
          entity_definition = entities.detect do |klass|
            klass["name"] == entity_name.strip
          end
          model_representation(entity_definition, document)
        end

        def model_representation(entity_definition, document)
          render_result, errors = Utils.render_liquid_string(
            template_string: table_template,
            context_items: entity_definition,
            context_name: "definition",
            document: document
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        # rubocop:disable Layout/IndentHeredoc
        def table_template
          <<~TEMPLATE
          === {{ definition.name }}
          {{ definition.definition }}

          {% if definition.attributes %}
          {% if definition.keyword == 'enumeration' %}
          .{{ definition.name }} values
          |===
          |Name |Definition

          {% for item in definition.attributes %}
          |{{ item.name }} |{{ item.definition }}
          {% endfor %}
          |===
          {% else %}
          .{{ definition.name }} attributes
          |===
          |Name |Definition |Mandatory/ Optional/ Conditional |Max Occur |Data Type

          {% for item in definition.attributes %}
          |{{ item.name }} |{% if item.definition %}{{ item.definition }}{% endif %} |{% if item.cardinality.min == "0" %}O{% else %}M{% endif %} |{% if item.cardinality.max == "*" %}N{% else %}1{% endif %} |{% if item.origin %}<<{{ item.origin }}>>{% endif %} `{{ item.type }}`
          {% endfor %}
          |===
          {% endif %}
          {% endif %}

          TEMPLATE
        end
        # rubocop:enable Layout/IndentHeredoc
      end
    end
  end
end
