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
        DEFAULT_RENDER_INCLUDE = 'packages'.freeze
        RENDER_STYLES_INCLUDES = {
          'default' => 'packages',
          'entity_list' => 'packages_entity_list',
          'data_dictionary' => 'packages_data_dictionary'
        }.freeze
        RENDER_STYLE_ATTRIBUTE = 'render_style'.freeze
        SUPPORTED_NESTED_MACRO = %w[
          before diagram_include_block after include_block].freeze
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

          lutaml_document = lutaml_document_from_file(document, block_match[1])
          fill_in_diagrams_attributes(document, lutaml_document)
          model_representation(
            lutaml_document,
            document,
            collect_additional_context(input_lines, input_lines.next),
            parse_yaml_config_file(document, block_match[2]))
        end

        def fill_in_entities_refs_attributes(document, lutaml_document_wrapper, options)
          lutaml_document = lutaml_document_wrapper.original_document
          render_style = options.fetch(RENDER_STYLE_ATTRIBUTE, 'default')
          all_children_packages = lutaml_document.packages.map(&:children_packages).flatten
          package_flat_packages = lambda do |pks|
            pks.each_with_object({}) do |package, res|
              res[package.name] = package.xmi_id
            end
          end
          children_pks = package_flat_packages.call(all_children_packages)
          ref_dictionary = package_flat_packages.call(lutaml_document.packages)
                            .merge(children_pks)
          %w[class enum data_type].each do |type|
            package_flat = lambda do |pks|
              pks.each_with_object({}) do |package, res|
                plural = type == "class" ? "classes" : "#{type}s"
                package.send(plural).map do |entity|
                  res["#{type}:#{package.name}:#{entity.name}"] = entity.xmi_id
                end
              end
            end
            children_pks_daigs = package_flat.call(all_children_packages)
              ref_dictionary = ref_dictionary
                                .merge(package_flat.call(lutaml_document.packages)
                                        .merge(children_pks_daigs))
          end
          document.attributes['lutaml_entity_id'] = ref_dictionary
        end

        def fill_in_diagrams_attributes(document, lutaml_document_wrapper)
          lutaml_document = lutaml_document_wrapper.original_document
          package_flat_diagrams = lambda do |pks|
            pks.each_with_object({}) do |package, res|
              package.diagrams.map { |diag| res["#{package.name}:#{diag.name}"] = diag.xmi_id }
            end
          end
          children_pks_daigs = package_flat_diagrams.call(lutaml_document.packages.map(&:children_packages).flatten)
          document.attributes['lutaml_figure_id'] = package_flat_diagrams.call(lutaml_document.packages)
                                                      .merge(children_pks_daigs)
        end

        def collect_additional_context(input_lines, end_mark)
          additional_context = Hash.new { |hash, key| hash[key] = [] }
          block_lines = []
          while (block_line = input_lines.next) != end_mark
            block_lines.push(block_line)
          end
          block_document = (Asciidoctor::Document.new(block_lines, {})).parse
          block_document.blocks.each do |block|
            next unless SUPPORTED_NESTED_MACRO.include?(block.attributes['role'])

            attrs = block.attributes
            name = attrs.delete('role')
            package = attrs.delete('package')
            macro_keyword = [name, package].compact.join(";")
            block_text = block.lines.length > 0 ? block.lines[1..-2].join("\n") : ''
            additional_context[macro_keyword].push({ 'text' => block_text }.merge(attrs))
          end
          additional_context
        end

        def package_level(lutaml_document, level)
          return lutaml_document if level <= 0

          package_level(lutaml_document['packages'].first, level - 1)
        end

        def create_context_object(lutaml_document, additional_context, options)
          root_package = package_level(lutaml_document.to_liquid, options['package_root_level'] || 1)
          if options.length.zero? || options['packages'].nil?
            return {
              'render_nested_packages' => true,
              "packages" => root_package['packages'],
              "additional_context" => additional_context
            }
          end

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
          fill_in_entities_refs_attributes(document, lutaml_document, options)
          render_result, errors = Utils.render_liquid_string(
            template_string: table_template(options['section_depth'] || 2, options[RENDER_STYLE_ATTRIBUTE]),
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

        def table_template(section_depth, render_style)
          include_name = RENDER_STYLES_INCLUDES.fetch(render_style, DEFAULT_RENDER_INCLUDE)
          <<~LIQUID
            {% include "#{include_name}", depth: #{section_depth}, context: context, additional_context: context.additional_context, render_nested_packages: context.render_nested_packages %}
          LIQUID
        end
      end
    end
  end
end
