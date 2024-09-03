# frozen_string_literal: true

class KlassTableDrop < Liquid::Drop
  def initialize(klass) # rubocop:disable Lint/MissingSuper
    @klass = klass
  end

  def id
    @klass[:general_id]
  end

  def name
    @klass[:name]
  end

  def stereotype
    @klass[:stereotype]
  end

  def definition
    @klass[:definition]
  end

  def type
    @klass[:type]
  end

  def upper_klass
    @klass[:general_upper_klass]
  end

  def general
    KlassTableGeneralDrop.new(@klass[:general]) if @klass[:general]
  end

  def has_general?
    !!@klass[:general]
  end

  def attributes
    @klass[:general_attributes].map do |attr|
      KlassTableAttributeDrop.new(attr)
    end
  end
end
