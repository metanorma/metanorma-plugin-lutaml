# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlEnumTableBlockMacro <
        ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlEaXmiBase
        include Content

        DEFAULT_TEMPLATE = File.join(
          Gem::Specification.find_by_name("metanorma-plugin-lutaml").gem_dir,
          "lib", "metanorma", "plugin", "lutaml", "liquid_templates",
          "_enum_table.liquid"
        )

        CONTEXT_NAME = "enum"

        use_dsl
        named :lutaml_enum_table

        def process(parent, target, attrs) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          xmi_path = get_xmi_path(parent, target, attrs)
          path = get_name_path(attrs)

          enum = ::Lutaml::XMI::Parsers::XML.serialize_enumeration_by_name(
            xmi_path, path
          )

          render_table(enum, CONTEXT_NAME, parent, attrs)
        end

        private

        def get_default_template
          DEFAULT_TEMPLATE
        end
      end
    end
  end
end
