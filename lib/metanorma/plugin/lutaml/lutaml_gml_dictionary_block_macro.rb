# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class LutamlGmlDictionaryBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlGmlDictionaryBase
        use_dsl
        named :lutaml_gml_dictionary

        def process(parent, target, attrs)
          tmpl = gml_dictionary_template(
            parent.document,
            attrs["template"],
          )

          render(tmpl, parent, attrs, target)
        end

        private

        def gml_dictionary_template(document, template_path)
          if template_path.nil?
            document.logger.warn("Template not found!")
          end

          rel_tmpl_path = Utils.relative_file_path(
            document, template_path
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end
      end
    end
  end
end
