# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlTableClassInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_table_class

        def process(parent, _target, attrs)
          entity_key = ['class', attrs["package"], attrs["name"]].compact.join(":")
          return if parent.document.attributes['lutaml_entity_id'].nil?
          xmi_id = parent.document.attributes['lutaml_entity_id'][entity_key]
          return unless xmi_id

          %Q(<xref target="section-#{xmi_id}"></xref>)
        end
      end
    end
  end
end
