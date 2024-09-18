require "coradoc"
require "coradoc/input/html"

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
          def html2adoc(input)
            Coradoc::Input::HTML.convert(input)
          end

          def interpolate(input)
            sub = ::Liquid::Template.parse(input)
            sub.render(@context)
          end

          def identify(input)
            input.split(/(?=[A-Z])/).map(&:downcase).join("-")
          end
        end
      end
    end
  end
end
