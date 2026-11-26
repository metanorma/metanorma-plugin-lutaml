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
      # Options can be supplied as a JSON object:
      #
      #   [lutaml_data,models.lml,store,options={"include_path":"templates"}]
      #
      # Data from a registered provider (see DataProviders), with the
      # query's keyword arguments under `arguments`:
      #
      #   [lutaml_data,provider:ituob.edition,edition,
      #    options={"arguments":{"register":"e212-mnc","as_of":1170}}]
      #
      # (written on one line in a document)
      #
      # XML Schema definitions with XML instance documents — the schema
      # (XSD) derives the model classes in-memory and the instance document
      # parses against them (needs lutaml-model >= 0.8.176):
      #
      #   [lutaml_data,<schema.xsd>,<instance.xml>,<context>]
      #   ----
      #   {% for ft in context.CTS100FCFeatureCatalogue.s100_fc_feature_types %}
      #   {{ ft.name }}
      #   {% endfor %}
      #   ----
      class LutamlDataPreprocessor < BasePreprocessor
        DATA_FILE_EXTENSIONS = %w[.lml .yaml .yml .json .xml].freeze
        SCHEMA_EXTENSIONS = %w[.xsd].freeze
        DEFAULT_CONTEXT_NAME = "lutaml_data"
        PROVIDER_SOURCE = /\Aprovider:(?<name>[^.]+)\.(?<query>.+)\z/

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
            parse_header_logged(block_header_match)

          end_mark = input_lines.next
          lines = extract_block_lines(input_lines, end_mark)

          render_block(
            document: document,
            lines: lines,
            definition_file: definition_file,
            instance_file: instance_file,
            context_name: context_name,
            options: options,
          )
        end

        def parse_header_logged(match)
          parse_header(match)
        rescue StandardError => e
          log_block_failure(e)
          raise e
        end

        def parse_header(match)
          definition_file = match[:definition_file].strip
          options, segments = split_options(match[:rest])

          data_segments, name_segments = segments
            .reject(&:empty?).partition { |segment| data_file?(segment) }

          [definition_file, data_segments.last,
           name_segments.last || DEFAULT_CONTEXT_NAME, options]
        end

        def split_options(rest)
          object_options = rest.match(/,\s*options=(\{.*\})\s*,?\s*\z/)
          if object_options
            require "json"
            return [JSON.parse(object_options[1]),
                    rest[0...object_options.begin(0)].split(",").map(&:strip)]
          end

          split_inline_options(rest.split(",").map(&:strip))
        end

        def split_inline_options(segments)
          options_start = segments.index { |segment| segment.include?("=") }
          return [{}, segments] unless options_start

          options = parse_options(",#{segments[options_start..].join(',')}")
          [options, segments[0...options_start]]
        end

        def data_file?(segment)
          DATA_FILE_EXTENSIONS.include?(File.extname(segment).downcase)
        end

        def render_data_template(document:, lines:, # rubocop:disable Metrics/ParameterLists,Metrics/MethodLength
                                 definition_file:, instance_file:,
                                 context_name:, options:)
          definition_path, instances_path = resolve_data_paths(
            document, definition_file, instance_file
          )

          if SCHEMA_EXTENSIONS.include?(File.extname(definition_path).downcase)
            return render_schema_data_template(
              document: document, lines: lines,
              definition_path: definition_path,
              instances_path: instances_path,
              context_name: context_name, options: options,
            )
          end

          compiler = ::Lutaml::Lml::ModelCompiler.new
          compiler.compile(File.new(definition_path, encoding: "UTF-8"))
          instances = load_instances(instances_path, compiler)

          [render_liquid(lines, document, options, context_name, instances)]
        rescue StandardError => e
          log_block_failure(e)
          raise e
        end

        def render_block(document:, lines:, definition_file:, **rest)
          provider = definition_file.match(PROVIDER_SOURCE)
          unless provider
            return render_data_template(document: document, lines: lines,
                                        definition_file: definition_file,
                                        **rest)
          end

          render_provider_template(document, lines, provider,
                                   rest[:context_name], rest[:options])
        end

        def render_provider_template(document, lines, provider, # rubocop:disable Metrics/ParameterLists
                                     context_name, options)
          arguments, options = provider_arguments(options)
          data = DataProviders.query(provider[:name], provider[:query],
                                     arguments)
          parsed_template = template(lines)
          parsed_template.registers[:file_system] =
            build_file_system(document, options)
          [parsed_template.render(context_name => data)]
        rescue StandardError => e
          log_block_failure(e)
          raise e
        end

        def provider_arguments(options)
          arguments = options.fetch("arguments", {})
          unless arguments.is_a?(Hash)
            raise StandardError, "lutaml_data provider `arguments` must " \
                                 "be a JSON object"
          end

          [arguments, options.except("arguments")]
        end

        def log_block_failure(error)
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to parse LutaML data block: " \
            "#{error.message}",
            :error,
          )
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

        # Schema-driven reading: the XSD is the schema of record. Derive
        # the model classes in-memory (no generated files) and parse the
        # XML instance document against them; liquid sees the parsed
        # model keyed by its root class name, matching the LML flow.
        def render_schema_data_template(document:, lines:,
                                        definition_path:, instances_path:,
                                        context_name:, options:)
          # The XSD reader ships inside lutaml-model
          # (lib/lutaml/xml/schema/xsd.rb). Do NOT require the lutaml
          # gem's glue here: its released 0.11.x still vendors a
          # lutaml/model copy whose definitions would shadow the
          # canonical gem's (the vendoring is being removed on the
          # lutaml unvendor branch).
          require "lutaml/model"

          ::Lutaml::Xml::Schema::Xsd # ensure the schema reader is loaded

          schema_source = File.read(definition_path, encoding: "UTF-8")
          module_namespace = schema_module_namespace(definition_path)
          target_namespace = schema_target_namespace(definition_path,
                                                     schema_source)

          ::Lutaml::Model::Schema.from_xml(
            schema_source,
            load_classes: true,
            module_namespace: module_namespace,
            namespace: target_namespace,
            register_id: module_namespace,
            location: definition_path,
          )

          instances = load_xml_instances(instances_path, module_namespace)
          [render_liquid(lines, document, options, context_name, instances)]
        end

        def schema_module_namespace(definition_path)
          base = File.basename(definition_path, ".*")
          "LutamlXml#{base.gsub(/[^A-Za-z0-9]/, "_").split("_")
                          .reject(&:empty?).map(&:capitalize).join}"
        end

        def schema_target_namespace(definition_path, source)
          schema = ::Lutaml::Xml::Schema::Xsd.parse(
            source, location: definition_path
          )
          schema.target_namespace
        end

        def load_xml_instances(instances_path, module_namespace)
          require "moxml"

          instance_xml = File.read(instances_path, encoding: "UTF-8")
          root_name = Moxml.parse(instance_xml).root.name

          namespace = Object.const_get(module_namespace)
          root_class = namespace.constants.filter_map do |const|
            klass = namespace.const_get(const)
            next unless klass.is_a?(Class) && klass < ::Lutaml::Model::Serializable

            klass.mappings_for(:xml)&.root_element == root_name ? klass : nil
          end.first

          unless root_class
            raise StandardError,
                  "No derived model declares root element `#{root_name}` " \
                  "for `#{instances_path}`"
          end

          [[demodulize(root_class.name), root_class.from_xml(instance_xml)]]
        end

        def load_instances(path, compiler)
          case File.extname(path).downcase
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
