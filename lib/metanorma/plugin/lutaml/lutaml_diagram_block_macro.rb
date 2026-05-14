# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlDiagramBlockMacro <
        ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_diagram

        def lutaml_file(document, file_path)
          File.new(Utils.relative_file_path(document, file_path))
        end
      end
    end
  end
end
