# frozen_string_literal: true

require "expressir"

module Metanorma
  module Plugin
    module Lutaml
      # Expressir 2.4.32's Ruby builder nests explicit, derived and inverse
      # attribute lists. Flatten before remark attachment invokes the formatter.
      module ExpressEntityAttributes
        def call(ast_data)
          entity = super
          entity.attributes = entity.attributes.flatten if entity&.attributes
          entity
        end
      end
    end
  end
end

if defined?(Expressir::Express::Builders::EntityDeclBuilder)
  Expressir::Express::Builders::EntityDeclBuilder.prepend(
    Metanorma::Plugin::Lutaml::ExpressEntityAttributes,
  )
end
