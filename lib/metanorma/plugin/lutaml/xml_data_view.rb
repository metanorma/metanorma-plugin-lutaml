# frozen_string_literal: true

require "liquid"

module Metanorma
  module Plugin
    module Lutaml
      # What Liquid sees of a model bound from XML. An optional element with
      # a single occurrence is nil when absent (never an empty Array, which
      # Liquid treats as true), a name the schema does not declare is an
      # error, a structure cannot be printed, and text that would read as an
      # AsciiDoc preprocessor directive when the rendered output is parsed
      # again is neutralised.
      module XmlDataView
        DIRECTIVE =
          /(?:\A|(?<=[\r\n]))\\?(include|embed|ifdef|ifndef|ifeval|endif)::/i

        # Added to every generated model class so that Liquid reaches the
        # model through its view, however the template was started.
        module Model
          def to_liquid
            ModelDrop.new(self)
          end
        end

        module_function

        def neutralise(text)
          text.gsub(DIRECTIVE) { "#{Regexp.last_match(1)}&#58;:" }
        end

        def present(value, attribute)
          return present_item(value) unless value.is_a?(Array)
          return nil if value.empty? && single?(attribute)

          value.map { |item| present_item(item) }
        end

        def present_item(value)
          case value
          when ::Lutaml::Model::Serializable then value.to_liquid
          when String then neutralise(value)
          else value
          end
        end

        # An element that may occur once keeps the list shape the compiler
        # gives it, but absent it is nil: an empty Array is true in Liquid.
        def single?(attribute)
          collection = attribute&.options&.fetch(:collection, nil)
          collection.is_a?(Range) && collection.end == 1
        end

        # Liquid drop over one generated model.
        class ModelDrop < ::Liquid::Drop
          def initialize(model)
            super()
            @model = model
          end

          def liquid_method_missing(name)
            key = name.to_s.to_sym
            attribute = attributes[key]
            return super unless attribute

            XmlDataView.present(@model.public_send(key), attribute)
          end

          def to_s
            return XmlDataView.neutralise(@model.content.to_s) if
              attributes.key?(:content)

            raise ::Liquid::Error,
                  "cannot print a structure with fields " \
                  "#{attributes.keys.join(', ')}; select one of its fields"
          end

          private

          def attributes
            @model.class.attributes
          end
        end
      end
    end
  end
end
