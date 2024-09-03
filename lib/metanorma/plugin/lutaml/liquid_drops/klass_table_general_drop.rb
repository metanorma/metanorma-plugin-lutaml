# frozen_string_literal: true

class KlassTableGeneralDrop < Liquid::Drop
  def initialize(gen) # rubocop:disable Lint/MissingSuper
    @gen = gen
  end

  def id
    @gen[:general_id]
  end

  def name
    @gen[:general_name]
  end

  def upper_klass
    @gen[:general_upper_klass]
  end

  def general
    KlassTableGeneralDrop.new(@gen[:general]) if @gen[:general]
  end

  def has_general?
    !!@gen[:general]
  end

  def attributes
    @gen[:general_attributes].map do |attr|
      KlassTableAttributeDrop.new(attr)
    end
  end
end
