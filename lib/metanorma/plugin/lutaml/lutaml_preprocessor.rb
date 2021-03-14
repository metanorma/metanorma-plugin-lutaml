# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/express_remarks_decorator"

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
      class LutamlPreprocessor < Asciidoctor::Extensions::Preprocessor
        REMARKS_ATTRIBUTE = "remarks".freeze

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

        def content_from_files(document, file_paths)
          file_list = file_paths.map do |file_path|
            File.new(Utils.relative_file_path(document, file_path), encoding: "UTF-8")
          end
          ::Lutaml::Parser.parse(file_list)
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
          block_match = line.match(/^\[lutaml,([^,]+)?,?([^,]+)?,?([^,]+)?\]/)
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
          file_paths = []
          result = contexts_names.each_with_object([]) do |path, res|
            if express_indexes[path]
              res.push(*express_indexes[path])
            else
              file_paths.push(path)
            end
          end
          if !file_paths.empty?
            from_files = content_from_files(document, file_paths)
                          .map do |n|
                            n.to_liquid.map { |j| j.merge('relative_path_prefix' => Utils.relative_file_path(document, File.dirname(j['file']))) }
                          end
                          .flatten
            result += from_files
          end
          result
        end

        def parse_template(document, current_block, block_match, express_indexes)
          options = parse_options(block_match[3])
          contexts_items(block_match, document, express_indexes)
            .map do |items|
              opts = options.merge('relative_path_prefix' => items['relative_path_prefix'])
              parse_context_block(document: document,
                                  context_lines: current_block,
                                  context_items: decorate_context_items(items, opts),
                                  context_name: block_match[2].strip)
            end.flatten
        rescue StandardError => e
          document.logger.warn("Failed to parse lutaml block: #{e.message}")
          []
        end

        def parse_options(options_string)
          options_string
            .to_s
            .scan(/(.+?)=(\s?[^\s]+)/)
            .map { |elem| elem.map(&:strip) }
            .to_h
        end

        def decorate_context_items(context_items, options)
          return context_items if !context_items.is_a?(Hash)

          context_items
            .map do |(key, val)|
              if val.is_a?(Hash)
                [key, decorate_context_items(val, options)]
              elsif key == REMARKS_ATTRIBUTE
                [key,
                 val&.map do |remark|
                   Metanorma::Plugin::Lutaml::ExpressRemarksDecorator
                     .call(remark, options)
                 end]
              elsif val.is_a?(Array)
                [key, val.map { |n| decorate_context_items(n, options) }]
              else
                [key, val]
              end
            end
            .to_h
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
