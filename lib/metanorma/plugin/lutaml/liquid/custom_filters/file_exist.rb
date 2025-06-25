module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
          def file_exist(path)
            File.exist?(path)
          end
        end
      end
    end
  end
end
