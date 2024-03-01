# frozen_string_literal: true

require "metanorma/plugin/lutaml/lutaml_diagram_base"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlDiagramBlock < ::Asciidoctor::Extensions::BlockProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_diagram
        on_context :literal
        parse_content_as :raw

        def lutaml_file(document, reader)
          lutaml_temp(document, reader)
        end

        private

        def lutaml_temp(document, reader)
          temp_file = Tempfile.new(["lutaml", ".lutaml"],
                                   Utils.relative_file_path(document, ""))
          temp_file.puts(reader.read)
          temp_file.rewind
          temp_file
        end
      end
    end
  end
end
