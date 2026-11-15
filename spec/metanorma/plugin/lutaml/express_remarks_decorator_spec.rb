# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/metanorma/plugin/lutaml/express_remarks_decorator"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarksDecorator do
  subject(:result) { described_class.call(remark, options) }

  let(:prefix) { File.expand_path("/project/schemas") }
  let(:options) { { "relative_path_prefix" => prefix } }

  def expanded_path(filename)
    File.expand_path(File.join(prefix, filename))
  end

  describe "prefixing relative paths" do
    context "with image:: macro" do
      let(:remark) { "image::diagram.svg[]" }

      it "prefixes the path" do
        expect(result).to eq("image::#{expanded_path('diagram.svg')}[]")
      end
    end

    context "with a docfile-relative prefix" do
      let(:prefix) { "../../schemas/resources/action_schema" }
      let(:remark) { "image::diagram.svg[]" }
      let(:options) do
        { "relative_path_prefix" => prefix,
          "relative_path_base" => File.expand_path("/project/documents/iso-1") }
      end

      it "resolves the path against the docfile directory, not the CWD" do
        expect(result).to eq(
          "image::#{File.expand_path(
            File.join(prefix, 'diagram.svg'),
            File.expand_path('/project/documents/iso-1'),
          )}[]",
        )
      end
    end

    context "with image: inline macro" do
      let(:remark) { "image:photo.png[alt text]" }

      it "prefixes the path" do
        expect(result).to eq("image:#{expanded_path('photo.png')}[alt text]")
      end
    end

    context "with link: macro" do
      let(:remark) { "link:details.html[Details]" }

      it "prefixes the path" do
        expect(result).to eq("link:#{expanded_path('details.html')}[Details]")
      end
    end

    context "with include:: directive" do
      let(:remark) { "include::snippet.adoc[]" }

      it "prefixes the path" do
        expect(result).to eq("include::#{expanded_path('snippet.adoc')}[]")
      end
    end

    context "with video:: macro" do
      let(:remark) { "video::demo.mp4[]" }

      it "prefixes the path" do
        expect(result).to eq("video::#{expanded_path('demo.mp4')}[]")
      end
    end

    context "with audio:: macro" do
      let(:remark) { "audio::sound.mp3[]" }

      it "prefixes the path" do
        expect(result).to eq("audio::#{expanded_path('sound.mp3')}[]")
      end
    end

    context "with paths containing subdirectories" do
      let(:remark) { "image::images/action_schemaexpg1.xml[]" }

      it "prefixes the path including subdirectory" do
        expect(result)
          .to eq("image::#{expanded_path('images/action_schemaexpg1.xml')}[]")
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
          "image::#{expanded_path('local.svg')}[]\n" \
          "image::http://example.com/remote.svg[]\n" \
          "image::#{expanded_path('other.svg')}[]",
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
          "image::#{expanded_path('diagram.svg')}[]\n" \
          "End of note.",
        )
      end
    end
  end

  describe "without relative_path_prefix option" do
    let(:remark) { "image::diagram.svg[]" }
    let(:options) { {} }

    it "returns the remark unchanged" do
      expect(result).to eq("image::diagram.svg[]")
    end
  end
  describe "dangling list continuations" do
    context "with a continuation-attached image after a plain paragraph" do
      let(:remark) do
        <<~REMARK
          stem:[a_k] - the distance, given by
          +
          image::ak_positive_distance.gif[]
        REMARK
      end

      it "blanks the continuation and keeps the image as a block" do
        expect(result).to eq(
          "stem:[a_k] - the distance, given by\n" \
          "\n" \
          "image::#{expanded_path('ak_positive_distance.gif')}[]",
        )
      end

      it "is idempotent under re-decoration" do
        second = described_class.call(result, options)
        expect(second).to eq(result)
      end
    end

    context "with a continuation after a genuine list item" do
      let(:remark) do
        <<~REMARK
          - list entry
          +
          image::diagram.svg[]
        REMARK
      end

      it "keeps the continuation" do
        expect(result).to eq(
          "- list entry\n" \
          "+\n" \
          "image::#{expanded_path('diagram.svg')}[]",
        )
      end
    end

    context "with a continuation before non-macro text" do
      let(:remark) do
        <<~REMARK
          some paragraph
          +
          plain continuation text
        REMARK
      end

      it "leaves the remark untouched" do
        expect(result).to eq("some paragraph\n+\nplain continuation text")
      end
    end
  end
end
