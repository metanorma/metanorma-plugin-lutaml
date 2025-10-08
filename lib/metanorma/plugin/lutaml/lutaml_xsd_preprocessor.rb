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
          (?<index_names>[^\[]+)       # Index names
          \[                           # Opening bracket
            (?<context_name>[^,]+)     # Context name
            ,                          # Comma separator
            (?<template>[^,]+)         # Template file
            (?<options>,.*)?           # Optional options
          \]
        }x.freeze

        def process_text_blocks(document, input_lines, express_indexes)
          return super unless liquid_block?(input_lines.peek)

          process_direct_block(
            document,
            input_lines.next,
            express_indexes,
          )
        end

        protected

        def lutaml_liquid?(line)
          line.match(XSD_PREPROCESSOR_REGEX)
        end

        def liquid_block?(line)
          line.match?(XSD_LIQUID_BLOCK_REGEX)
        end

        private

        def process_direct_block(document, line, express_indexes)
          block_header_match = line.match(XSD_LIQUID_BLOCK_REGEX)
          context_name = block_header_match[:context_name].strip
          index_name = block_header_match[:index_names].strip
          options = options_hash(block_header_match[:options])
          template_file = File.new(
            Utils.relative_file_path(document, block_header_match[:template]&.strip),
            encoding: "UTF-8",
          )
          liquid_template = template(template_file.read)
          liquid_template.registers[:file_system] = file_system([Utils.relative_file_path(document, "")])
          liquid_template.assigns[context_name] = gather_context_liquid_item(document, index_name, options)
          [liquid_template.render]
        end

        def template(lines)
          lines = lines.join("\n") if lines.respond_to?(:join)
          ::Liquid::Template.parse(lines, environment: liquid_environment)
        end

        def liquid_environment
          ::Liquid::Environment.new.tap do |env|
            env.register_filter(
              ::Metanorma::Plugin::Lutaml::Liquid::Xsd::CustomFilters,
            )
          end
        end

        def assign_options_in_liquid(template, options = {})
          options.each { |opt_key, opt_value| template.assigns[opt_key] = opt_value }
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

        def parse_options_string(str)
          str
            .to_s
            .scan(/,\s*([^=]+?)=(\s*[^,]+)/)
            .group_by(&:first)
            .transform_values { |items| items.map(&:last) }
        end
      end
    end
  end
end
