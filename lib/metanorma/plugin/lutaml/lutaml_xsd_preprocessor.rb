# frozen_string_literal: true

require "lutaml/xml/parsers/xsd"

module Metanorma
  module Plugin
    module Lutaml
      # Preprocessor for XSD (XML Schema Definition) files. Parses XSD via
      # lutaml-model's XSD parser and exposes the schema object to Liquid
      # templates.
      #
      # Caching: parsed XSD results are cached at two levels:
      # - Class-level (@@xsd_cache) persists across document invocations
      # - Document-level (document.attributes["lutaml_xsd_cache"]) within a
      #   single document's processing
      class LutamlXsdPreprocessor < BasePreprocessor
        XSD_PREPROCESSOR_REGEX = %r{
          ^                            # Start of line
          \[                           # Opening bracket
          (?:\blutaml_xsd\b)           # lutaml_xsd
          ,                            # Comma separator
          (?<index_names>[^,]+)?       # Optional index names
          ,?                           # Optional comma
          (?<context_name>[^,]+)?      # Optional context name
          (?<options>,.*)?             # Optional options
          \]                           # Closing bracket
        }x

        def initialize(_config = {})
          super
          @@xsd_cache ||= {}
        end

        protected

        def lutaml_liquid?(line)
          line.match(XSD_PREPROCESSOR_REGEX)
        end

        def load_lutaml_file(document, file_path, options)
          full_path = Utils.relative_file_path(document, file_path)
          location = xsd_location(full_path, options)
          cache_key = [full_path, location]

          cached = document_cache_entry(document, cache_key)
          return cached if cached

          result = @@xsd_cache[cache_key] ||=
            parse_xsd_file(full_path, location)

          set_document_cache_entry(document, cache_key, result)
          result
        end

        def index_type_name
          "XSD"
        end

        def index_missing_message(path)
          "Unable to load XSD file for `#{path}`, please specify the full path."
        end

        def template(lines)
          # XSD templates use double-newline joins to produce Asciidoctor
          # paragraph breaks (single newlines are treated as continuation).
          ::Liquid::Template.parse(
            lines.join("\n\n"),
            environment: create_liquid_environment,
          )
        end

        private

        def parse_xsd_file(full_path, location)
          File.open(full_path, "r:UTF-8") do |file|
            ::Lutaml::Xml::Parsers::Xsd.parse(file, location: location)
          end
        end

        def xsd_location(full_path, options)
          options["location"] || File.dirname(full_path)
        end

        def document_cache_entry(document, cache_key)
          document.attributes["lutaml_xsd_cache"]&.[](cache_key)
        end

        def set_document_cache_entry(document, cache_key, result)
          document.attributes["lutaml_xsd_cache"] ||= {}
          document.attributes["lutaml_xsd_cache"][cache_key] = result
        end
      end
    end
  end
end
