# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/metanorma/plugin/lutaml/express_remarks_decorator"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarksDecorator do
  subject(:result) { described_class.call(remark, options) }

  # The prefix is docfile-relative, as produced by
  # ExpressRemarkAdapter.relative_path_prefix; the decorator joins it as
  # written. An emitted path must not carry the build directory (#325):
  # two builds of the same tree in two directories produce byte-identical
  # markup only when the paths stay relative to the docfile.
  let(:prefix) { "../../schemas" }
  let(:options) { { "relative_path_prefix" => prefix } }

  def prefixed_path(filename)
    File.join(prefix, filename)
  end

  describe "prefixing relative paths" do
    context "with image:: macro" do
      let(:remark) { "image::diagram.svg[]" }

      it "prefixes the path, keeping it docfile-relative" do
        expect(result).to eq("image::#{prefixed_path('diagram.svg')}[]")
      end
    end

    context "with image: inline macro" do
      let(:remark) { "image:photo.png[alt text]" }

      it "prefixes the path" do
        expect(result).to eq("image:#{prefixed_path('photo.png')}[alt text]")
      end
    end

    context "with link: macro" do
      let(:remark) { "link:details.html[Details]" }

      it "prefixes the path" do
        expect(result).to eq("link:#{prefixed_path('details.html')}[Details]")
      end
    end

    context "with include:: directive" do
      let(:remark) { "include::snippet.adoc[]" }

      it "prefixes the path" do
        expect(result).to eq("include::#{prefixed_path('snippet.adoc')}[]")
      end
    end

    context "with video:: macro" do
      let(:remark) { "video::demo.mp4[]" }

      it "prefixes the path" do
        expect(result).to eq("video::#{prefixed_path('demo.mp4')}[]")
      end
    end

    context "with audio:: macro" do
      let(:remark) { "audio::sound.mp3[]" }

      it "prefixes the path" do
        expect(result).to eq("audio::#{prefixed_path('sound.mp3')}[]")
      end
    end

    context "with paths containing subdirectories" do
      let(:remark) { "image::images/action_schemaexpg1.xml[]" }

      it "prefixes the path including subdirectory" do
        expect(result)
          .to eq("image::#{prefixed_path('images/action_schemaexpg1.xml')}[]")
      end
    end
  end

  describe "skipping absolute paths" do
    context "with http:// URL" do
      let(:remark) { "image::http://example.com/diagram.svg[]" }

      it "does not modify the path" do
        expect(result).to eq("image::http://example.com/diagram.svg[]")
      end
    end

    context "with https:// URL" do
      let(:remark) { "image::https://example.com/diagram.svg[]" }

      it "does not modify the path" do
        expect(result).to eq("image::https://example.com/diagram.svg[]")
      end
    end

    context "with file:/// URL" do
      let(:remark) { "image::file:///tmp/diagram.svg[]" }

      it "does not modify the path" do
        expect(result).to eq("image::file:///tmp/diagram.svg[]")
      end
    end

    context "with absolute Unix path" do
      let(:remark) { "image::/absolute/path/diagram.svg[]" }

      it "does not modify the path" do
        expect(result).to eq("image::/absolute/path/diagram.svg[]")
      end
    end

    context "with Windows path" do
      let(:remark) { "image::C:/Users/doc/diagram.svg[]" }

      it "does not modify the path" do
        expect(result).to eq("image::C:/Users/doc/diagram.svg[]")
      end
    end
  end

  describe "multi-line remarks" do
    context "with mixed absolute and relative paths" do
      let(:remark) do
        "See the diagram below:\nimage::local.svg[]\n" \
          "image::http://example.com/remote.svg[]\nimage::other.svg[]"
      end

      it "only prefixes relative paths" do
        expect(result).to eq(
          "See the diagram below:\n" \
          "image::#{prefixed_path('local.svg')}[]\n" \
          "image::http://example.com/remote.svg[]\n" \
          "image::#{prefixed_path('other.svg')}[]",
        )
      end
    end

    context "with non-macro lines" do
      let(:remark) do
        "This is a note.\nimage::diagram.svg[]\nEnd of note."
      end

      it "preserves non-macro lines unchanged" do
        expect(result).to eq(
          "This is a note.\n" \
          "image::#{prefixed_path('diagram.svg')}[]\n" \
          "End of note.",
        )
      end
    end
  end

  describe "idempotence across passes" do
    let(:remark) { "image::diagram.svg[]" }

    it "does not stack the prefix when already decorated" do
      once = described_class.call(remark, options)
      twice = described_class.call(once, options)
      expect(twice).to eq(once)
    end
  end

  describe "without relative_path_prefix option" do
    let(:remark) { "image::diagram.svg[]" }
    let(:options) { {} }

    it "returns the remark unchanged" do
      expect(result).to eq("image::diagram.svg[]")
    end
  end
end
