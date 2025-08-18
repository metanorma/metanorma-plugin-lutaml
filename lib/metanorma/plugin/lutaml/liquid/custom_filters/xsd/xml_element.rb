module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def child_elements(schema, element)
              objects = resolved_element_order(resolve_complex_type(element, schema))
              objects.filter_map do |object|
                if object.respond_to?(:element)
                  object.element
                elsif object.is_a?(::Lutaml::Xsd::SimpleContent::SimpleContentDrop)
                  (object.restriction || object.extension).base
                end
              end.flatten
            end

            def attributes_xml_representation_for(object)
              case object
              when ::Lutaml::Xsd::AttributeGroup::AttributeGroupDrop
                %( ref="#{object.ref}")
              when ::Lutaml::Xsd::Attribute::AttributeDrop
                attr_attrs(object)
              when ::Lutaml::Xsd::Sequence::SequenceDrop
                sequence_attrs(object)
              when ::Lutaml::Xsd::Element::ElementDrop
                element_attrs(object)
              when ::Lutaml::Xsd::Any::AnyDrop
                any_attrs(object).map { |key, value| %( #{key}="#{value}") }.join
              end
            end

            def simple_content_children(object)
              return unless object.is_a?(::Lutaml::Xsd::SimpleContent::SimpleContentDrop)

              tag_name = object.extension ? "extension" : "restriction"
              [
                xsd_open_tag(tag_name, { base: object.public_send(tag_name).base }),
                resolved_element_order(instance).map { |child| "  #{simple_content_child(child)}" },
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
              return object if object.is_a?(::Lutaml::Xsd::ComplexType::ComplexTypeDrop)

              complex_type(schema, object)
            end

            def simple_content_child(child)
              case child
              when ::Lutaml::Xsd::Attribute::AttributeDrop
                xsd_open_tag("attribute", attr_attrs_hash(child), closed: true)
              when ::Lutaml::Xsd::AttributeGroup::AttributeGroupDrop
                xsd_open_tag("attributeGroup", { ref: child.ref }, closed: true)
              end
            end

            def xsd_open_tag(tag_name, attributes = {}, closed: false)
              attrs = attributes.map { |k, v| %(#{k}="#{v}") }.join(" ")
              %(<xsd:#{tag_name} #{attrs}#{"/" if closed}>)
            end

            def attr_attrs(object)
              attr_attrs_hash(object).map do |key, value|
                %( #{key}="#{value}")
              end.join
            end

            def attr_attrs_hash(object)
              attrs = {}
              attrs[:ref] = object.ref if object.ref
              attrs[:name] = object.name if object.name
              attrs[:type] = object.type if object.type
              attrs[:fixed] = object.fixed if object.fixed
              attrs[:use] = object.use if object.use
              attrs[:default] = object.default if object.default
              attrs
            end

            def sequence_attrs(object)
              min_occurs = %( minOccurs="#{object.min_occurs}") if object.min_occurs
              max_occurs = %( maxOccurs="#{object.max_occurs}") if object.max_occurs
              %(#{min_occurs}#{max_occurs})
            end

            def element_attrs(object)
              ref = %( ref="#{object.ref}") if object.ref
              name = %( name="#{object.name}") if object.name
              type = %( type="#{object.type}") if object.type
              min_occurs = %( minOccurs="#{object.min_occurs}") if object.min_occurs
              max_occurs = %( maxOccurs="#{object.max_occurs}") if object.max_occurs
              %(#{ref}#{name}#{type}#{min_occurs}#{max_occurs}")
            end

            def any_attrs(object)
              attrs = {}
              attrs[:id] = object.id if object.id
              attrs[:namespace] = object.namespace if object.namespace
              attrs[:processContents] = object.process_contents if object.process_contents
              attrs[:minOccurs] = object.min_occurs if object.min_occurs
              attrs[:maxOccurs] = object.max_occurs if object.max_occurs
              attrs
            end
          end
        end
      end
    end
  end
end
