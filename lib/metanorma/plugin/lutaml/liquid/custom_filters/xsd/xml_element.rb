module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def child_elements(schema, element)
              objects = resolved_element_order(resolve_complex_type(element))
              objects.filter_map do |object|
                if object.respond_to?(:element)
                  object.element
                elsif object.is_a?(::Lutaml::Xsd::SimpleContent::SimpleContentDrop)
                  (object.restriction || object.extension).base
                end
              end.flatten
            end

            def element_representations(elements, schema)
              elements.map.with_index(1) do |element, index|
                element = schema.element.find { |e| e.name == element.name } unless element.instance_of?(::Lutaml::Xsd::Element::ElementDrop)
                %(\n <#{element.name} type="#{element.type}" [#{min_max_arg(element)}]#{"\n" if index == elements.count})
              end
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
              end
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

            def resolve_complex_type(object)
              return object if object.is_a?(::Lutaml::Xsd::ComplexType::ComplexTypeDrop)

              complex_type(object)
            end

            def attr_attrs(object)
              use = %( use="#{object.use}") if object.use
              if object.ref
                %( ref="#{object.ref}"#{use})
              elsif object.name
                fixed = %( fixed="#{object.fixed}") if object.fixed
                default = %( default="#{object.default}") if object.default
                %( name="#{object.name}" type="#{object.type}"#{use}#{fixed}#{default})
              end
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
          end
        end
      end
    end
  end
end
