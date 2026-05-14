# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/reader"

module Metanorma
  module Plugin
    module Lutaml
      module LutamlEaXmiBase
        include Utils
        include XmiCache
        include XmiConfig
        include XmiPackageFilter
        include XmiContextBuilder
        include XmiRenderer

        SUPPORTED_NESTED_MACRO = %w[
          before diagram_include_block after include_block package_text
        ].freeze
        XMI_INDEX_REGEXP = %r{
          ^:lutaml-xmi-index:  # Start of the pattern
          (?<index_name>.+?)   # Capture index name
          ;                    # Separator
          (?<index_path>.+?)   # Capture index path
          ;?                   # Optional separator
          (?<config_group>     # Optional config group
            \s*config=         # Config prefix
            (?<config_path>.+) # Capture config path
          )?                   # End of optional group
          $                    # End of the pattern
        }x

        def process(document, reader)
          r = Asciidoctor::PreprocessorNoIfdefsReader.new document, reader.lines
          input_lines = r.readlines.to_enum
          Asciidoctor::PreprocessorNoIfdefsReader
            .new(document, processed_lines(document, input_lines))
        end

        private

        def get_xmi_path(parent, target, attrs)
          return get_path_from_index(parent, attrs["index"]) if attrs["index"]

          Utils.relative_file_path(parent.document, target)
        end

        def get_path_from_index(parent, index_name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          lutaml_xmi_index = parent.document
            .attributes["lutaml_xmi_index"][index_name]

          if lutaml_xmi_index.nil? || lutaml_xmi_index[:path].nil?
            ::Metanorma::Util.log(
              "[metanorma-plugin-lutaml] lutaml_xmi_index error: " \
              "XMI index #{index_name} path not found!",
              :error,
            )

            return nil
          end

          lutaml_xmi_index[:path]
        end

        def get_macro_regexp
          self.class.const_get(:MACRO_REGEXP)
        end

        def process_xmi_index_lines(document, line) # rubocop:disable Metrics/AbcSize
          block_match = line.match(XMI_INDEX_REGEXP)

          return if block_match.nil?

          name = block_match[:index_name]&.strip
          path = block_match[:index_path]&.strip
          config = block_match[:config_path]&.strip

          document.attributes["lutaml_xmi_index"] ||= {}
          document.attributes["lutaml_xmi_index"][name] = {
            path: path,
            config: config,
          }
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

          fill_in_diagrams_attributes(document, lutaml_document)
          model_representation(
            lutaml_document, document,
            collect_additional_context(document, input_lines, input_lines.next),
            yaml_config
          )
        end

        def load_lutaml_doc_and_config(document, xmi_or_index, config_yaml_path) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          index = xmi_or_index.match(/index=(.*)/)

          if index
            index_name = index[1]

            if document.attributes["lutaml_xmi_index"][index_name].nil? ||
                document.attributes["lutaml_xmi_index"][index_name][:path].nil?
              ::Metanorma::Util.log(
                "[metanorma-plugin-lutaml] lutaml_xmi_index error: " \
                "XMI index #{index_name} path not found!",
                :error,
              )
            end

            xmi_or_index = document
              .attributes["lutaml_xmi_index"][index_name][:path]
            config_yaml_path = document
              .attributes["lutaml_xmi_index"][index_name][:config]
          end

          yaml_config = parse_yaml_config_file(document, config_yaml_path)
          lutaml_document = lutaml_document_from_file_or_cache(
            document,
            xmi_or_index,
            yaml_config,
            Utils.relative_file_path(document, config_yaml_path),
          )
          [lutaml_document, yaml_config]
        end

        def collect_block_lines(input_lines, end_mark)
          block_lines = []

          while (block_line = input_lines.next) != end_mark
            block_lines.push(block_line)
          end

          block_lines
        end

        def collect_additional_context(document, input_lines, end_mark) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          additional_context = Hash.new { |hash, key| hash[key] = [] }
          additional_context["all_macros"] = []
          block_lines = collect_block_lines(input_lines, end_mark)

          processed_lines = process(
            document,
            ::Asciidoctor::PreprocessorReader.new(document, block_lines),
          ).read_lines

          block_document = ::Asciidoctor::Document
            .new(processed_lines, {}).parse
          block_document.blocks.each do |block|
            next unless SUPPORTED_NESTED_MACRO.include?(
              block.attributes["role"],
            )

            attrs = block.attributes
            name = attrs.delete("role")
            package = attrs.delete("package")
            macro_keyword = [name, package].compact.join(";")
            block_text = if block.lines.length.positive?
                           block.lines.join("\n")
                         else
                           ""
                         end
            additional_context[macro_keyword]
              .push({ "text" => block_text }.merge(attrs))
            additional_context["all_macros"]
              .push({ "text" => block_text,
                      "type" => name, "package" => package }.merge(attrs))
          end
          additional_context
        end
      end
    end
  end
end
