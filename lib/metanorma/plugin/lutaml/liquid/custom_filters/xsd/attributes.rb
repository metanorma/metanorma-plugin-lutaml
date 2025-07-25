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
              complex_type.attribute
                .concat(groups_attributes(schema, complex_type.attribute_group))
                .concat(simple_content_attributes(complex_type.simple_content, schema))
                .flatten
                .compact
            end

            def xml_representations(attr_instances, schema)
              attr_instances.map.with_index(1) do |attribute, index|
                attr = attr_instance(schema, attribute) || attribute
                %(\n #{attr_name(attr)}="#{attr_type(attr)}" [#{min_max_arg(attr)}]#{"\n" if index == attr_instances.count})
              end
            end

            def groups_attributes(schema, groups)
              groups.map do |group|
                group = schema.attribute_group.find { |g| g.name == group.ref } if group.ref
                group.attribute
              end
            end

            private

            def simple_content_attributes(simple_content, schema)
              resolved_element_order(simple_content).filter_map.with_object([]) do |object, array|
                array.concat(object.attribute) if object.respond_to?(:attribute)
                array.concat(groups_attributes(schema, object.attribute_group)) if object.respond_to?(:attribute_group)
              end
            end

            def complex_type(schema, element)
              schema.complex_type.find do |complex_type|
                complex_type.name == element.type
              end
            end

            def min_max_arg(attr)
              case attr.use
              when "optional" then "0..1"
              when "required" then "1"
              end
            end

            def attr_name(attr)
              attr.name || attr.ref
            end

            def attr_type(attr)
              return attr.fixed if attr.fixed
              return if attr.ref
              return attr.type if attr.type

              simple_type = attr.simple_type
              if union = simple_type.union
                %(union of: [ #{union_str(union)} ])
              elsif restriction = simple_type.restriction
                restriction_str(restriction)
              end
            end

            def union_str(union)
              simple_type = union.simple_type
              restrictions = simple_type.map { |st| restriction_str(st.restriction) }
              %(#{union.member_types}, [ #{restrictions.join(", ")} ])
            end

            def restriction_str(restriction)
              if restriction.enumeration
                %(#{restriction.base} (value comes from list: {'#{restriction.enumeration.map(&:value).join("'|'")}'}))
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
