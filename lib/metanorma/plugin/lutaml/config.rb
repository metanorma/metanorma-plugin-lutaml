# frozen_string_literal: true

require "yaml"
begin
  require "lutaml/uml"
rescue LoadError
end
require "lutaml/model"

module Metanorma
  module Plugin
    module Lutaml
      module Config
        autoload :Guidance, "metanorma/plugin/lutaml/config/guidance"
        autoload :GuidanceAttribute,
                 "metanorma/plugin/lutaml/config/guidance_attribute"
        autoload :GuidanceKlass, "metanorma/plugin/lutaml/config/guidance_klass"
        autoload :Package, "metanorma/plugin/lutaml/config/package"
        autoload :Root, "metanorma/plugin/lutaml/config/root"
      end
    end
  end
end
