# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
      class LutamlPreprocessor < ::Asciidoctor::Extensions::Preprocessor
        REMARKS_ATTRIBUTE = "remarks"

        def process(document, reader) # rubocop:disable Metrics/MethodLength
          r = Asciidoctor::PreprocessorNoIfdefsReader.new(document,
                                                          reader.lines)
          input_lines = r.readlines.to_enum

          has_lutaml_liquid = input_lines.any? { |line| lutaml_liquid?(line) }

          express_indexes = Utils.parse_document_express_indexes(
            document,
            input_lines,
          )

          result_content = process_input_lines(
            document: document,
            input_lines: input_lines,
            express_indexes: express_indexes,
          )

          log(document, result_content) if has_lutaml_liquid

          Asciidoctor::PreprocessorNoIfdefsReader.new(document, result_content)
        end

        protected

        def log(doc, text)
          File.open("#{doc.attr('docfile')}.lutaml.log.txt", "w:UTF-8") do |f|
            f.write(text.join("\n"))
          end
        end

        def lutaml_liquid?(line)
          line.match(/^\[(?:\blutaml\b|\blutaml_express\b|\blutaml_express_liquid\b),(?<index_names>[^,]+)?,?(?<context_name>[^,]+)?(?<options>,.*)?\]/) # rubocop:disable Layout/LineLength
        end

        def load_lutaml_file(document, file_path)
          ::Lutaml::Parser.parse(
            File.new(
              Utils.relative_file_path(document, file_path),
              encoding: "UTF-8",
            ),
          )
        end

        private

        def process_input_lines(document:, input_lines:, express_indexes:)
          result = []
          loop do
            result.push(
              *process_text_blocks(document, input_lines, express_indexes),
            )
          end
          result
        end

        def process_text_blocks(document, input_lines, express_indexes) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
          line = input_lines.next
          block_header_match = lutaml_liquid?(line)

          return [line] if block_header_match.nil?

          index_names = block_header_match[:index_names].split(";").map(&:strip)
          context_name = block_header_match[:context_name].strip

          options = block_header_match[:options] &&
            parse_options(block_header_match[:options].to_s.strip) || {}

          end_mark = input_lines.next

          render_liquid_template(
            document: document,
            lines: extract_block_lines(input_lines, end_mark),
            index_names: index_names,
            context_name: context_name,
            options: options,
            indexes: express_indexes,
          )
        end

        def extract_block_lines(input_lines, end_mark)
          block = []
          while (block_line = input_lines.next) != end_mark
            block.push(block_line)
          end
          block
        end

        def gather_context_liquid_items(index_names:, document:, indexes:, # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
selected_schemas:, options:)
          index_names.map do |path|
            if indexes[path]
              indexes[path][:liquid_drop] ||=
                indexes[path][:wrapper].original_document.to_liquid(
                  selected_schemas: selected_schemas,
                  options: options,
                )
            else
              full_path = Utils.relative_file_path(document, path)
              unless File.file?(full_path)
                raise StandardError.new(
                  "Unable to load EXPRESS index for `#{path}`, " \
                  "please define it at `:lutaml-express-index:` or specify " \
                  "the full path.",
                )
              end
              wrapper = load_lutaml_file(document, path)
              indexes[path] = {
                liquid_drop: wrapper.original_document.to_liquid(
                  selected_schemas: selected_schemas,
                  options: options,
                ),
              }
            end

            indexes[path]
          end
        end

        def read_config_yaml_file(document, file_path) # rubocop:disable Metrics/MethodLength
          return {} if file_path.nil?

          relative_file_path = Utils.relative_file_path(document, file_path)
          config_yaml = YAML.safe_load(
            File.read(relative_file_path, encoding: "UTF-8"),
          )

          options = {}
          if config_yaml["schemas"]
            unless config_yaml["schemas"].is_a?(Hash)
              raise StandardError.new(
                "[lutaml_express_liquid] attribute `config_yaml` must point " \
                "to a YAML file that has the `schema` key containing a hash.",
              )
            end

            options["selected_schemas"] = config_yaml["schemas"].keys
          end

          options
        end

        def get_original_document(wrapper)
          doc = wrapper
          return doc if doc.instance_of?(::Lutaml::XMI::RootDrop)

          doc.original_document
        end

        def render_liquid_template(document:, lines:, context_name:, # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
index_names:, options:, indexes:)
          config_yaml_path = options.delete("config_yaml")
          config = read_config_yaml_file(document, config_yaml_path)
          selected_schemas = config["selected_schemas"]

          all_items = gather_context_liquid_items(
            index_names: index_names,
            document: document,
            indexes: indexes,
            selected_schemas: selected_schemas,
            options: options.merge("document" => document),
          )

          all_items.map do |item|
            repo_drop = item[:liquid_drop]
            template = ::Liquid::Template.parse(lines.join("\n"))
            template.assigns[context_name] = repo_drop
            template.assigns["selected_schemas"] = selected_schemas
            template.render
          end.flatten
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[LutamlPreprocessor] Failed to parse LutaML block: #{e.message}",
            :error,
          )
          # [] # Return empty array to avoid breaking the document
          raise e
        end

        def parse_options(options_string)
          options_string
            .to_s
            .scan(/,\s*([^=]+?)=(\s*[^,]+)/)
            .map { |elem| elem.map(&:strip) }
            .to_h
        end
      end
    end
  end
end
