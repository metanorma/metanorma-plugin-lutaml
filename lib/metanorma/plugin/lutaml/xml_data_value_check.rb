# frozen_string_literal: true

require "bigdecimal"
require "date"
require "set"
require "lutaml/model"

module Metanorma
  module Plugin
    module Lutaml
      # Compares every leaf value of a hydrated model with the text it came
      # from, so a value the type layer misread or dropped is reported
      # instead of bound. Values are paired by name; a typed value pairs with
      # a source text only when both denote the same number, date or boolean.
      class XmlDataValueCheck
        XSI_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance"
        CONTENT = "content"

        Source = Struct.new(:element, :text, :used)

        # Whether a typed value denotes what its lexical form says.
        module Equivalence
          INFINITIES = {
            "INF" => Float::INFINITY, "+INF" => Float::INFINITY,
            "-INF" => -Float::INFINITY
          }.freeze
          DECIMAL = /\A[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?\z/
          DATE = /\A-?\d{4,}-\d{2}-\d{2}/
          ZONE = /(?:Z|[+-]\d{2}:\d{2})\z/

          module_function

          def same?(value, text)
            case value
            when ::Time, ::DateTime then same_moment?(value, text)
            when ::Date then same_day?(value, text)
            when Float then same_float?(value, text)
            when Numeric then same_number?(value, text)
            else same_literal?(value, text)
            end
          end

          def same_number?(value, text)
            text.match?(DECIMAL) && BigDecimal(text) == value
          end

          def same_day?(value, text)
            text.match?(DATE) && value.iso8601 == text[0, 10]
          end

          def same_literal?(value, text)
            case value
            when true, false then %w[true 1].include?(text) == value
            else value.to_s.split == text.split
            end
          end

          def same_float?(value, text)
            expected = INFINITIES.fetch(text) do
              return false unless text.match?(DECIMAL)

              Float(text)
            end
            expected == value
          end

          # An xs:time has no date, so a moment bound from one invents it.
          def same_moment?(value, text)
            return false unless text.match?(DATE) && text.include?("T")

            if text.match?(ZONE)
              ::DateTime.iso8601(text).to_time == value.to_time
            else
              same_fields?(value, text)
            end
          rescue ArgumentError
            false
          end

          def same_fields?(value, text)
            value.strftime("%Y-%m-%dT%H:%M:%S") == text[0, 19] &&
              fraction(value) == fraction_of(text)
          end

          def fraction(value)
            value.respond_to?(:subsec) ? value.subsec : value.sec_fraction
          end

          def fraction_of(text)
            digits = text[/\A.{19}\.(\d+)/, 1]
            digits ? Rational(digits.to_i, 10**digits.size) : 0
          end
        end
        private_constant :Equivalence, :Source

        def initialize(instance,
                       register: ::Lutaml::Model::Config.default_register)
          @register = register
          @empty_elements = Set.new
          @sources = Hash.new { |hash, key| hash[key] = [] }
          instance.xpath("//*").each { |node| collect_sources(node) }
        end

        def check(model)
          values = collected(model)
          # Content is matched last: it shares source texts with named values.
          keys = values.keys.partition { |key| key != CONTENT }.flatten
          keys.each { |key| compare(key, values.fetch(key)) }
          @sources.each_value do |sources|
            lost = sources.find { |source| !source.used }
            fail_with(nil, lost) if lost
          end
        end

        private

        def collected(model)
          Hash.new { |hash, key| hash[key] = [] }.tap do |values|
            collect_values(model, values)
          end
        end

        def collect_sources(node)
          node.attribute_nodes.each do |attribute|
            next if attribute.namespace&.href == XSI_NAMESPACE

            add_source(attribute.name, node.name, attribute.value)
          end
          return unless node.element_children.empty?

          add_source(node.name, node.name, node.text, content: true)
          @empty_elements << key_for(node.name) if node.text.strip.empty?
        end

        def key_for(name)
          ::Lutaml::Model::Utils.snake_case(name)
        end

        # A leaf element binds under its own name, or as the content of a
        # simple-content model; one source text serves either.
        def add_source(name, element, text, content: false)
          return if text.strip.empty?

          source = Source.new(element, text.strip, false)
          @sources[key_for(name)] << source
          @sources[CONTENT] << source if content
        end

        def collect_values(object, values, key = "root")
          case object
          when Array
            object.each { |item| collect_values(item, values, key) }
          when ::Lutaml::Model::Serializable
            collect_members(object, values)
          else add_value(values, key, object)
          end
        end

        # A member still at its schema default had no source text to compare.
        def collect_members(object, values)
          object.class.attributes.each do |name, attribute|
            next if object.using_default?(name)

            value = object.public_send(name)
            reject_unbound_form(object, name, attribute, value)
            collect_values(value, values, name.to_s)
          end
        end

        def reject_unbound_form(object, name, attribute, value)
          items = Array(value)
          reject_lost_default(object, name, attribute, items)
          return unless boolean?(attribute)

          bad = items.find { |item| !item.nil? && item != true && item != false }
          return if bad.nil?

          raise XmlDataLoader::Error,
                "Value #{bad.inspect} of #{name} does not bind as a boolean"
        end

        # XSD gives an empty element its declared default; the binding does not.
        def reject_lost_default(object, name, attribute, items)
          return unless @empty_elements.include?(name.to_s)
          return unless attribute.default_set?(@register, object)
          return unless items.empty? || items.any? { |item| blank?(item) }

          raise XmlDataLoader::Error,
                "Empty element #{name} does not receive its schema default"
        end

        def boolean?(attribute)
          type = attribute.type(@register)
          type.is_a?(Class) && type <= ::Lutaml::Model::Type::Boolean
        end

        def blank?(item)
          item.nil? || (item.is_a?(String) && item.strip.empty?)
        end

        def add_value(values, key, object)
          values[key] << object unless object.is_a?(String) && blank?(object)
        end

        def compare(key, values)
          sources = @sources.fetch(key, [])
          sources.reject!(&:used)
          unmatched = values.compact.reject { |value| claim(sources, value) }
          return if unmatched.empty?

          fail_with(unmatched.first, sources.first)
        end

        # Values arrive in document order, so a match is usually the first
        # remaining source and removing it keeps the whole pass near linear.
        def claim(sources, value)
          index = sources.index { |item| Equivalence.same?(value, item.text) }
          return false unless index

          sources.delete_at(index).used = true
        end

        def fail_with(value, source)
          raise XmlDataLoader::Error, describe(value, source)
        end

        def describe(value, source)
          if value.nil?
            "Element #{source.element} value #{source.text.inspect} " \
              "was not bound"
          elsif source
            "Element #{source.element} value #{source.text.inspect} " \
              "binds as #{value.inspect}, which is not the same value"
          else
            "Value #{value.inspect} has no source text"
          end
        end
      end
    end
  end
end
