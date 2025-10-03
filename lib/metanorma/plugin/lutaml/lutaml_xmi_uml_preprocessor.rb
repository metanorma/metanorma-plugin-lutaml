# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require_relative "utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"
require "metanorma/plugin/lutaml/lutaml_ea_xmi_base"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for rendering Lutaml::Uml models which are parsing from XMI file
      class LutamlXmiUmlPreprocessor < ::Asciidoctor::Extensions::Preprocessor
        include LutamlEaXmiBase

        MACRO_REGEXP = /\[lutaml_xmi_uml,([^,]+),?(.+)?\]/.freeze

        private

        def parse_result_document(full_path, _guidance)
          ::Lutaml::XMI::Parsers::XML.parse(
            File.new(full_path, encoding: "UTF-8"),
          )
        end

        def process_text_blocks(document, input_lines) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
          line = input_lines.next
          process_xmi_index_lines(document, line)
          block_match = line.match(get_macro_regexp)

          return [line] if block_match.nil?

          config_yaml_path = block_match[2]&.strip
          xmi_or_index = block_match[1]&.strip

          lutaml_document, yaml_config = load_lutaml_doc_and_config(
            document,
            xmi_or_index,
            config_yaml_path,
          )

          block_lines = collect_block_lines(input_lines, input_lines.next)

          render_result, errors = Utils.render_liquid_string(
            template_string: block_lines.join("\n"),
            contexts: create_default_context_object(
              lutaml_document, yaml_config
            ),
            document: document,
            include_path: template_path(document, yaml_config.template_path),
          )
          Utils.notify_render_errors(document, errors)

          render_result.split("\n")
        end

        def create_default_context_object(uml_document, options)
          context_name = "context"
          if options.context_name
            context_name = options.context_name
          end
          contexts = {}
          contexts[context_name] = uml_document.to_liquid
          contexts
        end
      end
    end
  end
end
