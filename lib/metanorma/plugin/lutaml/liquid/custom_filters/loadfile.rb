require_relative "../../content"

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
          include ::Metanorma::Plugin::Lutaml::Content

          def loadfile(path, parent_folder = ".")
            resolved_file_path = File.expand_path(path, parent_folder)
            load_content_from_file(resolved_file_path)
          end
        end
      end
    end
  end
end
