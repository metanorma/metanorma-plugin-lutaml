# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlTablePackageInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_table_package

        def process(parent, _target, attrs)
          return if parent.document.attributes['lutaml_entity_id'].nil?
          xmi_id = parent.document.attributes['lutaml_entity_id'][attrs["package"]]
          return unless xmi_id

          %Q(<xref target="section-#{xmi_id}"></xref>)
        end
      end
    end
  end
end
