# frozen_string_literal: true

class KlassTableContentDrop < Liquid::Drop
  def initialize(content) # rubocop:disable Lint/MissingSuper
    @content = content
  end

  def owned_props
    @content[:owned_props]
  end

  def assoc_props
    @content[:assoc_props]
  end

  def inherited_props
    @content[:inherited_props]
  end

  def inherited_assoc_props
    @content[:inherited_assoc_props]
  end
end
