module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def class_name_end_with(element, expected_type)
              element.class.name.include?(expected_type)
            end
          end
        end
      end
    end
  end
end
