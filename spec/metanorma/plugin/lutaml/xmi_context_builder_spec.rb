# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/extensions"
require "liquid"
require "metanorma/plugin/lutaml/xmi_context_builder"
require "metanorma/plugin/lutaml/xmi_model_reference"

RSpec.describe Metanorma::Plugin::Lutaml::XmiContextBuilder do
  def render_override(target, label = "Hidden")
    builder = Object.new.extend(described_class)
    options = Struct.new(:external_classes, :skip_unrecognized_connector)
      .new({ "Hidden" => target }, false)
    package = Struct.new(:name).new("Package")
    contexts = builder.create_default_context_object(
      "context", package, {}, options
    )
    Liquid::Template.parse(
      "<<{{ context.additional_context.external_classes.Hidden }},#{label}>>",
    ).render!(contexts)
  end

  def convert(source)
    registry = Asciidoctor::Extensions.create
    registry.preprocessor do
      process do |document, reader|
        Metanorma::Plugin::Lutaml::XmiModelReference.register(
          document, { "hidden" => "Hidden" }
        )
        reader
      end
    end
    Asciidoctor.convert(source, extension_registry: registry, safe: :safe)
  end

  it "visits each nested package once even with flattened descendants" do
    package_type = Struct.new(:xmi_id, :name, :children, :visits) do
      def packages
        self.visits += 1
        children
      end

      def children_packages
        children.flat_map { |child| [child, *child.children_packages] }
      end
    end
    packages = Array.new(12) do |index|
      package_type.new(index.to_s, "Package #{index}", [], 0)
    end
    packages.each_cons(2) { |parent, child| parent.children << child }
    builder = Object.new.extend(described_class)
    expect(builder.model_packages(packages.first)).to eq(packages)
    expect(packages.map(&:visits)).to eq([1] * packages.size)
  end

  it "preserves an explicit override to an absent internal model anchor" do
    output = convert(render_override("section-hidden"))
    expect(output).to include('href="#section-hidden">Hidden</a>')
  end

  it "preserves internal anchors containing dots" do
    output = convert(render_override("glossary.hidden"))
    expect(output).to include('href="#glossary.hidden">Hidden</a>')
  end

  it "preserves labels containing equals signs and square brackets" do
    output = convert(render_override("glossary-hidden", "Mode = Hidden [x]"))
    expect(output).to include(
      'href="#glossary-hidden">Mode = Hidden [x]</a>',
    )
  end

  it "preserves references to another document's fragment" do
    output = convert(render_override("other.adoc#hidden"))
    expect(output).to include('href="other.html#hidden">Hidden</a>')
  end

  it "preserves natural references to a section title" do
    output = convert(<<~ADOC)
      #{render_override('Human title')}

      == Human title

      Text.
    ADOC
    expect(output).to include('href="#_human_title">Hidden</a>')
  end

  it "preserves natural section-title references starting with section-" do
    output = convert(<<~ADOC)
      #{render_override('section-Reference types')}

      == section-Reference types

      Text.
    ADOC
    expect(output).to include('href="#_section_reference_types">Hidden</a>')
  end

  it "keeps overrides local to each macro's Liquid context" do
    source = [render_override("section-first"),
              render_override("section-second")].join("\n\n")
    output = convert(source)
    expect(output).to include('href="#section-first">Hidden</a>')
    expect(output).to include('href="#section-second">Hidden</a>')
  end

  it "preserves disabled and non-string mapping values" do
    original = { "Disabled" => nil, "Off" => false, "Numeric" => 123 }
    actual = Object.new.extend(described_class)
      .external_model_targets(original)
    expect(actual).to eq(original)
  end

  it "does not mutate the caller's external mapping" do
    original = { "Hidden" => "section-hidden" }
    Object.new.extend(described_class).external_model_targets(original)
    expect(original).to eq("Hidden" => "section-hidden")
  end

  it "leaves literal and escaped examples unchanged with overrides" do
    source = <<~'ADOC'
      \<<section-hidden,Hidden>>

      ----
      <<section-hidden,Hidden>>
      ----
    ADOC
    output = convert("#{render_override('section-hidden')}\n\n#{source}")
    expect(output.scan("&lt;&lt;section-hidden,Hidden&gt;&gt;").length).to eq(2)
    expect(output).to include('href="#section-hidden">Hidden</a>')
  end
end
