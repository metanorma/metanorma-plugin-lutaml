# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/extensions"
require "metanorma/plugin/lutaml/xmi_renderer"
require "metanorma/plugin/lutaml/xmi_model_reference"

RSpec.describe Metanorma::Plugin::Lutaml::XmiRenderer do
  def convert_override(anchor, label)
    renderer = Object.new.extend(described_class)
    context = {
      "model_anchors" => { "hidden" => "Hidden" },
      "external_classes" => { "Hidden" => anchor },
    }
    source = renderer.normalize_model_xrefs(
      "<<section-hidden,#{label}>>", context
    )
    registry = Asciidoctor::Extensions.create
    registry.preprocessor do
      process do |document, reader|
        Metanorma::Plugin::Lutaml::XmiModelReference.register(
          document, context["model_anchors"]
        )
        reader
      end
    end
    Asciidoctor.convert(source, extension_registry: registry, safe: :safe)
  end

  it "preserves an explicit override to an absent internal model anchor" do
    output = convert_override("section-hidden", "Hidden")
    expect(output).to include('href="#section-hidden">Hidden</a>')
  end

  it "preserves internal anchors containing dots" do
    output = convert_override("glossary.hidden", "Hidden")
    expect(output).to include('href="#glossary.hidden">Hidden</a>')
  end

  it "preserves labels containing equals signs and square brackets" do
    output = convert_override("glossary-hidden", "Mode = Hidden [x]")
    expect(output).to include(
      'href="#glossary-hidden">Mode = Hidden [x]</a>',
    )
  end

  it "preserves references to another document's fragment" do
    output = convert_override("other.adoc#hidden", "Hidden")
    expect(output).to include('href="other.html#hidden">Hidden</a>')
  end
end
