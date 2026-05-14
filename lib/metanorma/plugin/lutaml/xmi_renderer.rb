# frozen_string_literal: true

require "liquid"

module Metanorma
  module Plugin
    module Lutaml
      module XmiRenderer
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

        def template_path(document, tmpl_path)
          return LIQUID_INCLUDE_PATH if tmpl_path.nil?

          Utils.relative_file_path(document, tmpl_path)
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

        def render_table(context, context_name, parent, attrs) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          table_tmpl = get_template(parent.document, attrs)
          table_tmpl.assigns[context_name] = context

          if attrs["external_data"]
            data_array = attrs["external_data"].split(";")
            data_array.each do |data_item|
              context_name, external_data_path = data_item.split(":")
              external_data = content_from_file(
                parent.document, external_data_path.strip
              )
              table_tmpl.assigns[context_name.strip] = external_data
            end
          end

          rendered_table = table_tmpl.render
          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_table, attrs)
        end

        def get_template(document, attrs)
          tmpl = get_default_template
          tmpl = attrs["template"] if attrs["template"]

          rel_tmpl_path = Utils.relative_file_path(
            document, tmpl
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end

        def get_name_path(attrs)
          return attrs["path"] if attrs["path"]

          return "#{attrs['package']}::#{attrs['name']}" if attrs["package"]

          attrs["name"]
        end
      end
    end
  end
end
