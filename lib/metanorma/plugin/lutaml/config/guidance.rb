# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class Guidance < ::Lutaml::Model::Serializable
          attribute :classes, GuidanceKlass, collection: true,
                                             initialize_empty: true

          yaml do
            map "classes", to: :classes
          end
        end
      end
    end
  end
end
