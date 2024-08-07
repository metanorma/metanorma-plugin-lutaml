# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlGmlDictionaryBlock < ::Asciidoctor::Extensions::BlockProcessor
        include LutamlGmlDictionaryBase
        use_dsl
        named :lutaml_gml_dictionary
        on_context :open
        parse_content_as :raw

        def process(parent, reader, attrs)
          lines = reader.lines
          tmpl = ::Liquid::Template.parse(lines.join("\n"))
          render(tmpl, parent, attrs, attrs[2])
        end
      end
    end
  end
end
