# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
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
        }x

        protected

        def lutaml_liquid?(line)
          line.match(EXPRESS_PREPROCESSOR_REGEX)
        end

        def load_lutaml_file(document, file_path, _options)
          full_path = Utils.relative_file_path(document, file_path)

          file = File.new(full_path, encoding: "UTF-8")
          if full_path.end_with?(".exp")
            ::Lutaml::Express::Parsers::Exp.parse(file)
          else
            ::Lutaml::Uml::Parsers::Dsl.parse(file)
          end
        end

        def index_type_name
          "EXPRESS"
        end

        def index_missing_message(path)
          "Unable to load EXPRESS index for `#{path}`, " \
            "please define it at `:lutaml-express-index:` or specify " \
            "the full path."
        end

        def update_repo(options, repo)
          adapter = ExpressRemarkAdapter.for(repo)
          unwrapped = adapter.unwrap
          return unwrapped unless unwrapped

          adapter.decorate_remarks(options)
          unwrapped
        end

        def template(lines)
          ::Liquid::Template.parse(
            lines.join("\n"),
            environment: create_liquid_environment,
          )
        end

        def reorder_schemas(repo_liquid, options)
          return repo_liquid.schemas unless options["selected_schemas"]

          options["selected_schemas"].filter_map do |schema_name|
            repo_liquid.schemas.find do |schema|
              schema.id == schema_name || schema.file_basename == schema_name
            end
          end
        end
      end
    end
  end
end
