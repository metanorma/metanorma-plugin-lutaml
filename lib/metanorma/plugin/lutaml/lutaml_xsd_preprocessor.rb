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

        def lutaml_xsd_block?(line)
          line.match(XSD_LIQUID_BLOCK_REGEX)
        end

        private

        def xsd_location(full_path, options)
          options["location"] || File.dirname(full_path)
        end

        def template_file(document, block_match)
          File.read(
            Utils.relative_file_path(
              document,
              block_match[:template]&.strip,
            ),
            encoding: "UTF-8",
          )
        end

        def process_direct_block(document, line, _express_indexes)
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
          lines = lines.join("\n\n") if lines.respond_to?(:join)
          ::Liquid::Template.parse(lines)
        end

        def assign_options_in_liquid(template, options = {})
          options.each do |opt_key, opt_value|
            value = if opt_key == "skip_rendering_of"
                      opt_value.to_s.strip.delete("'").split(";")
                    else
                      opt_value
                    end
            template.assigns[opt_key] = value
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

          parse_options(options_string.strip)
        end

        def gather_context_liquid_item(document, path, options = {})
          unless File.file?(Utils.relative_file_path(document, path))
            raise StandardError.new(index_missing_message(path))
          end
          load_lutaml_file(document, path, options).to_liquid
        end

        def file_system(options, document)
          include_paths = [
            Utils.relative_file_path(document, ""),
            template_path(document, options),
          ]
          ::Metanorma::Plugin::Lutaml::Liquid::LocalFileSystem.new(
            include_paths,
            FILE_SYSTEM_PATTERNS,
          )
        end

        def template_path(document, options)
          template_path = options&.dig("include_path")
          return Utils::LIQUID_INCLUDE_PATH unless template_path

          Utils.relative_file_path(
            document,
            template_path,
          )
        end
      end
    end
  end
end
