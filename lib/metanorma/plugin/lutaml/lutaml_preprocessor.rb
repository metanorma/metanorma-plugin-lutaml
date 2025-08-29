# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # Class for processing Lutaml files
      class LutamlPreprocessor < BasePreprocessor
        EXPRESS_PREPROCESSOR_REGEX = %r{
          ^                            # Start of line
          \[                           # Opening bracket
          (?:\blutaml\b|               # Match lutaml or
            \blutaml_express\b|        # lutaml_express or
            \blutaml_express_liquid\b) # lutaml_express_liquid
          ,                            # Comma separator
          (?<index_names>[^,]+)?       # Optional index names
          ,?                           # Optional comma
          (?<context_name>[^,]+)?      # Optional context name
          (?<options>,.*)?             # Optional options
          \]                           # Closing bracket
        }x.freeze

        protected

        def lutaml_liquid?(line)
          line.match(EXPRESS_PREPROCESSOR_REGEX)
        end

        def assign_options_in_liquid(template, _options = {})
          template
        end
      end
    end
  end
end
