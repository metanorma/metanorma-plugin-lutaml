require "expressir/express_exp/cache"

module Metanorma
  module Plugin
    module Lutaml
      # Helpers for lutaml macroses
      module Utils
        LUTAML_EXP_IDX_TAG = /^:lutaml-express-index:(?<index_name>.+?);(?<index_path>.+?);?(\s*cache=(?<cache_path>.+))?$/.freeze

        module_function

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || "."
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def render_liquid_string(template_string:, context_items:,
                                 context_name:)
          liquid_template = Liquid::Template.parse(template_string)
          rendered_string = liquid_template
            .render(context_name => context_items,
                    strict_variables: true,
                    error_mode: :warn)
          [rendered_string, liquid_template.errors]
        end

        def notify_render_errors(document, errors)
          errors.each do |error_obj|
            document
              .logger
              .warn("Liquid render error: #{error_obj.message}")
          end
        end

        def process_express_index(path, cache_path, document, force_read = false)
          cache_full_path = Utils.relative_file_path(document, cache_path) if cache_path
          if !force_read && cache_full_path && File.file?(cache_full_path)
            return express_from_cache(cache_full_path).first
          end

          full_path = Utils.relative_file_path(document, path)
          wrapper = express_from_path(document, full_path).first
          express_write_cache(cache_full_path, wrapper.original_document) if cache_full_path && !File.file?(cache_full_path)
          wrapper
        rescue StandardError => e
          document.logger.warn("Failed to load #{full_path}: #{e.message}")
          nil
        rescue Expressir::ExpressExp::CacheLoadError
          process_express_index(path, cache_path, document, true)
        end

        def express_from_cache(path)
          ::Lutaml::Parser
            .parse(File.new(path), ::Lutaml::Parser::EXPRESS_CACHE_PARSE_TYPE)
        end

        def express_write_cache(path, repository)
          Expressir::ExpressExp::Cache.to_file(path, repository)
        end

        def express_from_path(document, path)
          if File.directory?(path)
            return express_from_folder(path)
          end

          express_from_index(document, path)
        end

        def express_from_folder(folder)
          files = Dir["#{folder}/*.exp"].map { |nested_path| File.new(nested_path, encoding: "UTF-8") }
          ::Lutaml::Parser.parse(files)
        end

        def express_decorate_wrapper(wrapper, document)
          wrapper
            .to_liquid
            .map do |j|
              j.merge('relative_path_prefix' => Utils.relative_file_path(document, File.dirname(j['file'])))
            end
        end

        def express_from_index(document, path)
          schemas_paths = YAML
                            .safe_load(File.read(path))
                            .fetch('schemas')
                            .map {|(_, schema_values)| schema_values['path'] }
          files_to_load = schemas_paths.map do |path|
            File.new(Utils.relative_file_path(document, path), encoding: "UTF-8")
          end
          ::Lutaml::Parser.parse(files_to_load)
        end

        def parse_document_express_indexes(document, input_lines)
          express_indexes = {}
          loop do
            line = input_lines.next
            break if line.length.zero?

            match = line.match(LUTAML_EXP_IDX_TAG)
            if match
              name = match[:index_name]
              path = match[:index_path]
              cache = match[:cache_path]
              repositories = process_express_index(path.strip, cache, document)
              if repositories
                express_indexes[name.strip] = express_decorate_wrapper(repositories, document)
              end
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
