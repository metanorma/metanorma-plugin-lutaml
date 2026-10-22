# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class Guidance < ::Lutaml::Model::Serializable
          attribute :classes, GuidanceKlass, collection: true,
                                             initialize_empty: true
          attribute :data_types, GuidanceKlass, collection: true,
                                                initialize_empty: true

          yaml do
            map "classes", to: :classes
            map "data_types", to: :data_types
          end

          # Drops index into both keys (KlassDrop reads ["classes"],
          # DataTypeDrop reads ["data_types"]); empty collections are
          # omitted from as_yaml, so pin both keys here.
          def to_yaml_hash
            super.tap do |hash|
              hash["classes"] ||= []
              hash["data_types"] ||= []
            end
          end
        end
      end
    end
  end
end
