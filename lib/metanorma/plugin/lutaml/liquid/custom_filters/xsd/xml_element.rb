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
          end
        end
      end
    end
  end
end
