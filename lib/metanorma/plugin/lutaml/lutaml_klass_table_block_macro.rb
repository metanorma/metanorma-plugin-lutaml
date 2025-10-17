# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlKlassTableBlockMacro <
        ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlEaXmiBase
        include Content

        DEFAULT_TEMPLATE = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates",
          "_klass_table.liquid"
        )

        use_dsl
        named :lutaml_klass_table

        def process(parent, target, attrs) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          xmi_path = get_xmi_path(parent, target, attrs)
          path = get_name_path(attrs)

          guidance = nil
          if attrs["guidance"]
            guidance = get_guidance(parent.document, attrs["guidance"])
          end

          klass = ::Lutaml::XMI::Parsers::XML.serialize_generalization_by_name(
            xmi_path, path, guidance
          )

          render(klass, parent, attrs)
        end

        private

        def render(klass, parent, attrs)
          rendered_table = render_table(klass, "klass", parent, attrs)
          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_table, attrs)
        end

        def get_default_template
          DEFAULT_TEMPLATE
        end
      end
    end
  end
end
