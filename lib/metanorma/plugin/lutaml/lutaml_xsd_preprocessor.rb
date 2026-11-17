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
      #
      # The bundled default templates (liquid_templates/xsd) are always on
      # the template search path, after the document directory and any
      # `include_path`, so documents can override single partials. The
      # direct syntax renders the default `xsd_schema` template when no
      # template is given.
      class LutamlXsdPreprocessor < BasePreprocessor
        CACHE = CacheStore.new
        DEFAULT_TEMPLATES_DIR = File.expand_path(
          "liquid_templates/xsd", __dir__
        ).freeze
        DEFAULT_TEMPLATE = "xsd_schema"
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
          (?<context_name>[^,\]]+)     # Context name
          (?:,\s*                      # Comma separator
          (?<template>[^,\]=]+?))?     # Optional template file path
          \s*                          # Optional whitespace
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

        def build_file_system(document, options)
          file_system = super
          file_system.roots.push(DEFAULT_TEMPLATES_DIR)
          file_system
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
          options = match[:options] ? parse_options(match[:options].strip) : {}

          schema = load_lutaml_file(document, file_path, options)
          schema_drop = update_repo(options, schema).to_liquid

          template_source = direct_template_source(document, match[:template],
                                                   context_name)
          tmpl = template([template_source])
          tmpl.registers[:file_system] = build_file_system(document, options)
          tmpl.assigns[context_name] = schema_drop
          tmpl.assigns["diagrams"] = options["diagrams"] != "false"

          tmpl.render.split("\n", -1)
        rescue StandardError => e
          ::Metanorma::Util.log(
            "[#{self.class.name}] Failed to parse LutaML block: #{e.message}",
            :error,
          )
          raise e
        end

        def direct_template_source(document, template_path, context_name)
          if template_path.nil? || template_path.strip.empty?
            return "{% render \"#{DEFAULT_TEMPLATE}\", " \
                   "schema: #{context_name}, diagrams: diagrams %}"
          end

          File.read(Utils.relative_file_path(document, template_path.strip),
                    encoding: "UTF-8")
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
