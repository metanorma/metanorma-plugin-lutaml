# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "lutaml/formatter"
require_relative "utils"

module Metanorma
  module Plugin
    module Lutaml
      module LutamlEaXmiBase
        include Utils

        LIQUID_INCLUDE_PATH = File.join(
          Gem.loaded_specs["metanorma-plugin-lutaml"].full_gem_path,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates"
        )
        DEFAULT_RENDER_INCLUDE = "packages"
        RENDER_STYLES_INCLUDES = {
          "default" => "packages",
          "entity_list" => "packages_entity_list",
          "entity_list_class" => "packages_entity_list_class",
          "data_dictionary" => "packages_data_dictionary",
        }.freeze
        RENDER_STYLE_ATTRIBUTE = "render_style"
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
        }x.freeze

        # search document for block `lutaml_ea_xmi`
        # or `lutaml_uml_datamodel_description`
        # read include directives that goes after that in block and transform
        # into yaml2text blocks
        def process(document, reader)
          r = Asciidoctor::PreprocessorNoIfdefsReader.new document, reader.lines
          input_lines = r.readlines.to_enum
          Asciidoctor::PreprocessorNoIfdefsReader
            .new(document, processed_lines(document, input_lines))
        end

        private

        def lutaml_document_from_file_or_cache(document, file_path, yaml_config, yaml_config_path = nil) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Layout/LineLength
          full_path = Utils.relative_file_path(document, file_path)
          if document.attributes["lutaml_xmi_cache"] &&
              document.attributes["lutaml_xmi_cache"][full_path]
            return document.attributes["lutaml_xmi_cache"][full_path]
          end

          yaml_config.ea_extension&.each do |ea_extension_path|
            # resolve paths of ea extensions based on the location of
            # config yaml file
            ea_extension_full_path = File.expand_path(
              ea_extension_path, File.dirname(yaml_config_path)
            )
            Xmi::EaRoot.load_extension(ea_extension_full_path)
          end

          guidance = get_guidance(document, yaml_config.guidance)
          result_document = parse_result_document(full_path, guidance)
          document.attributes["lutaml_xmi_cache"] ||= {}
          document.attributes["lutaml_xmi_cache"][full_path] = result_document
          result_document
        end

        def get_guidance(document, guidance_config)
          return unless guidance_config

          guidance_yaml = Utils.relative_file_path(document, guidance_config)
          guidance = Metanorma::Plugin::Lutaml::Config::Guidance.from_yaml(
            File.read(guidance_yaml, encoding: "UTF-8"),
          )
          guidance.to_yaml_hash
        end

        def parse_yaml_config_file(document, file_path)
          return Metanorma::Plugin::Lutaml::Config::Root.new if file_path.nil?

          relative_file_path = Utils.relative_file_path(document, file_path)

          Metanorma::Plugin::Lutaml::Config::Root.from_yaml(
            File.read(relative_file_path, encoding: "UTF-8"),
          )
        end

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
            # load lutaml index
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

        def fill_in_entities_refs_attributes(document, # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
          lutaml_document, _options)
          # render_style = options.fetch(RENDER_STYLE_ATTRIBUTE, "default")
          all_children_packages = lutaml_document.packages
            .map(&:children_packages).flatten
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
            children_pks_diags = package_flat.call(all_children_packages)
            ref_dictionary = ref_dictionary
              .merge(package_flat.call(lutaml_document.packages)
                                      .merge(children_pks_diags))
          end
          document.attributes["lutaml_entity_id"] = ref_dictionary
        end

        def fill_in_diagrams_attributes(document, lutaml_document) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          package_flat_diagrams = lambda do |pks|
            pks.each_with_object({}) do |package, res|
              package.diagrams.map do |diag|
                res["#{package.name}:#{diag.name}"] = diag.xmi_id
              end
            end
          end
          children_pks_diags = package_flat_diagrams.call(
            lutaml_document.packages.map(&:children_packages).flatten,
          )

          document.attributes["lutaml_figure_id"] = package_flat_diagrams
            .call(lutaml_document.packages)
            .merge(children_pks_diags)
        end

        def collect_additional_context(document, input_lines, end_mark) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          additional_context = Hash.new { |hash, key| hash[key] = [] }
          additional_context["all_macros"] = []
          block_lines = []

          while (block_line = input_lines.next) != end_mark
            block_lines.push(block_line)
          end

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

        def package_level(lutaml_document, level)
          return lutaml_document if level <= 0

          package_level(lutaml_document["packages"].first, level - 1)
        end

        def create_context_object( # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          lutaml_document, additional_context, options,
          context_name = "context"
        )
          root_package = package_level(lutaml_document.to_liquid,
                                       options.package_root_level || 1)
          contexts = {}

          if options.packages.nil?
            contexts[context_name] = {
              "render_nested_packages" => true,
              "packages" => root_package["packages"],
              "root_packages" => [root_package],
              "additional_context" => additional_context
                .merge("external_classes" => options.external_classes),
              "name" => root_package["name"],
            }

            return contexts
          end

          all_packages = [root_package, *root_package["children_packages"]]
          contexts[context_name] = {
            "packages" => sort_and_filter_out_packages(all_packages, options),
            "package_entities" => package_hash(options, "render_entities"),
            "package_skip_sections" => package_hash(options, "skip_tables"),
            "additional_context" => additional_context
              .merge("external_classes" => options.external_classes),
            "root_packages" => [root_package],
            "render_nested_packages" => options.render_nested_packages ||
              false,
            "name" => root_package["name"],
          }

          contexts
        end

        def package_hash(options, key)
          return {} unless options.packages

          result = {}
          packages = options.packages.reject { |p| p.send(key.to_sym).nil? }
          packages.each do |p|
            result[p.name] = p.send(key.to_sym).map { |n| [n, true] }.to_h
          end
          result
        end

        def sort_and_filter_out_packages(all_packages, options) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          return all_packages if options.packages.nil?

          result = []
          # Step one - filter out all skipped packages
          all_packages =
            filter_out_all_skipped_packages(options, all_packages)

          # Step two - select supplied packages by pattern
          select_supplied_packages_by_pattern(options, all_packages,
                                              result)
        end

        def filter_out_all_skipped_packages(options, all_packages) # rubocop:disable Metrics/AbcSize
          return all_packages if options.skip.nil?

          options.skip.each do |skip_package|
            entity_regexp = config_entity_regexp(skip_package)
            all_packages.delete_if do |package|
              package["name"] =~ entity_regexp
            end
          end

          all_packages
        end

        def select_supplied_packages_by_pattern(options, all_packages, result) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          options.packages.each do |package|
            entity_regexp = config_entity_regexp(package.name)
            all_packages.each do |p|
              if p["name"]&.match?(entity_regexp)
                result.push(p)
                all_packages.delete_if do |nest_package|
                  nest_package["name"] == p["name"]
                end
              end
            end
          end

          result
        end

        def config_entity_regexp(entity)
          additional_sym = ".*" if /\*$/.match?(entity)
          %r{^#{Regexp.escape(entity.delete('*'))}#{additional_sym}$}
        end

        def model_representation(lutaml_doc, document, add_context, options) # rubocop:disable Metrics/MethodLength
          fill_in_entities_refs_attributes(document, lutaml_doc, options)
          render_result, errors = Utils.render_liquid_string(
            template_string: template(options.section_depth || 2,
                                      options.render_style,
                                      options.include_root),
            contexts: create_context_object(lutaml_doc,
                                            add_context,
                                            options,
                                            "context"),
            document: document,
            include_path: template_path(document, options.template_path),
          )
          Utils.notify_render_errors(document, errors)
          render_result.split("\n")
        end

        def template_path(document, template_path)
          return LIQUID_INCLUDE_PATH if template_path.nil?

          Utils.relative_file_path(document, template_path)
        end

        def template(section_depth, render_style, include_root)
          include_name = RENDER_STYLES_INCLUDES.fetch(render_style,
                                                      DEFAULT_RENDER_INCLUDE)
          result = ""
          if include_root
            result += <<~LIQUID
              {% include "#{include_name}", package_skip_sections: context.package_skip_sections, package_entities: context.package_entities, context: context.root_packages, additional_context: context.additional_context, render_nested_packages: false %}
            LIQUID
          end
          result + <<~LIQUID
            {% include "#{include_name}", depth: #{section_depth}, package_skip_sections: context.package_skip_sections, package_entities: context.package_entities, context: context, additional_context: context.additional_context, render_nested_packages: context.render_nested_packages %}
          LIQUID
        end
      end
    end
  end
end
