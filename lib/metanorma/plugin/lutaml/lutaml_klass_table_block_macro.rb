# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlKlassTableBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        DEFAULT_TEMPLATE = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates",
          "_klass_table.liquid"
        )

        use_dsl
        named :lutaml_klass_table

        def process(parent, target, attrs)
          xmi_path = Utils.relative_file_path(parent.document, target)

          if attrs["template"]
            attrs["template"] = Utils.relative_file_path(
              parent.document, attrs["template"]
            )
          end

          klass = ::Lutaml::XMI::Parsers::XML.serialize_generalization_by_name(
            xmi_path, attrs["name"]
          )

          render(klass, parent, attrs)
        end

        private

        def render(klass, parent, attrs)
          rendered_table = render_table(klass, parent, attrs)

          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_table, attrs)
        end

        def render_table(klass, parent, attrs)
          table_tmpl = get_template(parent.document, attrs)
          table_tmpl.assigns["klass"] = klass
          table_tmpl.render
        end

        def get_template(document, attrs)
          template = DEFAULT_TEMPLATE
          if attrs["template"]
            template = attrs["template"]
          end

          rel_tmpl_path = Utils.relative_file_path(
            document, template
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end
      end
    end
  end
end
