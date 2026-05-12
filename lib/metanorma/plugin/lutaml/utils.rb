require "expressir"
require "expressir/express/parser"
require "expressir/express/cache"
require "metanorma/plugin/lutaml/liquid/multiply_local_file_system"
require "metanorma/plugin/lutaml/liquid/custom_blocks/key_iterator"
require "metanorma/plugin/lutaml/liquid/custom_filters/html2adoc"
require "metanorma/plugin/lutaml/liquid/custom_filters/values"
require "metanorma/plugin/lutaml/liquid/custom_filters/replace_regex"
require "metanorma/plugin/lutaml/liquid/custom_filters/loadfile"
require "metanorma/plugin/lutaml/liquid/custom_filters/file_exist"

module Metanorma
  module Plugin
    module Lutaml
      # Helpers for lutaml macros
      module Utils
        # Prepended to Liquid::Context to preserve the original exception
        # that Liquid 5.x wraps as InternalError (discarding the cause).
        module LiquidErrorCapturer
          def handle_error(e, line_number = nil)
            if e.is_a?(::Liquid::Error)
              super
            else
              ie = ::Liquid::InternalError.new("internal")
              ie.set_backtrace(e.backtrace)
              ie.define_singleton_method(:original_error) { e }
              ie.template_name ||= template_name
              ie.line_number ||= line_number
              errors.push(ie)
              exception_renderer.call(ie).to_s
            end
          end
        end

        LUTAML_EXP_IDX_TAG = %r{
          ^:lutaml-express-index: # Start of the pattern
          (?<index_name>.+?)      # Capture index name
          ;                       # Separator
          (?<index_path>.+?)      # Capture index path
          ;?                      # Optional separator
          (?<cache_group>         # Optional cache group
            \s*cache=             # Cache prefix
            (?<cache_path>.+)     # Capture cache path
          )?                      # End of optional group
          $                       # End of the pattern
        }x

        module_function

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || ".",
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def render_liquid_string( # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          contexts:, document:,
          template_string: nil, include_path: nil, template_path: nil
        )
          unless ::Liquid::Context <= LiquidErrorCapturer
            ::Liquid::Context.prepend(LiquidErrorCapturer)
          end

          # Allow includes for the template
          include_paths = [
            Utils.relative_file_path(document, ""),
            include_path, template_path
          ].compact

          if template_path
            template_string = File.read(template_path)
          end

          liquid_template = ::Liquid::Template
            .parse(template_string, environment: create_liquid_environment)
          liquid_template.registers[:file_system] =
            ::Metanorma::Plugin::Lutaml::Liquid::LocalFileSystem
              .new(include_paths, ["%s.liquid", "_%s.liquid", "_%s.adoc"])
          rendered_string = liquid_template
            .render(contexts,
                    strict_variables: false,
                    error_mode: :warn)

          [rendered_string, liquid_template.errors]
        end

        def create_liquid_environment
          ::Liquid::Environment.new.tap do |liquid_env|
            liquid_env.register_tag(
              "keyiterator",
              ::Metanorma::Plugin::Lutaml::Liquid::CustomBlocks::KeyIterator,
            )
            liquid_env.register_filter(
              ::Metanorma::Plugin::Lutaml::Liquid::CustomFilters,
            )
          end
        end

        def processed_lines(document, input_lines)
          result = []
          loop do
            result.push(*process_text_blocks(document, input_lines))
          end
          result
        end

        @seen_liquid_errors = Set.new

        def notify_render_errors(_document, errors)
          return if errors.empty?

          grouped = errors.group_by { |e| error_signature(e) }
          grouped.each do |sig, errs|
            total = errs.size
            already_seen = @seen_liquid_errors.include?(sig)
            @seen_liquid_errors << sig
            next if already_seen

            err = errs.first
            backtrace = err.backtrace&.first(3)&.join("\n").to_s
            count_label = total > 1 ? " (#{total}x)" : ""
            parts = ["[metanorma-plugin-lutaml] Liquid render error#{count_label}:"]
            parts << "  #{err.class}: #{err.message}"
            if err.respond_to?(:original_error) && err.original_error
              orig = err.original_error
              parts << "  Caused by: #{orig.class}: #{orig.message}"
            end
            parts << backtrace unless backtrace.empty?
            ::Metanorma::Util.log(parts.join("\n"), :error)
          end
        end

        def error_signature(err)
          orig = err.respond_to?(:original_error) && err.original_error
          base = "#{err.class}: #{err.message}"
          orig ? "#{base} (#{orig.class}: #{orig.message})" : base
        end

        def load_express_repositories( # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          path:, cache_path:, document:, force_read: false
        )
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
        def load_express_from_index(_document, path) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          yaml_content = YAML.safe_load_file(path)
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

        def parse_document_express_indexes(document, input_lines) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
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
              raise StandardError.new("No name and path set in " \
                                      "`:lutaml-express-index:` attribute.")
            end

            lutaml_expressir_model = load_express_repositories(
              path: path,
              cache_path: cache,
              document: document,
            )

            if lutaml_expressir_model
              express_indexes[name] = { model: lutaml_expressir_model }
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
