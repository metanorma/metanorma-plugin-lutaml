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

        def load_express_lutaml_file(document, file_path)
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

        def gather_context_liquid_items( # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
          index_names:, document:, indexes:, options: {}
        )
          index_names.map do |path| # rubocop:disable Metrics/BlockLength
            if indexes[path] && indexes[path][:model]
              repo = indexes[path][:model]
              repo = update_repo(options, repo)
              indexes[path][:liquid_drop] ||= repo.to_liquid
            else
              full_path = Utils.relative_file_path(document, path)
              unless File.file?(full_path)
                raise StandardError.new(
                  "Unable to load EXPRESS index for `#{path}`, " \
                  "please define it at `:lutaml-express-index:` or specify " \
                  "the full path.",
                )
              end
              repo = load_express_lutaml_file(document, path)
              repo = update_repo(options, repo)
              indexes[path] = {
                liquid_drop: repo.to_liquid,
              }
            end

            indexes[path]
          end
        end

        def update_repo(options, repo)
          # Unwrap repo if it's a cache
          repo = repo.content if repo.is_a? Expressir::Model::Cache

          # Process each schema
          repo.schemas.each do |schema|
            update_schema_selection(schema, options)
            options["relative_path_prefix"] =
              relative_path_prefix(options, schema)
            update_remarks(schema, options)
          end

          repo
        end

        def update_schema_selection(schema, options)
          return unless options["selected_schemas"]

          schema.selected = options["selected_schemas"].include?(schema.file_basename) ||
            options["selected_schemas"].include?(schema.id)
        end

        def update_remarks(model, options)
          model.remarks = decorate_remarks(options, model.remarks)
          model.remark_items&.each do |ri|
            ri.remarks = decorate_remarks(options, ri.remarks)
          end

          model.children.each do |child|
            if child.respond_to?(:remarks) && child.respond_to?(:remark_items)
              update_remarks(child, options)
            end
          end
        end

        def relative_path_prefix(options, model)
          return nil if options.nil? || options["document"].nil?

          document = options["document"]
          file_path = File.dirname(model.file)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || ".",
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def decorate_remarks(options, remarks)
          return [] unless remarks

          remarks.map do |remark|
            ::Expressir::Express::ExpressRemarksDecorator
              .call(remark, options)
          end
        end

        def read_config_yaml_file(document, file_path)
          return {} if file_path.nil?

          relative_file_path = Utils.relative_file_path(document, file_path)
          config_yaml = YAML.safe_load(
            File.read(relative_file_path, encoding: "UTF-8"),
          )

          return {} unless config_yaml["schemas"]

          unless config_yaml["schemas"].is_a?(Hash)
            raise StandardError.new(
              "[lutaml_express_liquid] attribute `config_yaml` must point " \
              "to a YAML file that has the `schemas` key containing a hash.",
            )
          end

          { "selected_schemas" => config_yaml["schemas"].keys }
        end

        def render_liquid_template(document:, lines:, context_name:, # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/ParameterLists
                      index_names:, options:, indexes:)
          # Process options and configuration
          options = process_options(document, options)

          # Get all context items in one go
          all_items = gather_context_liquid_items(
            index_names: index_names,
            document: document,
            indexes: indexes,
            options: options.merge("document" => document),
          )

          # Setup include paths for liquid templates
          include_paths = [Utils.relative_file_path(document, "")]
          options["include_path"]&.split(",")&.each do |path|
            # resolve include_path relative to the document
            include_paths.push(Utils.relative_file_path(document, path))
          end

          file_system = ::Metanorma::Plugin::Lutaml::Liquid::LocalFileSystem
            .new(include_paths, ["%s.liquid", "_%s.liquid", "_%s.adoc"])

          # Parse template once outside the loop
          template = ::Liquid::Template.parse(lines.join("\n"))
          template.registers[:file_system] = file_system

          # Render for each item
          all_items.map do |item|
            template.assigns[context_name] = item[:liquid_drop]
            template.render
          end.flatten
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[LutamlPreprocessor] Failed to parse LutaML block: #{e.message}",
            :error,
          )
          raise e
        end

        def process_options(document, options)
          # Process config file if specified
          if (config_yaml_path = options.delete("config_yaml"))
            config = read_config_yaml_file(document, config_yaml_path)
            if config["selected_schemas"]
              options["selected_schemas"] =
                config["selected_schemas"]
            end
          end
          options
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
