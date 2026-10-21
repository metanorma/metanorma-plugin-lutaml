# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # Renders LutaML data instances through a Liquid template.
      #
      # Data definitions and instances in separate files:
      #
      #   [lutaml_data,<definitions.lml>,<instances.lml|yaml|json>,<context>]
      #   ----
      #   {% for check in context.S158Checks.checks %}
      #   {{ check.dev_id }}
      #   {% endfor %}
      #   ----
      #
      # Data definitions and instances in the same file:
      #
      #   [lutaml_data,<definitions.lml>,<context>]
      #
      class LutamlDataPreprocessor < BasePreprocessor
        DATA_FILE_EXTENSIONS = %w[.lml .yaml .yml .json].freeze
        DEFAULT_CONTEXT_NAME = "lutaml_data"

        DATA_BLOCK_REGEX = %r{
          ^
          \[
          \blutaml_data\b
          ,(?<definition_file>[^,\[\]]+)
          (?<rest>.*)
          \]
        }x

        protected

        def lutaml_liquid?(line)
          line.match(DATA_BLOCK_REGEX)
        end

        def index_type_name
          "LutaML data"
        end

        def load_lutaml_file(_document, file_path, _options)
          ::Lutaml::Lml.parse_document(File.new(file_path, encoding: "UTF-8"))
        end

        private

        def process_text_blocks(document, input_lines, _express_indexes)
          line = input_lines.next
          block_header_match = lutaml_liquid?(line)
          return [line] unless block_header_match

          definition_file, instance_file, context_name, options =
            parse_header(block_header_match)

          end_mark = input_lines.next
          lines = extract_block_lines(input_lines, end_mark)

          render_data_template(
            document: document,
            lines: lines,
            definition_file: definition_file,
            instance_file: instance_file,
            context_name: context_name,
            options: options,
          )
        end

        def parse_header(match)
          definition_file = match[:definition_file].strip
          segments = match[:rest].split(",").map(&:strip)
          options, segments = split_options(segments)

          data_segments, name_segments = segments
            .reject(&:empty?).partition { |segment| data_file?(segment) }

          [definition_file, data_segments.last,
           name_segments.last || DEFAULT_CONTEXT_NAME, options]
        end

        def split_options(segments)
          options_start = segments.index { |segment| segment.include?("=") }
          return [{}, segments] unless options_start

          options = parse_options(",#{segments[options_start..].join(',')}")
          [options, segments[0...options_start]]
        end

        def data_file?(segment)
          DATA_FILE_EXTENSIONS.include?(File.extname(segment))
        end

        def render_data_template(document:, lines:, # rubocop:disable Metrics/ParameterLists
                                 definition_file:, instance_file:,
                                 context_name:, options:)
          definition_path, instances_path = resolve_data_paths(
            document, definition_file, instance_file
          )

          compiler = ::Lutaml::Lml::ModelCompiler.new
          compiler.compile(File.new(definition_path, encoding: "UTF-8"))
          instances = load_instances(instances_path, compiler)

          [render_liquid(lines, document, options, context_name, instances)]
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to parse LutaML data block: " \
            "#{e.message}",
            :error,
          )
          raise e
        end

        def render_liquid(lines, document, options, context_name, instances)
          parsed_template = template(lines)
          parsed_template.registers[:file_system] =
            build_file_system(document, options)
          parsed_template.render(context_name => deep_stringify(instances.to_h))
        end

        # Liquid resolves variable lookups by string keys; the compiled
        # LML models hash with symbols
        def deep_stringify(value)
          case value
          when Hash
            value.transform_keys(&:to_s)
                 .transform_values { |v| deep_stringify(v) }
          when Array
            value.map { |v| deep_stringify(v) }
          else
            value
          end
        end

        def resolve_data_paths(document, definition_file, instance_file)
          definition_path = Utils.relative_file_path(document, definition_file)
          unless File.file?(definition_path)
            raise StandardError, index_missing_message(definition_file)
          end

          instances_path = instance_file &&
            Utils.relative_file_path(document, instance_file)
          if instances_path && !File.file?(instances_path)
            raise StandardError, index_missing_message(instance_file)
          end

          [definition_path, instances_path || definition_path]
        end

        def load_instances(path, compiler)
          case File.extname(path)
          when ".lml" then load_lml_instances(path, compiler)
          when ".json" then load_structured_instances(path, compiler,
                                                      :parse_json_data)
          else load_structured_instances(path, compiler, :parse_yaml_data)
          end
        end

        def load_lml_instances(path, compiler)
          doc = load_lutaml_file(nil, path, {})
          root = doc.instance
          return [] unless root

          [[root.type.to_s, compiler.hydrate(doc)]]
        rescue StandardError => e
          raise StandardError, "Failed to parse LutaML instances in " \
                               "`#{path}`: #{e.message}"
        end

        def load_structured_instances(path, compiler, parser)
          data = send(parser, path)
          entries = data.is_a?(Array) ? data : [data]
          entries.map { |entry| build_structured_entry(path, compiler, entry) }
        rescue StandardError => e
          raise e if e.message.start_with?("Instance", "Unknown type")

          raise StandardError, "Failed to load data instances in " \
                               "`#{path}`: #{e.message}"
        end

        def build_structured_entry(path, compiler, entry)
          type = entry.delete("type")
          unless type
            raise StandardError, "Instance in `#{path}` is missing the " \
                                 "`type` key"
          end

          klass = compiler.compiled_classes[demodulize(type)]
          unless klass
            raise StandardError,
                  "Unknown type `#{type}` in `#{path}`"
          end

          [demodulize(type), klass.from_hash(entry)]
        end

        def parse_yaml_data(path)
          require "yaml"
          YAML.safe_load(File.read(path, encoding: "UTF-8"))
        end

        def parse_json_data(path)
          require "json"
          JSON.parse(File.read(path, encoding: "UTF-8"))
        end

        def demodulize(name)
          name.to_s.split("::").last
        end
      end
    end
  end
end
