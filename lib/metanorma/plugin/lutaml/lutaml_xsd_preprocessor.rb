# frozen_string_literal: true

require "lutaml/xml/parsers/xsd"

module Metanorma
  module Plugin
    module Lutaml
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
        }x.freeze

        protected

        def lutaml_liquid?(line)
          line.match(XSD_PREPROCESSOR_REGEX)
        end

        def load_lutaml_file(document, file_path, options)
          full_path = Utils.relative_file_path(document, file_path)

          File.open(full_path, "r:UTF-8") do |file|
            ::Lutaml::Xml::Parsers::Xsd.parse(
              file,
              location: xsd_location(full_path, options),
            )
          end
        end

        def index_type_name
          "XSD"
        end

        def index_missing_message(path)
          "Unable to load XSD file for `#{path}`, please specify the full path."
        end

        private

        def xsd_location(full_path, options)
          options["location"] || File.dirname(full_path)
        end

        def template(lines)
          ::Liquid::Template.parse(
            lines.join("\n\n"),
            environment: create_liquid_environment,
          )
        end

        def reorder_schemas(repo_liquid, _options)
          repo_liquid
        end

        def update_repo(_options, repo)
          repo
        end
      end
    end
  end
end
