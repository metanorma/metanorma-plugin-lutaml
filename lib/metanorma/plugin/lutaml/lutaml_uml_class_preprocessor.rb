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
      #  @example [lutaml_uml_class,path/to/lutaml,EntityName]
      class LutamlUmlClassPreprocessor < Asciidoctor::Extensions::Preprocessor
        MACRO_REGEXP =
          /\[lutaml_uml_class,([^,]+),?([^,]+),?(.+?)?\]/

        def get_macro_regexp
          self.class.const_get(:MACRO_REGEXP)
        end

        # search document for block `datamodel_attributes_table`
        #  read include derectives that goes after that in block and transform
        #  into yaml2text blocks
        def process(document, reader)
          input_lines = reader.readlines.to_enum
          Asciidoctor::Reader.new(processed_lines(document, input_lines))
        end

        private

        def lutaml_document_from_file(document, file_path)
          ::Lutaml::Parser.parse(
            File.new(
              Utils.relative_file_path(document, file_path),
              encoding: "UTF-8")
            ).first
        end

        def parse_options_to_hash(options_string)
          return {} if options_string.nil? || options_string.empty?

          options_string.split(",").inject({}) do |acc,pair|
            key, value = pair.split("=")
            value = true if value.nil?
            acc[key.to_sym] = value if key
            acc
          end
        end

        def processed_lines(document, input_lines)
          input_lines.each_with_object([]) do |line, result|
            if match = line.match(get_macro_regexp)
              lutaml_path = match[1]
              entity_name = match[2]
              options = parse_options_to_hash(match[3])

              result.push(*parse_marco(lutaml_path, entity_name, document, options))
            else
              result.push(line)
            end
          end
        end

        def parse_marco(lutaml_path, entity_name, document, options)
          lutaml_document = lutaml_document_from_file(document, lutaml_path)
            .serialized_document
          entities = [lutaml_document["classes"], lutaml_document["enums"]]
            .compact
            .flatten
          entity_definition = entities.detect do |klass|
            klass["name"] == entity_name.strip
          end
          model_representation(entity_definition, document, options)
        end

        def model_representation(entity_definition, document, options)
          render_result, errors = Utils.render_liquid_string(
            template_string: template(options),
            context_items: entity_definition,
            context_name: "definition",
            document: document
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def equalsigns
        end

        # rubocop:disable Layout/IndentHeredoc
        def template(options)
          skip_headers = options[:skip_headers]

          <<~TEMPLATE
          #{"=== {{ definition.name }}" unless skip_headers}
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
          ==== Attributes

          {% for item in definition.attributes %}
          ===== {{item.name}}

          {% if item.definition %}
          {{ item.definition }}
          {% endif %}

          .Specification of `{{ definition.name }}.{{ item.name }}`
          [cols="h,a"]
          |===

          h|Value type and multiplicity
          |
          `{{ item.type }}`
          {% if item.cardinality.min -%}
          {% if item.cardinality.max -%}
          `[{{item.cardinality.min}}..{{item.cardinality.max}}]`
          {% else -%}
          `[{{item.cardinality.min}}]`
          {% endif -%}
          {% else -%}
          (multiplicity unspecified)
          {% endif %}

          {% if item.origin %}
          h|Origin
          |<<{{ item.origin }}>>
          {% endif %}

          |===
          {% endfor %}

          {% endif %}
          {% endif %}

          TEMPLATE
        end
        # rubocop:enable Layout/IndentHeredoc
      end
    end
  end
end
