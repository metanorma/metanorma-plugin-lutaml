# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        autoload :CustomBlocks, "metanorma/plugin/lutaml/liquid/custom_blocks"
        autoload :CustomFilters, "metanorma/plugin/lutaml/liquid/custom_filters"
        autoload :LocalFileSystem,
                 "metanorma/plugin/lutaml/liquid/multiply_local_file_system"
      end
    end
  end
end
