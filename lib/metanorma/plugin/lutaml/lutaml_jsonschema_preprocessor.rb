# frozen_string_literal: true

require "lutaml/jsonschema"

module Metanorma
  module Plugin
    module Lutaml
      # Preprocessor for JSON Schema files. Parses the schema through
      # lutaml-jsonschema and renders documentation from its annotations
      # (title, description, constraints).
      #
      # Three forms are supported:
      #   Default: lutaml_jsonschema::path[]
      #            renders the built-in reference (properties tables and
      #            definitions) as embeddable AsciiDoc
      #   Direct:  lutaml_jsonschema::path[context, template, options]
      #            renders a Liquid template file with the schema as context
      #   Block:   [lutaml_jsonschema, path, context, options] .... ----
      #            renders the inline Liquid template with the schema
      class LutamlJsonschemaPreprocessor < BasePreprocessor
        CACHE = CacheStore.new

        JSONSCHEMA_PREPROCESSOR_REGEX = %r{
          ^                            # Start of line
          \[                           # Opening bracket
          (?:\blutaml_jsonschema\b)    # lutaml_jsonschema
          ,                            # Comma separator
          (?<index_names>[^,]+)?       # Schema path(s), ";"-separated
          ,?                           # Optional comma
          (?<context_name>[^,]+)?      # Optional context name
          (?<options>,.*)?             # Optional options
          \]                           # Closing bracket
        }x

        JSONSCHEMA_DIRECT_REGEX = %r{
          ^\s*                         # Start of line
          lutaml_jsonschema::          # Macro prefix
          (?<file_path>[^\[]+?)        # Schema file path
          \[                           # Opening bracket
          (?<attributes>[^\]]*)        # Optional context, template, options
          \]                           # Closing bracket
          \s*$                         # End of line
        }x

        protected

        def lutaml_liquid?(line)
          line.match(JSONSCHEMA_PREPROCESSOR_REGEX)
        end

        def load_lutaml_file(document, file_path, _options)
          load_schema_set(document, file_path).schemas.values.first
        end

        def index_type_name
          "JSON Schema"
        end

        private

        def process_text_blocks(document, input_lines, express_indexes)
          match = input_lines.peek.match(JSONSCHEMA_DIRECT_REGEX)
          return handle_direct_block(document, input_lines, match) if match

          super
        end

        def handle_direct_block(document, input_lines, match)
          input_lines.next # consume the matched line
          file_path = match[:file_path].strip
          render_direct(document, file_path, match[:attributes])
            .split("\n", -1)
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to render JSON Schema " \
            "`#{file_path}`: #{e.message}", :error
          )
          raise e
        end

        def render_direct(document, file_path, attributes)
          context_name, template_path, options =
            parse_direct_attributes(attributes)
          return render_default(document, file_path) unless context_name

          render_template_file(document, file_path, context_name,
                               template_path, options)
        end

        def parse_direct_attributes(attributes)
          named, positional = split_attributes(attributes)
          if positional.size == 1
            raise StandardError,
                  "lutaml_jsonschema:: needs both a context name and a " \
                  "template path, or neither (for the default reference)"
          end

          options = named.to_h { |attr| attr.split("=", 2).map(&:strip) }
          [positional[0], positional[1], options]
        end

        def split_attributes(attributes)
          attributes.to_s.split(",").map(&:strip).reject(&:empty?)
            .partition { |attr| attr.include?("=") }
        end

        def render_default(document, file_path)
          ::Lutaml::Jsonschema::Exports::Adoc
            .new(load_schema_set(document, file_path), embeddable: true)
            .render
        end

        def render_template_file(document, file_path, context_name,
                                 template_path, options)
          schema = load_lutaml_file(document, file_path, options)
          template_file = Utils.relative_file_path(document, template_path)
          tmpl = template([File.read(template_file, encoding: "UTF-8")])
          tmpl.registers[:file_system] = build_file_system(document, options)
          tmpl.assigns[context_name] = schema.to_liquid
          tmpl.render
        end

        def load_schema_set(document, file_path)
          full_path = Utils.relative_file_path(document, file_path)
          unless File.file?(full_path)
            raise StandardError, index_missing_message(file_path)
          end

          CACHE.fetch_or_store([full_path, File.mtime(full_path)]) do
            ::Lutaml::Jsonschema::SchemaSet.load_from_files(full_path)
          end
        end
      end
    end
  end
end
