# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
          # Relative paths resolve against +parent_folder+ so existence
          # checks anchor at the same directory the file loads from
          # (metanorma#627); the default keeps working-directory behavior.
          def file_exist(path, parent_folder = ".")
            File.exist?(File.expand_path(path, parent_folder))
          end
        end
      end
    end
  end
end
