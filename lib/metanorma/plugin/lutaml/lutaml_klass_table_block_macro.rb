# frozen_string_literal: true

require_relative "liquid_drops/klass_table_drop"
require_relative "liquid_drops/klass_table_attribute_drop"
require_relative "liquid_drops/klass_table_general_drop"
require_relative "liquid_drops/klass_table_content_drop"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlKlassTableBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        DEFAULT_TEMPLATE_PATH = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib/metanorma/plugin/lutaml/liquid_templates/<NAME>.liquid",
        )
        DEFAULT_TABLE_TEMPLATE = DEFAULT_TEMPLATE_PATH
          .gsub("<NAME>", "_klass_table")
        DEFAULT_ROW_TEMPLATE = DEFAULT_TEMPLATE_PATH
          .gsub("<NAME>", "_klass_row")
        DEFAULT_ASSOC_ROW_TEMPLATE = DEFAULT_TEMPLATE_PATH
          .gsub("<NAME>", "_klass_assoc_row")

        use_dsl
        named :lutaml_klass_table

        def process(parent, target, attrs)
          result_path = Utils.relative_file_path(parent.document, target)

          gen = ::Lutaml::XMI::Parsers::XML.serialize_generalization_by_name(
            result_path, attrs["name"]
          )

          render(gen, parent, attrs)
        end

        private

        def render(gen, parent, attrs) # rubocop:disable Metrics/MethodLength
          content = {}

          content[:owned_props] = render_owned_props(
            gen, parent, attrs
          )
          content[:assoc_props] = render_assoc_props(
            gen, parent, attrs
          )
          content[:inherited_props] = render_inherited_props(
            gen, parent, attrs
          )
          content[:inherited_assoc_props] = render_inherited_assoc_props(
            gen, parent, attrs
          )

          # content[:inherited_props] += render_named_inherited_props(
          #   gen, parent, attrs, "gml"
          # )
          # content[:inherited_props] += render_named_inherited_props(
          #   gen, parent, attrs, "core"
          # )
          # content[:inherited_assoc_props] += render_named_inherited_props(
          #   gen, parent, attrs, "gen"
          # )

          rendered_table = render_table(gen, parent, attrs, content)

          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_table, attrs)
        end

        def render_table(gen, parent, attrs, content)
          table_tmpl = get_template(
            parent.document, attrs["table_template"], :table
          )

          table_tmpl.assigns["root"] = KlassTableDrop.new(gen)
          table_tmpl.assigns["content"] =
            KlassTableContentDrop.new(content)

          table_tmpl.render
        end

        def render_general_rows(general_item, parent, attrs)
          row_tmpl = get_template(
            parent.document, attrs["row_template"], :row
          )
          render_rows(general_item, row_tmpl)
        end

        def render_assoc_rows(general_item, parent, attrs)
          row_tmpl = get_template(
            parent.document, attrs["assoc_template"], :assoc_row
          )
          render_rows(general_item, row_tmpl)
        end

        def render_rows(general_item, row_tmpl)
          gen_attrs = general_item[:general_attributes]
          upper_klass = general_item[:general_upper_klass]
          gen_name = general_item[:general_name]
          attributes = prepare_row_drops(gen_attrs, upper_klass, gen_name)
          row_tmpl.assigns["attributes"] = attributes
          row_tmpl.render
        end

        def prepare_row_drops(gen_attrs, upper_klass, gen_name) # rubocop:disable Metrics/MethodLength
          gen_attrs.map do |attr|
            attr[:gen_name] = gen_name
            attr[:upper_klass] = upper_klass
            attr[:name_ns] = case attr[:type_ns]
                             when "core", "gml"
                               upper_klass
                             else
                               attr[:type_ns]
                             end

            attr[:name_ns] = upper_klass if attr[:name_ns].nil?

            KlassTableAttributeDrop.new(attr)
          end
        end

        def render_owned_props(gen, parent, attrs)
          render_general_rows(gen, parent, attrs)
        end

        def render_assoc_props(gen, parent, attrs)
          render_assoc_rows(gen, parent, attrs)
        end

        def render_gml_inherited_props(gen, parent, attrs)
          render_named_inherited_props(gen, parent, attrs, "gml")
        end

        def render_core_inherited_props(gen, parent, attrs)
          render_named_inherited_props(gen, parent, attrs, "core")
        end

        def render_gen_inherited_props(gen, parent, attrs)
          render_named_inherited_props(gen, parent, attrs, "gen")
        end

        def render_named_inherited_props(gen, parent, attrs, name)
          attr_key = "#{name}_attributes".to_sym
          general_item = {}
          general_item[:general_attributes] = gen[attr_key]
          general_item[:general_upper_klass] = gen[attr_key].first[:upper_klass]
          general_item[:general_name] = name

          render_general_rows(general_item, parent, attrs)
        end

        def render_inherited_props(gen, parent, attrs)
          render_inherited_rows(gen, parent, attrs, assoc: false)
        end

        def render_inherited_assoc_props(gen, parent, attrs)
          render_inherited_rows(gen, parent, attrs, assoc: true)
        end

        def render_inherited_rows(gen, parent, attrs, assoc: false) # rubocop:disable Metrics/MethodLength
          rendered_rows = ""
          general_item = gen[:general]

          while general_item && !general_item.empty?
            rendered_rows += if assoc
                               render_assoc_rows(general_item, parent, attrs)
                             else
                               render_general_rows(general_item, parent, attrs)
                             end
            general_item = general_item[:general]
          end

          rendered_rows
        end

        def get_template(document, template_path, tmpl_type)
          if template_path.nil?
            template_path = get_default_template_path(tmpl_type)
          end

          rel_tmpl_path = Utils.relative_file_path(
            document, template_path
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end

        def get_default_template_path(tmpl_type)
          case tmpl_type
          when :row
            DEFAULT_ROW_TEMPLATE
          when :assoc_row
            DEFAULT_ASSOC_ROW_TEMPLATE
          else
            DEFAULT_TABLE_TEMPLATE
          end
        end
      end
    end
  end
end
