# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module CacheRegistry
        def self.xmi_cache
          XmiCache::XMI_PARSE_CACHE
        end

        def self.xsd_cache
          LutamlXsdPreprocessor::CACHE
        end

        def self.clear_all
          xmi_cache.clear
          xsd_cache.clear
        end
      end
    end
  end
end
