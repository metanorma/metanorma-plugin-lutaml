# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/utils"

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
      class LutamlPreprocessor < Asciidoctor::Extensions::Preprocessor
        def process(document, reader)
          input_lines = reader.readlines.to_enum
          express_indexes = Utils.parse_document_express_indexes(
            document,
            input_lines
          )
          Asciidoctor::Reader
            .new(processed_lines(document, input_lines, express_indexes))
        end

        protected

        def content_from_file(document, file_path)
          ::Lutaml::Parser
            .parse(File.new(Utils.relative_file_path(document, file_path),
                            encoding: "UTF-8"))
        end

        private

        def processed_lines(document, input_lines, express_indexes)
          result = []
          loop do
            result
              .push(*process_text_blocks(
                document,
                input_lines,
                express_indexes
              ))
          end
          result
        end

        def process_text_blocks(document, input_lines, express_indexes)
          line = input_lines.next
          block_match = line.match(/^\[lutaml,(.+?),(.+?)\]/)
          return [line] if block_match.nil?

          end_mark = input_lines.next
          parse_template(document,
                         collect_internal_block_lines(document,
                                                      input_lines,
                                                      end_mark),
                         block_match,
                         express_indexes)
        end

        def collect_internal_block_lines(_document, input_lines, end_mark)
          current_block = []
          while (block_line = input_lines.next) != end_mark
            current_block.push(block_line)
          end
          current_block
        end

        def contexts_items(block_match, document, express_indexes)
          contexts_names = block_match[1].split(";").map(&:strip)
          contexts_names.each_with_object([]) do |path, res|
            if express_indexes[path]
              res.push(*express_indexes[path])
            else
              res.push(content_from_file(document, path))
            end
          end
        end

        def parse_template(document, current_block, block_match, express_indexes)
          contexts_items(block_match, document, express_indexes)
            .map do |context_items|
              parse_context_block(document: document,
                                  context_lines: current_block,
                                  context_items: context_items,
                                  context_name: block_match[2].strip)
            end.flatten
        rescue StandardError => e
          document.logger.warn("Failed to parse lutaml block: #{e.message}")
          []
        end

        def parse_context_block(context_lines:,
                                context_items:,
                                context_name:,
                                document:)
          render_result, errors = Utils.render_liquid_string(
            template_string: context_lines.join("\n"),
            context_items: context_items,
            context_name: context_name
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end
      end
    end
  end
end
