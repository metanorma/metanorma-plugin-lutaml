# frozen_string_literal: true

require "metanorma/plugin/lutaml/express_remarks_decorator"

module Metanorma
  module Plugin
    module Lutaml
      # Preprocessor for EXPRESS schema formats (lutaml, lutaml_express,
      # lutaml_express_liquid). Parses EXPRESS files via the lutaml/expressir
      # gems, decorates remarks with relative path resolution, and renders
      # Liquid templates with the EXPRESS-specific Liquid environment.
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
          repo = repo.content if repo.is_a?(Expressir::Model::Cache)
          return repo unless repo.is_a?(Expressir::Model::Repository) ||
            repo.is_a?(Expressir::Model::ExpFile)

          repo.schemas.each do |schema|
            options["relative_path_prefix"] =
              relative_path_prefix(options, schema)
            update_remarks(schema, options)
          end

          repo
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

        private

        def update_remarks(model, options)
          model.remarks = decorate_remarks(options, model.remarks)
          decorate_remark_items(model, options)

          model.children.each do |child|
            next unless traversable_model_element?(child)

            update_remarks(child, options)
          end
        end

        def traversable_model_element?(child)
          child.is_a?(Expressir::Model::ModelElement) &&
            !child.is_a?(Expressir::Model::Declarations::RemarkItem)
        end

        def decorate_remark_items(model, options)
          return unless model.is_a?(Expressir::Model::HasRemarkItems)

          model.remark_items&.each do |ri|
            ri.remarks = decorate_remarks(options, ri.remarks)
          end
        end

        def relative_path_prefix(options, model)
          return if options.nil? || options["document"].nil?

          document = options["document"]
          file_path = File.dirname(model.file)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || ".",
          )
          document.path_resolver.system_path(file_path, docfile_directory)
        end

        def decorate_remarks(options, remarks)
          return [] unless remarks

          remarks.map do |remark|
            ExpressRemarksDecorator.call(remark, options)
          end
        end
      end
    end
  end
end
