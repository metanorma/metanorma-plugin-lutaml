# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
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

        private

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
