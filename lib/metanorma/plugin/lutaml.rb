# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      autoload :Liquid, "metanorma/plugin/lutaml/liquid"
      autoload :XmiCache, "metanorma/plugin/lutaml/xmi_cache"
      autoload :XmiConfig, "metanorma/plugin/lutaml/xmi_config"
      autoload :XmiContextBuilder, "metanorma/plugin/lutaml/xmi_context_builder"
      autoload :XmiPackageFilter, "metanorma/plugin/lutaml/xmi_package_filter"
      autoload :XmiRenderer, "metanorma/plugin/lutaml/xmi_renderer"
    end
  end
end
