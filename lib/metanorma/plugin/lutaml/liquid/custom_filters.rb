require "reverse_adoc"

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
          def html2asciidoc(input)
            ReverseAdoc.convert(input)
          end
        end
      end
    end
  end
end
