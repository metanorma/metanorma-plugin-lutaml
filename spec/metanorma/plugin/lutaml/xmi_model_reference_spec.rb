# frozen_string_literal: true

require "asciidoctor"
require "asciidoctor/extensions"
require "metanorma/plugin/lutaml/xmi_model_reference"

RSpec.describe Metanorma::Plugin::Lutaml::XmiModelReference do
  def convert(source, inventories = [
    { "hidden" => "Hidden", "present" => "Present" },
  ])
    processor = described_class
    registry = Asciidoctor::Extensions.create
    registry.preprocessor do
      process do |document, reader|
        inventories.each { |inventory| processor.register(document, inventory) }
        reader
      end
    end
    Asciidoctor.convert(source, extension_registry: registry, safe: :safe)
  end

  it "drops absent model links while preserving explicit labels" do
    output = convert("See <<section-hidden,*Custom label*>>.")
    expect(output).to include("<strong>Custom label</strong>")
    expect(output).not_to include("href=")
  end

  it "uses the model name for empty or whitespace-only labels" do
    output = convert("<<section-hidden,>> <<section-hidden, >>")
    expect(output).to include("Hidden Hidden")
    expect(output).not_to include("href=")
  end

  it "preserves forward links to anchors in actual custom output" do
    output = convert(<<~ADOC)
      See <<section-present,Present>>.

      [[section-present]]
      == Custom heading

      Text.
    ADOC
    expect(output).to include('href="#section-present"')
  end

  it "merges inventories supplied by later macro expansions" do
    output = convert("<<section-later>> <<section-hidden>>", [
                       { "hidden" => "Hidden" }, { "later" => "Later" }
                     ])
    expect(output).to include("Later Hidden")
    expect(output).not_to include("href=")
  end

  it "escapes fallback names and handles adjacent bare references separately" do
    output = convert("<<section-a>><<section-b>>", [
                       { "a" => "A < B", "b" => "C & D" },
                     ])
    expect(output).to include("A &lt; BC &amp; D")
    expect(output).not_to include("href=")
  end

  it "renders XMI targets with no defining model as text" do
    output = convert("<<section-undefined,Label>> <<section-undefined>>",
                     [{ "undefined" => nil }])
    expect(output).to include("Label undefined")
    expect(output).not_to include("href=")
  end

  it "keeps links to undefined XMI targets that have actual anchors" do
    output = convert(<<~ADOC, [{ "undefined" => nil }])
      See <<section-undefined,Label>>.

      [[section-undefined]]
      == Heading
    ADOC
    expect(output).to include('href="#section-undefined"')
  end

  it "keeps a model name when a later macro only references the id" do
    output = convert("<<section-hidden>>", [
                       { "hidden" => "Hidden" }, { "hidden" => nil }
                     ])
    expect(output).to include("Hidden")
  end

  it "leaves explicit external mappings to inventory ids linked" do
    output = convert("<<#section-hidden,Mapped>>\n\n[[section-hidden]]\n== H")
    expect(output).to include('href="#section-hidden"')
  end

  it "preserves unrelated references" do
    expect(convert("<<section-other,Other>>"))
      .to include('href="#section-other"')
  end

  it "leaves escaped references and literal examples alone" do
    output = convert(<<~'ADOC')
      \<<section-hidden,Hidden>>

      ----
      <<section-hidden,Hidden>>
      ----
    ADOC
    expect(output.scan("&lt;&lt;section-hidden,Hidden&gt;&gt;").length).to eq(2)
    expect(output).not_to include("href=")
  end

  it "resolves table references against later document anchors" do
    output = convert(<<~ADOC)
      [cols="a"]
      |===
      |See <<section-present,Present>> and <<section-hidden,Hidden>>.
      |===

      [[section-present]]
      == Present

      Text.
    ADOC
    expect(output).to include('href="#section-present"')
    expect(output).not_to include('href="#section-hidden"')
  end

  it "finds anchors emitted inside table cells" do
    output = convert(<<~ADOC)
      See <<section-present,Present>>.

      [cols="a"]
      |===
      |[[section-present]]
      Present definition
      |===
    ADOC
    expect(output).to include('href="#section-present"')
  end

  it "does not carry inventories into other documents" do
    convert("<<section-hidden,Hidden>>")
    expect(convert("<<section-hidden,Hidden>>", []))
      .to include('href="#section-hidden"')
  end
end
