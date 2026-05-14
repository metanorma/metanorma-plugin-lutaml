# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"

module Metanorma
  module Plugin
    module Lutaml
      # Base preprocessor for LutaML format-specific preprocessors.
      #
      # Subclasses must implement:
      #   - #lutaml_liquid?(line) — match the macro header line
      #   - #load_lutaml_file(document, file_path, options)
      #     parse format-specific input
      #
      # Subclasses may override:
      #   - #index_type_name — human-readable format name for error messages
      #   - #update_repo(options, repo) — transform parsed repo before rendering
      #   - #template(lines) — parse Liquid template lines
      #   - #reorder_schemas(repo_liquid, options) — reorder/filter schemas
      class BasePreprocessor < ::Asciidoctor::Extensions::Preprocessor
        include Utils

        FILE_SYSTEM_PATTERNS = ["%s.liquid", "_%s.liquid", "_%s.adoc"].freeze

        def process(document, reader)
          input_lines = Asciidoctor::PreprocessorNoIfdefsReader
            .new(document, reader.lines).readlines.to_enum

          express_indexes = Utils.parse_document_express_indexes(
            document, input_lines
          )

          result_content = process_input_lines(
            document: document,
            input_lines: input_lines,
            express_indexes: express_indexes,
          )

          Asciidoctor::PreprocessorNoIfdefsReader.new(document, result_content)
        end

        protected

        def load_lutaml_file(_document, _file_path, _options)
          raise NotImplementedError,
                "#{self.class}#load_lutaml_file must be implemented"
        end

        def lutaml_liquid?(_line)
          raise NotImplementedError,
                "#{self.class}#lutaml_liquid? must be implemented"
        end

        def index_type_name
          raise NotImplementedError,
                "#{self.class}#index_type_name must be implemented"
        end

        def update_repo(_options, repo)
          repo
        end

        def template(lines)
          ::Liquid::Template.parse(lines.join("\n"))
        end

        def reorder_schemas(repo_liquid, _options)
          repo_liquid
        end

        def index_missing_message(path)
          "Unable to load #{index_type_name} file for `#{path}`, " \
            "please specify the full path."
        end

        def build_file_system(document, options)
          include_paths = [Utils.relative_file_path(document, "")]
          options["include_path"]&.split(",")&.each do |path|
            include_paths.push(Utils.relative_file_path(document, path))
          end
          ::Metanorma::Plugin::Lutaml::Liquid::LocalFileSystem
            .new(include_paths, FILE_SYSTEM_PATTERNS)
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

        def process_text_blocks(document, input_lines, express_indexes) # rubocop:disable Metrics/AbcSize
          line = input_lines.next
          block_header_match = lutaml_liquid?(line)

          return [line] unless block_header_match

          index_names = block_header_match[:index_names].split(";").map(&:strip)
          context_name = block_header_match[:context_name].strip
          options = (block_header_match[:options] &&
            parse_options(block_header_match[:options].to_s.strip)) || {}

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

        # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
        def gather_context_liquid_items(index_names:, document:,
                                        indexes:, options: {})
          index_names.map do |path|
            if indexes[path] && indexes[path][:model]
              repo = indexes[path][:model]
              repo = update_repo(options, repo)
              indexes[path][:liquid_drop] ||= repo.to_liquid
            else
              full_path = Utils.relative_file_path(document, path)
              unless File.file?(full_path)
                raise StandardError, index_missing_message(path)
              end

              repo = load_lutaml_file(document, path, options)
              repo = update_repo(options, repo)
              indexes[path] = { liquid_drop: repo.to_liquid }
            end

            indexes[path]
          end
        end
        # rubocop:enable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists

        def render_liquid_template(document:, lines:, context_name:, # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
                                   index_names:, options:, indexes:)
          options = process_options(document, options)

          all_items = gather_context_liquid_items(
            index_names: index_names, document: document, indexes: indexes,
            options: options.merge("document" => document)
          )

          parsed_template = template(lines)
          parsed_template.registers[:file_system] =
            build_file_system(document, options)

          all_items.map do |item|
            parsed_template.assigns[context_name] = item[:liquid_drop]
            parsed_template.assigns["ordered_schemas"] = reorder_schemas(
              item[:liquid_drop], options
            )
            parsed_template.assigns["schemas_order"] =
              options["selected_schemas"]
            parsed_template.render.split("\n", -1)
          end.flatten
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to parse LutaML block: #{e.message}",
            :error,
          )
          raise e
        end

        def process_options(document, options)
          if (config_yaml_path = options.delete("config_yaml"))
            config = read_config_yaml_file(document, config_yaml_path)
            if config["selected_schemas"]
              options["selected_schemas"] =
                config["selected_schemas"]
            end
          end
          options
        end

        def read_config_yaml_file(document, file_path) # rubocop:disable Metrics/MethodLength
          return {} unless file_path

          relative_file_path = Utils.relative_file_path(document, file_path)
          config_yaml = YAML.safe_load(
            File.read(relative_file_path, encoding: "UTF-8"),
          )

          return {} unless config_yaml["schemas"]

          unless config_yaml["schemas"].is_a?(Hash)
            raise StandardError,
                  "[lutaml_express_liquid] attribute `config_yaml` must " \
                  "point to a YAML file with the `schemas` key as a hash."
          end

          { "selected_schemas" => config_yaml["schemas"].keys }
        end

        def parse_options(options_string)
          options_string
            .to_s
            .scan(/,\s*([^=]+?)=(\s*[^,]+)/)
            .to_h { |elem| elem.map(&:strip) }
        end
      end
    end
  end
end
