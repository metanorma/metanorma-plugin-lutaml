module Metanorma
  module Plugin
    module Lutaml
      # Helpers for lutaml macroses
      module Utils
        module_function

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || "."
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end
      end
    end
  end
end