module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def resolved_element_order(object)
              return [] if object&.element_order.nil?

              object.element_order.each_with_object(object.element_order.dup) do |xml_element, array|
                if xml_element.text? || ELEMENT_ORDER_IGNORABLE.include?(xml_element.name)
                  next array.delete_if { |instance| instance == xml_element }
                end

                index = 0
                array.each_with_index do |element, i|
                  next unless element == xml_element

                  method_name = ::Lutaml::Model::Utils.snake_case(xml_element.name)
                  array[i] = Array(object.send(method_name))[index]
                  index += 1
                end
              end
            end
          end
        end
      end
    end
  end
end
