# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlKlassTableBlockMacro <
        ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlEaXmiBase

        DEFAULT_TEMPLATE = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates",
          "_klass_table.liquid"
        )

        use_dsl
        named :lutaml_klass_table

        def process(parent, target, attrs) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          xmi_path = get_xmi_path(parent, target, attrs)

          if attrs["template"]
            attrs["template"] = Utils.relative_file_path(
              parent.document, attrs["template"]
            )
          end

          guidance = nil
          if attrs["guidance"]
            guidance = get_guidance(parent.document, attrs["guidance"])
          end

          path = if !attrs["path"].nil?
                   attrs["path"]
                 elsif !attrs["package"].nil? && !attrs["name"].nil?
                   "#{attrs['package']}::#{attrs['name']}"
                 else
                   attrs["name"]
                 end

          klass = ::Lutaml::XMI::Parsers::XML.serialize_generalization_by_name(
            xmi_path, path, guidance
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
