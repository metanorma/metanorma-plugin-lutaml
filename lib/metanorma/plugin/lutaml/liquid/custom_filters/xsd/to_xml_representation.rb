module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def to_xml_representation(element, skip_rendering = [])
              ruby_object(element).to_xml(except: Array(skip_rendering))
            end

            private

            def ruby_object(element)
              element.instance_variable_get(:@object)
            end
          end
        end
      end
    end
  end
end
