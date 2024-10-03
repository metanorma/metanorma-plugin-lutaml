# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlKlassTableBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        DEFAULT_TEMPLATE_PATH = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates"
        )

        use_dsl
        named :lutaml_klass_table

        def process(parent, target, attrs)
          xmi_path = Utils.relative_file_path(parent.document, target)

          if attrs["tmpl_folder"]
            attrs["tmpl_folder"] = Utils.relative_file_path(
              parent.document, attrs["tmpl_folder"]
            )
          end

          gen = ::Lutaml::XMI::Parsers::XML.serialize_generalization_by_name(
            xmi_path, attrs["name"]
          )

          render(gen, parent, attrs)
        end

        private

        def render(gen, parent, attrs)
          rendered_table = render_table(gen, parent, attrs)

          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_table, attrs)
        end

        def render_table(gen, parent, attrs)
          table_tmpl = get_template(parent.document, attrs)
          table_tmpl.assigns["root"] = gen
          table_tmpl.render
        end

        def get_template(document, attrs)
          tmpl_folder = DEFAULT_TEMPLATE_PATH
          if attrs["tmpl_folder"]
            tmpl_folder = attrs["tmpl_folder"]
          end
          template_path = get_default_template_path(tmpl_folder, attrs)

          rel_tmpl_path = Utils.relative_file_path(
            document, template_path
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end

        def get_default_template_path(tmpl_folder, attrs)
          liquid_template = attrs["table_tmpl_name"] || "_klass_table"
          File.join(tmpl_folder, "#{liquid_template}.liquid")
        end
      end
    end
  end
end
