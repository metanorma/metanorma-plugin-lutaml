# frozen_string_literal: true

class KlassTableAttributeDrop < Liquid::Drop
  LOWER_VALUE_MAPPINGS = {
    "C" => "0",
    "M" => "1",
  }.freeze

  def initialize(attr) # rubocop:disable Lint/MissingSuper
    @attr = attr
  end

  def id
    @attr[:id]
  end

  def name
    @attr[:name]
  end

  def type
    @attr[:type]
  end

  def xmi_id
    @attr[:xmi_id]
  end

  def is_derived
    @attr[:is_derived]
  end

  def cardinality
    min = @attr[:cardinality]["min"]
    min = min.nil? ? nil : LOWER_VALUE_MAPPINGS[min]

    "#{min}..#{@attr[:cardinality]['max']}"
  end

  def definition
    @attr[:definition]
  end

  def association
    @attr[:association]
  end

  def has_association?
    !!@attr[:association]
  end

  def upper_klass
    @attr[:upper_klass]
  end

  def type_ns
    @attr[:type_ns]
  end
end
