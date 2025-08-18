module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            ELEMENT_ORDER_IGNORABLE = %w[import include].freeze
            TITLE_SUFFIX = {
              "element" => "element declaration",
              "complex_type" => "type definition"
            }.freeze

            def used_by(schema, instance)
              case instance
              when ::Lutaml::Xsd::Element::ElementDrop,
                   ::Lutaml::Xsd::AttributeGroup::AttributeGroupDrop
                used_by_complex_type(schema, instance)
              when ::Lutaml::Xsd::ComplexType::ComplexTypeDrop
                complex_type_used_by(schema, instance)
              end.map { |object| linkify_object(object) }
            end

            private

            def value_of(object)
              if object.respond_to?(:type) && object.type
                object.type
              elsif object.respond_to?(:ref) && object.ref
                object.ref
              end
            end

            def linkify_object(object)
              name = object.name
              id_prefix = id_prefix(object)
              href = %(href="##{id_prefix}_#{name}")
              title = %(title="Jump to '#{name}' #{TITLE_SUFFIX[id_prefix]}.")
              %(pass:[<a #{title} #{href}>#{name}</a>])
            end

            def id_prefix(object)
              ::Lutaml::Model::Utils.base_class_snake_case(object.class.name).delete_suffix("_drop")
            end

            def find_used_by(object, element)
              resolved_element_order(object).any? do |xml_element|
                if value_of(xml_element) == element.name
                  true
                else
                  find_used_by(xml_element, element)
                end
              end
            end

            def used_by_complex_type(schema, element)
              schema.complex_type.select { |complex_type| find_used_by(complex_type, element) }
            end

            def complex_type_used_by(schema, complex_type)
              used_by_elements = schema.element.select do |element|
                if element.type == complex_type.name
                  true
                else
                  find_used_by(element, complex_type)
                end
              end
              used_by_elements.concat(schema.group.select { |group| find_used_by(group, complex_type) })
              used_by_elements
            end

            def resolved_element_order(object)
              return [] if object.element_order.nil?

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
