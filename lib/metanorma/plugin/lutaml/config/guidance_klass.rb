# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class GuidanceKlass < ::Lutaml::Model::Serializable
          attribute :name, :string
          attribute :attributes, GuidanceAttribute, collection: true,
                                                    initialize_empty: true

          yaml do
            map "name", to: :name
            map "attributes", to: :attributes
          end
        end
      end
    end
  end
end
