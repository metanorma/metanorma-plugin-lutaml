module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module Xsd
          module CustomFilters
            def to_xml_representation(element, skip_rendering = nil)
              element.instance_variable_get(:@object).to_formatted_xml(
                except: Array(skip_rendering&.to_sym),
              )
            end
          end
        end
      end
    end
  end
end
