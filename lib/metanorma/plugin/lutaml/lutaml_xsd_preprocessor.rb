# frozen_string_literal: true

require_relative "liquid/custom_filters/xsd/used_by"

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

        private

        def template(lines)
          ::Liquid::Template.parse(lines.join("\n"), environment: liquid_environment)
        end

        def liquid_environment
          ::Liquid::Environment.new.tap do |env|
            env.register_filter(
              ::Metanorma::Plugin::Lutaml::Liquid::Xsd::CustomFilters,
            )
          end
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
