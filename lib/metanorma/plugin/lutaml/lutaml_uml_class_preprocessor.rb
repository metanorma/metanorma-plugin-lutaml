# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      #  @example [lutaml_uml_class,path/to/lutaml,EntityName]
      class LutamlUmlClassPreprocessor < ::Asciidoctor::Extensions::Preprocessor
        MACRO_REGEXP =
          /\[lutaml_uml_class,([^,]+),?([^,]+),?(.+?)?\]/.freeze

        def get_macro_regexp
          self.class.const_get(:MACRO_REGEXP)
        end

        # search document for block `datamodel_attributes_table`
        #  read include derectives that goes after that in block and transform
        #  into yaml2text blocks
        def process(document, reader)
          r = Asciidoctor::PreprocessorNoIfdefsReader.new document, reader.lines
          input_lines = r.readlines.to_enum
          Asciidoctor::PreprocessorNoIfdefsReader
            .new(document, processed_lines(document, input_lines))
        end

        private

        def lutaml_document_from_file(document, file_path)
          ::Lutaml::Parser.parse(
            File.new(
              Utils.relative_file_path(document, file_path),
              encoding: "UTF-8",
            ),
          ).first
        end

        DEFAULT_OPTIONS = { depth: 2 }.freeze

        def parse_options_to_hash(options_string)
          return DEFAULT_OPTIONS.dup if options_string.nil? ||
            options_string.empty?

          opts = options_string.split(",").inject({}) do |acc, pair|
            key, value = pair.split("=")
            key = key.to_sym
            value = true if value.nil?
            value = value.to_i if key == :depth
            acc[key] = value if key
            acc
          end

          DEFAULT_OPTIONS.dup.merge(opts)
        end

        def processed_lines(document, input_lines)
          input_lines.each_with_object([]) do |line, result|
            if match = line.match(get_macro_regexp)
              lutaml_path = match[1]
              entity_name = match[2]
              options = parse_options_to_hash(match[3])

              result.push(*parse_macro(lutaml_path, entity_name, document,
                                       options))
            else
              result.push(line)
            end
          end
        end

        def parse_macro(lutaml_path, entity_name, document, options)
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
            document: document,
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def equalsigns(depth)
          "=" * depth
        end

        # rubocop:disable Layout/IndentHeredoc
        def template(options)
          skip_headers = options[:skip_headers]
          depth = options[:depth]

          <<~TEMPLATE
            {% if definition.keyword == 'enumeration' %}
            #{"#{equalsigns(depth)} Enumeration: {{ definition.name }}" unless skip_headers}
            {% else %}
            #{"#{equalsigns(depth)} Class: {{ definition.name }}" unless skip_headers}
            {% endif %}

            #{equalsigns(depth + 1)} Description

            {{ definition.definition }}

            {% if definition.attributes %}
            {% if definition.keyword == 'enumeration' %}
            {% for item in definition.attributes %}
            #{equalsigns(depth + 1)} Enumeration value: {{item.name}}

            {% if item.definition %}
            {{ item.definition }}
            {% endif %}

            {% endfor %}

            {% else %}

            {% for item in definition.attributes %}
            #{equalsigns(depth + 1)} Attribute: {{item.name}}

            {% if item.definition %}
            {{ item.definition }}
            {% endif %}

            Value type and multiplicity:
            {% if item.type -%}{{ item.type }}{% else -%}(no type specified){% endif %}
            {% if item.cardinality.min -%}
            {% if item.cardinality.max -%}
            {blank}[{{item.cardinality.min}}..{{item.cardinality.max}}]
            {% else -%}
            {blank}[{{item.cardinality.min}}]
            {% endif -%}
            {% else -%}
            (multiplicity unspecified)
            {% endif %}

            {% if item.origin %}
            Origin: <<{{ item.origin }}>>
            {% endif %}

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
