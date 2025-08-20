module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def child_elements(schema, element)
              complex_type = resolve_complex_type(element, schema)
              resolved_element_order(complex_type).filter_map do |object|
                if object.respond_to?(:element)
                  object.element
                elsif object.is_a?(::Lutaml::Xsd::SimpleContent::SimpleContentDrop)
                  (object.restriction || object.extension).base
                end
              end.flatten
            end

            def attributes_xml_representation_for(object)
              attrs = case drop_class_name(object)
                      when "attribute_group" then { ref: object.ref }
                      when "attribute" then attribute_attrs(object)
                      when "sequence" then sequence_attrs(object)
                      when "element" then element_attrs(object)
                      when "any" then any_attrs(object)
                      else {}
                      end
              attr_to_str(attrs)
            end

            def simple_content_children(object)
              return unless object.is_a?(::Lutaml::Xsd::SimpleContent::SimpleContentDrop)

              tag_name = object.extension ? "extension" : "restriction"
              children = resolved_element_order(instance).map do |child|
                "  #{simple_content_child(child)}"
              end
              base_attr = { base: object.public_send(tag_name).base }
              [
                xsd_open_tag(tag_name, base_attr),
                children,
                "</xsd:#{tag_name}>",
              ].flatten
            end

            def cardinality_representation(element)
              max = case element.max_occurs
                    when "unbounded"
                      "*"
                    else
                      element.max_occurs&.to_i || 1
                    end
              min = element.min_occurs&.to_i || 1
              "[#{min}..#{max}]"
            end

            private

            def resolve_complex_type(object, schema)
              if object.is_a?(::Lutaml::Xsd::ComplexType::ComplexTypeDrop)
                object
              else
                complex_type(schema, object)
              end
            end

            def simple_content_child(child)
              case child
              when ::Lutaml::Xsd::Attribute::AttributeDrop
                xsd_open_tag("attribute", attribute_attrs(child), closed: true)
              when ::Lutaml::Xsd::AttributeGroup::AttributeGroupDrop
                xsd_open_tag("attributeGroup", { ref: child.ref }, closed: true)
              end
            end

            def xsd_open_tag(tag_name, attributes = {}, closed: false)
              attrs = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
              %(<xsd:#{tag_name} #{attrs}#{'/' if closed}>)
            end

            def attr_to_str(attrs)
              attrs.map { |key, value| %( #{key}="#{value}") }.join
            end

            def sequence_attrs(object)
              {
                minOccurs: object.min_occurs,
                maxOccurs: object.max_occurs,
              }.compact
            end

            def attribute_attrs(object)
              {
                ref: object.ref,
                name: object.name,
                type: object.type,
                fixed: object.fixed,
                use: object.use,
                default: object.default,
              }.compact
            end

            def element_attrs(object)
              {
                ref: object.ref,
                name: object.name,
                type: object.type,
                minOccurs: object.min_occurs,
                maxOccurs: object.max_occurs,
              }.compact
            end

            def any_attrs(object)
              {
                id: object.id,
                namespace: object.namespace,
                processContents: object.process_contents,
                minOccurs: object.min_occurs,
                maxOccurs: object.max_occurs,
              }.compact
            end
          end
        end
      end
    end
  end
end
