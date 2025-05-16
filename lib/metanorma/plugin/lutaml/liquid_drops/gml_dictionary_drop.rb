# frozen_string_literal: true

require "ogc/gml/dictionary"

class GmlDictionaryDrop < Liquid::Drop
  def initialize(dict) # rubocop:disable Lint/MissingSuper
    @dict = dict
  end

  def name
    @dict.name.join
  end

  def file_name
    "#{name}.xml"
  end

  def dictionary_entry
    @dict.dictionary_entry.map do |entry|
      GmlDictionaryEntryDrop.new(entry)
    end
  end
end
