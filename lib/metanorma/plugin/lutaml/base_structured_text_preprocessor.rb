# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require_relative "source_extractor"
require_relative "utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"

module Metanorma
  module Plugin
    module Lutaml
      # Base class for processing structured data blocks(yaml, json)
      class BaseStructuredTextPreprocessor <
        ::Asciidoctor::Extensions::Preprocessor
        include Utils

        BLOCK_START_REGEXP = /\{(.+?)\.\*,(.+),(.+)\}/.freeze
        BLOCK_END_REGEXP = /\A\{[A-Z]+\}\z/.freeze
        LOAD_FILE_REGEXP = /{% assign (.*) = (.*) \| load_file %}/.freeze
        INCLUDE_PATH_OPTION = "include_path"
        TEMPLATE_OPTION = "template"

        def process(document, reader)
          r = Asciidoctor::PreprocessorNoIfdefsReader
            .new(document, reader.lines)
          input_lines = r.readlines
          Metanorma::Plugin::Lutaml::SourceExtractor
            .extract(document, input_lines)
          result_content = processed_lines(document, input_lines.to_enum)
          Asciidoctor::PreprocessorNoIfdefsReader.new(document, result_content)
        end

        protected

        def content_from_file(_document, _file_path)
          raise ArgumentError, "Implement `content_from_file` in your class"
        end

        def content_from_anchor(_document, _file_path)
          raise ArgumentError, "Implement `content_from_anchor` in your class"
        end

        private

        def process_text_blocks(document, input_lines)
          line = input_lines.next
          block_match = line.match(/^\[#{config[:block_name]},(.+?)\]/)
          return [line] if block_match.nil?

          end_mark = input_lines.next
          parse_template(
            document,
            collect_internal_block_lines(document, input_lines, end_mark),
            block_match,
          )
        end

        def collect_internal_block_lines(document, input_lines, end_mark) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          current_block = []
          while (block_line = input_lines.next) != end_mark
            if block_line.match?(LOAD_FILE_REGEXP)
              load_file_match = block_line.match(LOAD_FILE_REGEXP)

              # Add parent folder as argument to loadfile filter
              block_line = "{% assign #{load_file_match[1]} = "\
                           "#{load_file_match[2]} | loadfile: " \
                           "\"#{document.attributes['docdir']}\" %}"
            end

            current_block.push(block_line)
          end
          current_block
        end

        def data_file_type
          @config[:block_name].split("2").first
        end

        def parse_template(document, current_block, block_match) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          transformed_liquid_lines = current_block.map do |x|
            transform_line_liquid(x)
          end

          contexts, include_path, template_path = resolve_context(
            document, block_match
          )

          parse_context_block(
            document: document,
            context_lines: transformed_liquid_lines,
            contexts: contexts,
            include_path: include_path,
            template_path: template_path,
          )
        end

        def resolve_context(document, block_match) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          include_path = nil
          template_path = nil

          contexts = if block_match[1].include?("=")
                       multiple_contexts, include_path, template_path =
                         content_from_multiple_contexts(
                           document, block_match[1].split(",")
                         )
                       multiple_contexts
                     elsif block_match[1].start_with?("#")
                       anchor = block_match[1].split(",").first.strip[1..-1]
                       {
                         block_match[1].split(",").last.strip =>
                           content_from_anchor(document, anchor),
                       }
                     else
                       path = block_match[1].split(",").first.strip
                       {
                         block_match[1].split(",").last.strip =>
                           content_from_file(document, path),
                       }
                     end
          [contexts, include_path, template_path]
        end

        def content_from_multiple_contexts(document, context_and_paths) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          contexts = {}
          include_path = nil
          template_path = nil

          context_and_paths.each do |context_and_path|
            context_and_path.strip!
            context_name, path = context_and_path.split("=")

            if context_name == INCLUDE_PATH_OPTION
              include_path = path
            elsif context_name == TEMPLATE_OPTION
              template_path = path
            else
              context_items = content_from_file(document, path)
              contexts[context_name] = context_items
            end
          end

          [contexts, include_path, template_path]
        end

        def transform_line_liquid(line) # rubocop:disable Metrics/MethodLength
          if line.match?(BLOCK_START_REGEXP)
            line.gsub!(BLOCK_START_REGEXP, '{% keyiterator \1, \2 %}')
          end

          if line.strip.match?(BLOCK_END_REGEXP)
            line.gsub!(BLOCK_END_REGEXP, "{% endkeyiterator %}")
          end
          line
            .gsub(/(?<!{){(?!%)([^{}]{1,900})(?<!%)}(?!})/, '{{\1}}')
            .gsub(/[a-z\.]{1,900}\#/, "index")
            .gsub(/{{([^}]{1,900})\s+\+\s+(\d+)\s*?}}/, '{{ \1 | plus: \2 }}')
            .gsub(/{{([^}]{1,900})\s+-\s+(\d+)\s*?}}/, '{{ \1 | minus: \2 }}')
            .gsub(/{{([^}]{1,500})\.values([^}]{0,500})}}/,
                  '{% assign custom_value = \1 | values %}{{custom_value\2}}')
        end

        def parse_context_block( # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          context_lines:, contexts:, document:,
          include_path: nil, template_path: nil
        )
          if include_path
            include_path = relative_file_path(document, include_path)
          end

          if template_path
            template_path = relative_file_path(document, template_path)
          end

          render_result, errors = render_liquid_string(
            template_string: context_lines.join("\n"),
            contexts: contexts,
            document: document,
            include_path: include_path,
            template_path: template_path,
          )
          notify_render_errors(document, errors)
          render_result.split("\n")
        end
      end
    end
  end
end
