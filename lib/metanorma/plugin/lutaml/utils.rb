require "expressir"
require "expressir/express/parser"
require "expressir/express/cache"
require "metanorma/plugin/lutaml/liquid/custom_filters"
require "metanorma/plugin/lutaml/liquid/multiply_local_file_system"

liquid_klass = if Object.const_defined?("Liquid::Environment")
                 Object.const_get("Liquid::Environment").default
               else
                 Object.const_get("Liquid::Template")
               end
liquid_klass.register_filter(Metanorma::Plugin::Lutaml::Liquid::CustomFilters)

module Metanorma
  module Plugin
    module Lutaml
      # Helpers for lutaml macros
      module Utils
        LUTAML_EXP_IDX_TAG = /^:lutaml-express-index:(?<index_name>.+?);(?<index_path>.+?);?(\s*cache=(?<cache_path>.+))?$/.freeze

        module_function

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || ".",
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def render_liquid_string(template_string:, context_items:,
                                 context_name:, document:, include_path: nil)
          liquid_template = ::Liquid::Template.parse(template_string)

          # Allow includes for the template
          include_paths = [
            Utils.relative_file_path(document, ""),
            include_path,
          ].compact

          liquid_template.registers[:file_system] =
            ::Metanorma::Plugin::Lutaml::Liquid::LocalFileSystem
              .new(include_paths, ["%s.liquid", "_%s.liquid", "_%s.adoc"])

          rendered_string = liquid_template
            .render(context_name => context_items,
                    strict_variables: true,
                    error_mode: :warn)

          [rendered_string, liquid_template.errors]
        end

        def notify_render_errors(document, errors)
          errors.each do |error_obj|
            ::Metanorma::Util.log(
              "[metanorma-plugin-lutaml] Liquid render error: " \
              "#{error_obj.message}",
              :error,
            )
          end
        end

        def load_express_repositories(path:, cache_path:, document:,
force_read: false)
          cache_full_path = cache_path &&
            Utils.relative_file_path(document, cache_path)

          # If there is cache and "force read" not set.
          if !force_read && cache_full_path && File.file?(cache_full_path)
            return load_express_repo_from_cache(cache_full_path)
          end

          # If there is no cache or "force read" is set.
          full_path = Utils.relative_file_path(document, path)
          lutaml_doc = load_express_repo_from_path(document, full_path)

          if cache_full_path && !File.file?(cache_full_path)
            save_express_repo_to_cache(
              cache_full_path,
              lutaml_doc,
              document,
            )
          end

          lutaml_doc
        rescue Expressir::Error
          FileUtils.rm_rf(cache_full_path)

          load_express_repositories(
            path: path,
            cache_path: cache_path,
            document: document,
            force_read: true,
          )
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[metanorma-plugin-lutaml] Failed to load " \
            "#{full_path}: #{e.message}",
            :error,
          )
          raise e
          # nil
        end

        def load_express_repo_from_cache(path)
          ::Lutaml::Parser
            .parse(File.new(path), ::Lutaml::Parser::EXPRESS_CACHE_PARSE_TYPE)
        end

        def save_express_repo_to_cache(path, repository, document)
          root_path = Pathname.new(relative_file_path(document, ""))
          Expressir::Express::Cache
            .to_file(path,
                     repository,
                     root_path: root_path)
        end

        def load_express_repo_from_path(document, path)
          return load_express_from_folder(path) if File.directory?(path)

          load_express_from_index(document, path)
        end

        def load_express_from_folder(folder)
          files = Dir["#{folder}/*.exp"].map do |nested_path|
            File.new(nested_path, encoding: "UTF-8")
          end
          ::Lutaml::Parser.parse(files)
        end

        # TODO: Refactor this using Suma::SchemaConfig
        def load_express_from_index(_document, path)
          yaml_content = YAML.safe_load(File.read(path))
          schema_yaml_base_path = Pathname.new(File.dirname(path))

          # If there is a global root path set, all subsequent paths are
          # relative to it.
          if yaml_content["path"]
            root_schema_path = Pathname.new(yaml_content["path"])
            schema_yaml_base_path = schema_yaml_base_path + root_schema_path
          end

          files_to_load = yaml_content["schemas"].map do |key, value|
            # If there is no path: set for a schema, we assume it uses the
            # schema name as the #{filename}.exp.
            schema_path = Pathname.new(value["path"] || "#{key}.exp")

            real_schema_path = schema_yaml_base_path + schema_path
            File.new(real_schema_path.cleanpath.to_s, encoding: "UTF-8")
          end

          ::Lutaml::Parser.parse(files_to_load)
        end

        def parse_document_express_indexes(document, input_lines)
          express_indexes = {}
          loop do
            line = input_lines.next

            # Finished parsing document attributes
            break if line.empty?

            match = line.match(LUTAML_EXP_IDX_TAG)
            next unless match

            name = match[:index_name]&.strip
            path = match[:index_path]&.strip
            cache = match[:cache_path]&.strip

            unless name && path
              raise StandardError.new("No name and path set in `:lutaml-express-index:` attribute.")
            end

            lutaml_expressir_model = load_express_repositories(
              path: path,
              cache_path: cache,
              document: document,
            )

            if lutaml_expressir_model
              express_indexes[name] = {
                model: lutaml_expressir_model,
              }
            end
          end

          express_indexes
        rescue StopIteration
          express_indexes
        ensure
          input_lines.rewind
        end
      end
    end
  end
end
