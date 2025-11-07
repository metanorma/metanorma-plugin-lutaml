# frozen_string_literal: true

require_relative "liquid/custom_filters/xsd/to_xml_representation"

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
        XSD_LIQUID_BLOCK_REGEX = %r{
          ^                            # Start of line
          (?:\blutaml_xsd\b)::         # lutaml_xsd
          (?<index_name>[^\[]+)        # Index names
          \[                           # Opening bracket
            (?<context_name>[^,]+)     # Context name
            ,                          # Comma separator
            (?<template>[^,]+)         # Template file
            (?<options>,.*)?           # Optional options
          \]
        }x.freeze

        def process_text_blocks(document, input_lines, express_indexes)
          if lutaml_xsd_block?(input_lines.peek)
            process_direct_block(document, input_lines.next, express_indexes)
          else
            super
          end
        end

        protected

        def lutaml_liquid?(line)
          line.match(XSD_PREPROCESSOR_REGEX)
        end

        def lutaml_xsd_block?(line)
          line.match(XSD_LIQUID_BLOCK_REGEX)
        end

        private

        def template_file(document, options)
          File.new(
            Utils.relative_file_path(
              document,
              options[:template]&.strip,
            ),
            encoding: "UTF-8",
          ).read
        end

        def process_direct_block(document, line, express_indexes)
          block_match     = lutaml_xsd_block?(line)
          index_name      = block_match[:index_name].strip
          context_name    = block_match[:context_name].strip
          options         = options_hash(block_match[:options])
          liquid_template = template(template_file(document, block_match))

          liquid_template.registers[:file_system] = file_system(options, document)
          liquid_template.assigns[context_name] = gather_context_liquid_item(
            document,
            index_name,
            options,
          )
          assign_options_in_liquid(liquid_template, options)
          [liquid_template.render]
        end

        def template(lines)
          lines = lines.join("\n") if lines.respond_to?(:join)
          ::Liquid::Template.parse(lines, environment: liquid_environment)
        end

        def liquid_environment
          ::Liquid::Environment.new.tap do |env|
            env.register_filter(Liquid::Xsd::CustomFilters)
          end
        end

        def assign_options_in_liquid(template, options = {})
          options.each do |opt_key, opt_value|
            opt_value = if opt_key == "skip_rendering_of"
                          opt_value.to_s.strip.delete("'").split(";")
                        end
            template.assigns[opt_key] = opt_value
          end
        end

        def reorder_schemas(repo_liquid, _options)
          repo_liquid
        end

        def update_repo(_options, repo)
          repo
        end

        def options_hash(options_string)
          return {} if options_string.nil?

          parse_options_string(options_string.strip)
        end

        def gather_context_liquid_item(document, path, options = {})
          unless File.file?(Utils.relative_file_path(document, path))
            raise StandardError.new(
              "Unable to load EXPRESS index for `#{path}`, " \
              "please define it at `:lutaml-express-index:` or specify " \
              "the full path.",
            )
          end
          load_lutaml_file(document, path, options).to_liquid
        end

        def file_system(options, document)
          include_paths = [
            Utils.relative_file_path(document, ""),
            template_path(document, options),
          ]
          Liquid::LocalFileSystem.new(include_paths, FILE_SYSTEM_PATTERNS)
        end

        def template_path(document, options)
          template_path = options&.dig("templates_dir")
          return Utils::LIQUID_INCLUDE_PATH unless template_path

          Utils.relative_file_path(
            document,
            template_path,
          )
        end

        def parse_options_string(str)
          str
            .to_s
            .scan(/,\s*([^=]+?)=(\s*[^,]+)/)
            .to_h
        end
      end
    end
  end
end
