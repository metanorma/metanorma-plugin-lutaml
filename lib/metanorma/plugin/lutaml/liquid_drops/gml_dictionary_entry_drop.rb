# frozen_string_literal: true

require "ogc/gml/dictionary"

class GmlDictionaryEntryDrop < Liquid::Drop
  def initialize(dict_entry) # rubocop:disable Lint/MissingSuper
    @dict_entry = dict_entry
  end

  def name
    @dict_entry.definition.name.first.content
  end

  def description
    @dict_entry.definition.description
  end
end
