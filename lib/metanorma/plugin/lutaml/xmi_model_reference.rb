# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/extensions"

module Metanorma
  module Plugin
    module Lutaml
      # Resolve model links after every macro has generated its actual anchors.
      class XmiModelReference < ::Asciidoctor::Extensions::InlineMacroProcessor
        use_dsl
        named :lutaml_model_reference
        parse_content_as :text
        match(/(?<!\\)&lt;&lt;section-
          (?<target>(?:(?!&gt;&gt;)[^,\s])+?)
          (?:,(?<content>.*?))?&gt;&gt;/x)

        INVENTORY_ATTRIBUTE = "lutaml_model_anchors"

        def self.root_document(document)
          document = document.parent_document while document.parent_document
          document
        end

        def self.register(document, anchors)
          document = root_document(document)
          unless document.attributes.key?(INVENTORY_ATTRIBUTE)
            document.attributes[INVENTORY_ATTRIBUTE] = {}
            document.extensions.inline_macro self
          end
          document.attributes[INVENTORY_ATTRIBUTE].merge!(anchors)
        end

        def process(parent, target, attrs)
          document = self.class.root_document(parent.document)
          name = document.attributes.fetch(INVENTORY_ATTRIBUTE, {})[target]
          text = reference_text(parent, attrs["text"], target, name)
          value = if name && !document.catalog[:refs].key?("section-#{target}")
                    text
                  else
                    label = text ? ",#{text}" : ""
                    "&lt;&lt;section-#{target}#{label}&gt;&gt;"
                  end
          create_inline(parent, :quoted, value, type: :unquoted)
        end

        private

        def reference_text(parent, text, target, name)
          return text unless name && (text.to_s.empty? || text == target)

          parent.sub_specialchars(name)
        end
      end
    end
  end
end
