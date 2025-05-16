# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlTableInlineMacro <
        ::Asciidoctor::Extensions::InlineMacroProcessor
        include LutamlDiagramBase
        SUPPORTED_OPTIONS = %w[class enum data_type].freeze

        use_dsl
        named :lutaml_table

        def process(parent, _target, attrs)
          keyword = SUPPORTED_OPTIONS.find { |n| attrs[n] }
          entity_key = [keyword, attrs["package"],
                        attrs[keyword]].compact.join(":")
          return if parent.document.attributes["lutaml_entity_id"].nil?

          xmi_id = parent.document.attributes["lutaml_entity_id"][entity_key]
          return unless xmi_id

          %(<xref target="section-#{xmi_id}"/>)
        end
      end
    end
  end
end
