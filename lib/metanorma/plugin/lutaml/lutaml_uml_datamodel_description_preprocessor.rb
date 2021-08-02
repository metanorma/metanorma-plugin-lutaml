# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "metanorma/plugin/lutaml/utils"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      #  @example [lutaml_uml_attributes_table,path/to/lutaml,EntityName]
      class LutamlUmlDatamodelDescriptionPreprocessor <
          Asciidoctor::Extensions::Preprocessor
        MARCO_REGEXP =
          /\[lutaml_uml_datamodel_description,([^,]+),?(.+)?\]/
        LIQUID_INCLUDE_PATH = File.join(
          Gem.loaded_specs["metanorma-plugin-lutaml"].full_gem_path,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates"
        )
        # search document for block `lutaml_uml_datamodel_description`
        #  read include derectives that goes after that in block and transform
        #  into yaml2text blocks
        def process(document, reader)
          input_lines = reader.readlines.to_enum
          Asciidoctor::Reader.new(processed_lines(document, input_lines))
        end

        private

        def lutaml_document_from_file(document, file_path)
          ::Lutaml::Parser
            .parse(File.new(Utils.relative_file_path(document, file_path),
                            encoding: "UTF-8"))
            .first
        end

        def parse_yaml_config_file(document, file_path)
          return {} if file_path.nil?

          relative_file_path = Utils.relative_file_path(document, file_path)
          YAML.load(File.read(relative_file_path, encoding: "UTF-8"))
        end

        def processed_lines(document, input_lines)
          result = []
          loop do
            result.push(*process_text_blocks(document, input_lines))
          end
          result
        end

        def process_text_blocks(document, input_lines)
          line = input_lines.next
          block_match = line.match(MARCO_REGEXP)
          return [line] if block_match.nil?

          model_representation(
            lutaml_document_from_file(document, block_match[1]),
            document,
            collect_additional_context(input_lines, input_lines.next),
            parse_yaml_config_file(document, block_match[2]))
        end

        def collect_additional_context(input_lines, end_mark)
          additional_context = {}
          block_lines = []
          while (block_line = input_lines.next) != end_mark
            block_lines.push(block_line)
          end
          block_document = (Asciidoctor::Document.new(block_lines, {})).parse
          block_document.blocks.each do |block|
            attrs = block.attributes
            name = attrs.delete('role')
            package = attrs.delete('package')
            macro_keyword = [name, package].compact.join(";")
            additional_context[macro_keyword] = { 'text' => block.lines[1..-2].join("\n") }.merge(attrs)
          end
          additional_context
        end

        def create_context_object(lutaml_document, additional_context, options)
          if options.length.zero?
            return {
              'render_nested_packages' => true,
              "packages" => lutaml_document.to_liquid['packages'].first['packages'].first['packages'],
              "additional_context" => additional_context
            }
          end

          root_package = lutaml_document.to_liquid['packages'].first
          all_packages = [root_package, *root_package['children_packages']]
          {
            "packages" => sort_and_filter_out_packages(all_packages, options),
            "additional_context" => additional_context
          }
        end

        def sort_and_filter_out_packages(all_packages, options)
          return all_packages if options['packages'].nil?

          result = []
          # Step one - filter out all skipped packages
          options['packages']
            .find_all { |entity| entity.is_a?(Hash) && entity['skip'] }
            .each do |entity|
              entity_regexp = config_entity_regexp(entity['skip'])
              all_packages
                .delete_if {|package| package['name'] =~ entity_regexp }
            end
          # Step two - select supplied packages by pattern
          options['packages']
            .find_all { |entity| entity.is_a?(String) }
            .each do |entity|
              entity_regexp = config_entity_regexp(entity)
              all_packages.each.with_index do |package|
                if package['name'] =~ entity_regexp
                  result.push(package)
                  all_packages
                    .delete_if {|nest_package| nest_package['name'] == package['name'] }
                end
              end
            end
          result
        end

        def config_entity_regexp(entity)
          additional_sym = '.*' if entity =~ /\*$/
          %r{^#{Regexp.escape(entity.gsub('*', ''))}#{additional_sym}$}
        end

        def model_representation(lutaml_document, document, additional_context, options)
          render_result, errors = Utils.render_liquid_string(
            template_string: table_template,
            context_items: create_context_object(lutaml_document,
                              additional_context,
                              options),
            context_name: "context",
            document: document,
            include_path: LIQUID_INCLUDE_PATH
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def table_template
          <<~LIQUID
            {% include "packages", depth: 2, context: context, additional_context: context.additional_context, render_nested_packages: context.render_nested_packages %}
          LIQUID
        end
      end
    end
  end
end
