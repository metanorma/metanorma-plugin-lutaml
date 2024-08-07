# frozen_string_literal: true

require "ogc/gml/dictionary"

class GmlDictionarySourceDrop < Liquid::Drop
  def initialize(source) # rubocop:disable Lint/MissingSuper
    @source = source
  end

  def value
    @source
  end
end
