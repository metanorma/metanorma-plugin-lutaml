# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class Package < ::Lutaml::Model::Serializable
          attribute :name, :string
          attribute :skip_tables, :string, collection: true
          attribute :render_entities, :string, collection: true

          yaml do
            map "name", to: :name
            map "skip_tables", to: :skip_tables
            map "render_entities", to: :render_entities
          end
        end
      end
    end
  end
end
