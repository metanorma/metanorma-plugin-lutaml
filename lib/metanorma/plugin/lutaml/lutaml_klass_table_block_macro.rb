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

        def render_general_rows(gen_attributes, upper_klass, parent, attrs)
          row_tmpl = get_template(
            parent.document, attrs["row_template"], :row
          )
          render_rows(gen_attributes, upper_klass, row_tmpl)
        end

        def render_assoc_rows(gen_attributes, upper_klass, parent, attrs)
          row_tmpl = get_template(
            parent.document, attrs["assoc_template"], :assoc_row
          )
          render_rows(gen_attributes, upper_klass, row_tmpl)
        end

        def render_rows(gen_attributes, upper_klass, row_tmpl)
          attributes = prepare_row_attrbiutes(gen_attributes, upper_klass)
          row_tmpl.assigns["attributes"] = attributes
          row_tmpl.render
        end

        def prepare_row_attrbiutes(gen_attributes, upper_klass)
          gen_attributes.map do |attr|
            attr[:upper_klass] = case attr[:type_ns]
                                 when "core", "gml"
                                   upper_klass
                                 else
                                   attr[:type_ns]
                                 end

            attr[:upper_klass] = upper_klass if attr[:upper_klass].nil?

            KlassTableAttributeDrop.new(attr)
          end
        end

        def render_owned_props(gen, parent, attrs)
          gen_attributes = gen[:general_attributes]
          upper_klass = gen[:general_upper_klass]
          render_general_rows(gen_attributes, upper_klass, parent, attrs)
        end

        def render_assoc_props(gen, parent, attrs)
          gen_attributes = gen[:general_attributes]
          upper_klass = gen[:general_upper_klass]
          render_assoc_rows(gen_attributes, upper_klass, parent, attrs)
        end

        def render_inherited_props(gen, parent, attrs)
          rendered_rows = ""
          # rendered_rows += render_gml_inherited_props(gen, parent, attrs)
          # rendered_rows += render_core_inherited_props(gen, parent, attrs)

          general_item = gen[:general]
          while general_item && !general_item.empty?
            gen_attributes = general_item[:general_attributes]
            upper_klass = general_item[:general_upper_klass]
            rendered_rows += render_general_rows(gen_attributes, upper_klass,
                                                 parent, attrs)
            general_item = general_item[:general]
          end

          rendered_rows
        end

        def render_gml_inherited_props(gen, parent, attrs)
          rendered_rows = ""
          rendered_rows += render_general_rows(
            gen[:gml_attributes],
            gen[:gml_attributes].first[:upper_klass],
            parent, attrs
          )
          rendered_rows
        end

        def render_core_inherited_props(gen, parent, attrs)
          rendered_rows = ""
          rendered_rows += render_general_rows(
            gen[:core_attributes],
            gen[:core_attributes].first[:upper_klass],
            parent, attrs
          )
          rendered_rows
        end

        def render_gen_inherited_props(gen, parent, attrs)
          rendered_rows = ""
          rendered_rows += render_general_rows(
            gen[:gen_attributes],
            gen[:gen_attributes].first[:upper_klass],
            parent, attrs
          )
          rendered_rows
        end

        def render_inherited_assoc_props(gen, parent, attrs)
          rendered_rows = ""
          # rendered_rows += render_gen_inherited_props(gen, parent, attrs)
          general_item = gen[:general]
          while general_item && !general_item.empty?
            gen_attributes = general_item[:general_attributes]
            upper_klass = general_item[:general_upper_klass]
            rendered_rows += render_assoc_rows(gen_attributes, upper_klass,
                                               parent, attrs)
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
