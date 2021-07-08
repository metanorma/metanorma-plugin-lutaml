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
      class LutamlUmlDatamodelDescriptionPreprocessor < Asciidoctor::Extensions::Preprocessor
        MARCO_REGEXP =
          /\[lutaml_uml_datamodel_description,([^\]]+)]/
        SUPPORTED_NESTED_MACROSES = %w[preface footer]
        # search document for block `lutaml_uml_datamodel_description`
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
          result = []
          loop do
            result.push(*process_text_blocks(document, input_lines))
          end
          result
        end

        def lutaml_document_from_file(document, file_path)
          ::Lutaml::Parser
            .parse(File.new(Utils.relative_file_path(document, file_path),
                            encoding: "UTF-8"))
            .first
        end

        def process_text_blocks(document, input_lines)
          line = input_lines.next
          block_match = line.match(MARCO_REGEXP)
          return [line] if block_match.nil?

          model_representation(
            lutaml_document_from_file(document, block_match[1]),
            document,
            collect_additional_context(document, input_lines, input_lines.next))
        end

        def collect_additional_context(document, input_lines, end_mark)
          additional_context = {}
          while (block_line = input_lines.next) != end_mark
            nested_match = SUPPORTED_NESTED_MACROSES
                            .map { |macro| [macro, block_line.match(/\[.#{macro}\]/)] }
                            .find { |n| !n.last.nil? }
            nested_context_value = []
            if nested_match
              nested_end_mark = input_lines.next
              while (block_line = input_lines.next) != nested_end_mark
                nested_context_value.push(block_line)
              end
              additional_context[nested_match.first] = nested_context_value.join("\n")
            end
          end
          additional_context
        end

        def model_representation(lutaml_document, document, additional_context)
          liquid_templates_path = File
                                    .join(
                                      Gem.loaded_specs['metanorma-plugin-lutaml'].full_gem_path,
                                      'lib',
                                      'metanorma',
                                      'plugin',
                                      'lutaml',
                                      'liquid_templates')
          render_result, errors = Utils.render_liquid_string(
            template_string: table_template,
            context_items: lutaml_document.to_liquid.merge('additional_context' => additional_context),
            context_name: "context",
            document: document,
            include_path: liquid_templates_path
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def table_template
          <<~LIQUID
            {% include "packages", depth: 3, context: context, additional_context: context.additional_context %}
          LIQUID
        end
      end
    end
  end
end
