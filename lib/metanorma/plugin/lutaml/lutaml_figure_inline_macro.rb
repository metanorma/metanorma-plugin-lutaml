# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlFigureInlineMacro < Asciidoctor::Extensions::InlineMacroProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_figure

        def process(parent, _target, attrs)
          diagram_key = [attrs["package"], attrs["name"]].compact.join(":")
          return if parent.document.attributes['lutaml_figure_id'].nil?
          xmi_id = parent.document.attributes['lutaml_figure_id'][diagram_key]
          return unless xmi_id

          %Q(<xref target="figure-#{xmi_id}"></xref>)
        end
      end
    end
  end
end
