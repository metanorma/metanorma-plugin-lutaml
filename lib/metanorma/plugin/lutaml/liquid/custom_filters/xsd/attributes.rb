module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def attributes(schema, element)
              complex_type = case element
                             when ::Lutaml::Xsd::Element::ElementDrop
                               complex_type(schema, element)
                             when ::Lutaml::Xsd::ComplexType::ComplexTypeDrop
                               element
                             end
              [
                complex_type.attribute,
                groups_attributes(schema, complex_type.attribute_group),
                simple_content_attributes(complex_type.simple_content, schema),
              ].flatten.compact
            end

            def xml_representations(attr_instances, schema)
              attr_instances.map.with_index(1) do |attribute, index|
                attr = attr_instance(schema, attribute) || attribute
                name_value = %( #{attr_name(attr)}="#{attr_type(attr)}")
                min_max = %( [#{min_max_arg(attr)}])
                [
                  "\n",
                  name_value,
                  min_max,
                  ("\n" if index == attr_instances.count),
                ].compact.join
              end
            end

            def groups_attributes(schema, groups)
              attr_group = schema.attribute_group
              groups.flat_map do |group|
                group = attr_group.find { |g| g.name == group.ref } if group.ref

                group.attribute
              end
            end

            def min_max_arg(attr)
              case attr.use
              when "optional" then "0..1"
              when "required" then "1"
              end
            end

            def attr_type(attr)
              return if attr.ref
              return attr.fixed if attr.fixed
              return attr.type if attr.type

              simple_type = attr.simple_type
              if union = simple_type.union
                %(union of: [ #{union_str(union)} ])
              elsif restriction = simple_type.restriction
                restriction_str(restriction)
              end
            end

            private

            def simple_content_attributes(simple_content, schema)
              content = resolved_element_order(simple_content)
              content.each_with_object([]) do |object, array|
                array.concat(object.attribute) if object.respond_to?(:attribute)

                if object.respond_to?(:attribute_group)
                  array.concat(
                    groups_attributes(schema, object.attribute_group),
                  )
                end
              end
            end

            def complex_type(schema, element)
              schema.complex_type.find do |complex_type|
                complex_type.name == element.type
              end
            end

            def attr_name(attr)
              attr.name || attr.ref
            end

            def union_str(union)
              restrictions = union.simple_type.map do |st|
                restriction_str(st.restriction)
              end.join(", ")
              %(#{union.member_types}, [ #{restrictions} ])
            end

            def restriction_str(restriction)
              if restriction.enumeration
                enum_values = restriction.enumeration.map(&:value)
                values_str = %({'#{enum_values.join("'|'")}'})
                %(#{restriction.base} (value comes from list: #{values_str}))
              end
            end

            def attr_instance(schema, attribute)
              ref = attribute.ref
              return attribute if ref&.start_with?("xml:") || attribute.type

              schema.attribute.find { |attr| attr.name == ref }
            end
          end
        end
      end
    end
  end
end
