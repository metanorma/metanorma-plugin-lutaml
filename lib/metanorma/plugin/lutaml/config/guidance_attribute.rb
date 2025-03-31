# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class GuidanceAttribute < ::Lutaml::Model::Serializable
          attribute :name, :string
          attribute :used, :boolean
          attribute :guidance, :string

          yaml do
            map "name", to: :name
            map "used", to: :used
            map "guidance", to: :guidance
          end
        end
      end
    end
  end
end
