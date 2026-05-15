# frozen_string_literal: true

require "lutaml/model"

module Metanorma
  module Plugin
    module Lutaml
      # Preprocessor for XSD (XML Schema Definition) files. Parses XSD via
      # lutaml-model's XSD parser and exposes the schema object to Liquid
      # templates.
      #
      # Two syntaxes are supported:
      #   Block:  [lutaml_xsd, path, context, options] .... ----
      #   Direct: lutaml_xsd::path[context, template, options]
      class LutamlXsdPreprocessor < BasePreprocessor
        CACHE = CacheStore.new
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
        }x

        XSD_DIRECT_REGEX = %r{
          ^\s*                         # Start of line
          lutaml_xsd::                 # Macro prefix
          (?<file_path>[^\[]+?)        # XSD file path
          \[                           # Opening bracket
          (?<context_name>[^,]+)       # Context name
          ,\s*                         # Comma separator
          (?<template>[^,\]]+)         # Template file path
          (?<options>,[^\]]+)?         # Optional options
          \]                           # Closing bracket
          \s*$                         # End of line
        }x

        def initialize(_config = {})
          super
        end

        protected

        def lutaml_liquid?(line)
          line.match(XSD_PREPROCESSOR_REGEX)
        end

        def load_lutaml_file(document, file_path, options)
          full_path = Utils.relative_file_path(document, file_path)
          location = xsd_location(full_path, options)
          cache_key = [full_path, location]

          CACHE.fetch_or_store(cache_key) do
            parse_xsd_file(full_path, location)
          end
        end

        def index_type_name
          "XSD"
        end

        def index_missing_message(path)
          "Unable to load XSD file for `#{path}`, please specify the full path."
        end

        def template(lines)
          # XSD templates use double-newline joins to produce Asciidoctor
          # paragraph breaks (single newlines are treated as continuation).
          ::Liquid::Template.parse(
            lines.join("\n\n"),
            environment: create_liquid_environment,
          )
        end

        private

        def process_text_blocks(document, input_lines, express_indexes)
          match = xsd_direct?(input_lines.peek)
          return handle_direct_block(document, input_lines, match) if match

          super
        end

        def xsd_direct?(line)
          line.match(XSD_DIRECT_REGEX)
        end

        def handle_direct_block(document, input_lines, match)
          input_lines.next # consume the matched line

          file_path = match[:file_path].strip
          context_name = match[:context_name].strip
          template_file = Utils.relative_file_path(document,
                                                   match[:template].strip)
          options = match[:options] ? parse_options(match[:options].strip) : {}

          schema = load_lutaml_file(document, file_path, options)
          schema_drop = update_repo(options, schema).to_liquid

          template_source = File.read(template_file, encoding: "UTF-8")
          tmpl = template([template_source])
          tmpl.registers[:file_system] = build_file_system(document, options)
          tmpl.assigns[context_name] = schema_drop

          tmpl.render.split("\n", -1)
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to parse LutaML block: #{e.message}",
            :error,
          )
          raise e
        end

        def parse_xsd_file(full_path, location)
          content = File.read(full_path, encoding: "UTF-8")
          ::Lutaml::Xml::Schema::Xsd.parse(content, location: location)
        end

        def xsd_location(full_path, options)
          options["location"] || File.dirname(full_path)
        end
      end
    end
  end
end
