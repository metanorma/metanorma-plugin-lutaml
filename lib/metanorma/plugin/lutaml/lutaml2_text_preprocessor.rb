# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml/uml"
require "lutaml/uml/parsers/dsl"

::Lutaml::Uml::Document.class_eval do
  def to_liquid
    serialize_to_hash(self)
  end

  def serialize_to_hash(object)
    object.instance_variables.each_with_object({}) do |var, res|
      variable = object.instance_variable_get(var)
      if variable.is_a?(Array)
        res[var.to_s.gsub("@", '')] = variable.map { |n| serialize_to_hash(n) }
      else
        res[var.to_s.gsub("@", '')] = variable
      end
    end
  end
end

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
      class Lutaml2TextPreprocessor <
        Asciidoctor::Extensions::Preprocessor

        def process(document, reader)
          input_lines = reader.readlines.to_enum
          Asciidoctor::Reader.new(processed_lines(document, input_lines))
        end

        protected

        def content_from_file(document, file_path)
          ::Lutaml::Uml::Parsers::Dsl
            .parse(File.new(relative_file_path(document, file_path),
                            encoding: "UTF-8"))
        end

        private

        def processed_lines(document, input_lines)
          result = []
          loop do
            result.push(*process_text_blocks(document, input_lines))
          end
          result
        end

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || "."
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def process_text_blocks(document, input_lines)
          line = input_lines.next
          block_match = line.match(/^\[lutaml2text,(.+?),(.+?)\]/)
          return [line] if block_match.nil?

          end_mark = input_lines.next
          parse_template(document,
                         collect_internal_block_lines(document,
                                                      input_lines,
                                                      end_mark),
                         block_match)
        end

        def collect_internal_block_lines(document, input_lines, end_mark)
          current_block = []
          nested_marks = []
          while (block_line = input_lines.next) != end_mark
            current_block.push(block_line)
          end
          current_block
        end

        def parse_template(document, current_block, block_match)
          context_items = content_from_file(document, block_match[1])
          parse_context_block(document: document,
                              context_lines: current_block,
                              context_items: context_items,
                              context_name: block_match[2])
        rescue StandardError => e
          document.logger
            .warn("Failed to parse lutaml2text \
              block: #{e.message}")
          []
        end

        def parse_context_block(context_lines:,
                                context_items:,
                                context_name:,
                                document:)
          render_result, errors = render_liquid_string(
            template_string: context_lines.join("\n"),
            context_items: context_items,
            context_name: context_name
          )
          notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def render_liquid_string(template_string:, context_items:,
                                 context_name:)
          liquid_template = Liquid::Template.parse(template_string)
          rendered_string = liquid_template.render(context_name => context_items,strict_variables: true,error_mode: :warn)
          [rendered_string, liquid_template.errors]
        end

        def notify_render_errors(document, errors)
          errors.each do |error_obj|
            document
              .logger
              .warn("Liquid render error: #{error_obj.message}")
          end
        end
      end
    end
  end
end
