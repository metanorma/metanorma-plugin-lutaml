# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/extensions"
require "set"

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
        # Ids of real model entities (classes, enums, data types, packages).
        # These never degrade to plain text (#70): even when the current
        # template does not render their sections, the link must survive
        # for collection-level documents to resolve.
        ANCHORABLE_ATTRIBUTE = "lutaml_model_anchorable"

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
          document.attributes[INVENTORY_ATTRIBUTE]
            .merge!(anchors) { |_, old, new| new || old }
        end

        # The subset of the inventory that is a real model entity
        # (classes, enums, data types, packages, stubs). Only ids the XMI
        # never defines (attribute types and association ends present
        # solely as idrefs) degrade to plain text; XMI-declared objects
        # stay linked (#70).
        def self.register_anchorable(document, ids)
          document = root_document(document)
          document.attributes[ANCHORABLE_ATTRIBUTE] ||= Set.new
          document.attributes[ANCHORABLE_ATTRIBUTE].merge(ids)
        end

        def process(parent, target, attrs)
          document = self.class.root_document(parent.document)
          inventory = document.attributes.fetch(INVENTORY_ATTRIBUTE, {})
          name = inventory[target]
          text = reference_text(parent, attrs["text"], target, name)
          value = if suppress_link?(document, target)
                    plain_text(parent, text, target)
                  else
                    label = text ? ",#{text}" : ""
                    "&lt;&lt;section-#{target}#{label}&gt;&gt;"
                  end
          create_inline(parent, :quoted, value, type: :unquoted)
        end

        private

        def suppress_link?(document, target)
          inventory = document.attributes.fetch(INVENTORY_ATTRIBUTE, {})
          anchorable = document.attributes.fetch(ANCHORABLE_ATTRIBUTE, Set.new)
          inventory.key?(target) && !anchored?(document, target) &&
            !anchorable.member?(target)
        end

        def anchored?(document, target)
          document.catalog[:refs].key?("section-#{target}")
        end

        def plain_text(parent, text, target)
          text.to_s.strip.empty? ? parent.sub_specialchars(target) : text
        end

        def reference_text(parent, text, target, name)
          return text unless name && (text.to_s.strip.empty? || text == target)

          parent.sub_specialchars(name)
        end
      end
    end
  end
end
