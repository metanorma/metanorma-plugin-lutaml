# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "liquid"
require "asciidoctor"
require "metanorma/plugin/lutaml/express_remark_adapter"
require "metanorma/plugin/lutaml/express_schema_listing"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressSchemaListing do
  describe ".fence_length" do
    # The fence must exceed every dash run at line start in the content
    # (asciidoctor closes a listing only on a dash line of the SAME
    # length as its opening fence) while staying a valid listing fence.
    it "is four dashes when the content carries no dash run" do
      expect(described_class.fence_length("plain\ncontent")).to eq(4)
    end

    it "stays a valid listing fence over a two-dash run" do
      expect(described_class.fence_length("a\n--\nb")).to eq(4)
    end

    it "exceeds a four-dash run by one" do
      expect(described_class.fence_length("a\n----\nb")).to eq(5)
    end

    it "exceeds the longest run by one" do
      expect(described_class.fence_length("a\n----\nb\n-----\nc")).to eq(6)
    end

    it "ignores dash runs that do not start the line" do
      expect(described_class.fence_length("a\n  ----\nb")).to eq(4)
    end

    it "counts a dash run with trailing text" do
      expect(described_class.fence_length("----trail")).to eq(5)
    end
  end

  describe ".extract_expressg_figures" do
    it "passes content without an EXPRESS-G remark through unchanged" do
      stripped, figures = described_class
        .extract_expressg_figures("SCHEMA s;\nEND_SCHEMA;")

      expect(stripped).to eq("SCHEMA s;\nEND_SCHEMA;")
      expect(figures).to be_empty
    end

    it "lifts the whole remark out and keeps the figure body" do
      content = <<~ADOC
        ENTITY point;
        END_ENTITY;

        (*"s.__expressg"
        [[expg_1]]
        [.svgmap]
        ====
        image::diag1.svg[]
        ====
        *)
        END_SCHEMA;
      ADOC

      stripped, figures = described_class.extract_expressg_figures(content)

      expect(stripped).to eq("ENTITY point;\nEND_ENTITY;\nEND_SCHEMA;\n")
      expect(figures)
        .to eq(["[[expg_1]]\n[.svgmap]\n====\nimage::diag1.svg[]\n===="])
    end

    it "keeps every diagram of a remark carrying several in one body" do
      content = <<~ADOC
        (*"s.__expressg"
        [.svgmap]
        ====
        image::one.svg[]
        ====

        [.svgmap]
        ====
        image::two.svg[]
        ====
        *)
        END_SCHEMA;
      ADOC

      _stripped, figures = described_class.extract_expressg_figures(content)

      expect(figures.length).to eq(1)
      expect(figures[0]).to include("one.svg")
      expect(figures[0]).to include("two.svg")
    end

    it "dedents the figure body, keeping relative indentation" do
      content = <<~ADOC
        ENTITY point;
        END_ENTITY;

        (*"s.__expressg"
          [[expg_1]]
          [.svgmap]
          ====
            image::nested.svg[]
          ====
        *)
        END_SCHEMA;
      ADOC

      _stripped, figures = described_class.extract_expressg_figures(content)

      expect(figures)
        .to eq(["[[expg_1]]\n[.svgmap]\n====\n  image::nested.svg[]\n===="])
    end

    it "removes only the remark matched, not lookalike prose" do
      content = "(*\"s\"\nprose about __expressg stays\n*)\nEND_SCHEMA;\n"

      stripped, figures = described_class.extract_expressg_figures(content)

      expect(stripped).to eq(content)
      expect(figures).to be_empty
    end
  end

  describe "the liquid drop method" do
    # The listing is a COMPLETE block: heading, computed fence, the
    # schema's rendered source (with the schema prose spliced in by the
    # adapter) and the same fence — so no dash run inside remark prose
    # can close the listing early (43 of the 125 SRL schema listings
    # close early under the templates' hardcoded two-dash fence).
    let(:schema_directory) { Dir.mktmpdir }
    let(:schema_file) { File.join(schema_directory, "listing_schema.exp") }
    let(:document) do
      document_class.new(
        { "docfile" => File.join(Dir.mktmpdir, "page.adoc") },
        path_resolver,
      )
    end
    let(:path_resolver) do
      Class.new do
        def system_path(path, base) = File.expand_path(path, base)
      end.new
    end
    let(:document_class) do
      Class.new do
        attr_reader :attributes, :path_resolver

        def initialize(attributes, path_resolver)
          @attributes = attributes
          @path_resolver = path_resolver
        end
      end
    end

    def write_schema_file(source)
      File.write(schema_file, source)
    end

    # One parse, decorated once: every listing view works on the same
    # schema instance the decoration stashed its values on. Without a
    # document there is no imagesdir to emit attribute entries for, so
    # the listing is the pure block.
    def decorated_schema(options = {})
      repository = Expressir::Express::Parser.from_file(schema_file)
      described_class.apply
      Metanorma::Plugin::Lutaml::ExpressRemarkAdapter
        .for(repository).decorate_remarks({ "document" => options[:document] })
      repository.schemas.first
    end

    context "with remark prose carrying dash runs" do
      let(:schema) do
        write_schema_file(<<~EXP)
          SCHEMA listing_schema;

          (*"listing_schema"
          Intro prose.

          ----
          dashed block
          ----

          More prose.
          *)

          ENTITY thing;
            name : STRING;
          END_ENTITY;

          END_SCHEMA;
        EXP
        decorated_schema
      end

      it "emits the source heading with a computed fence" do
        lines = listing_of(schema).split("\n")

        expect(lines[0]).to eq('[source%unnumbered,subs="+macros"]')
        expect(lines[1]).to eq("-----")
      end

      it "closes with the same fence it opened" do
        lines = listing_of(schema).split("\n")

        expect(lines[1]).to eq(lines[-1])
      end

      it "never produces a fence that appears in the content" do
        lines = listing_of(schema).split("\n")
        fence = lines[1]
        closing = lines.rindex(fence)
        content = lines[2...closing]

        expect(fence.length)
          .to eq(described_class.fence_length(content.join("\n")))
        expect(content).not_to include(fence)
        expect(lines[(closing + 1)..]).not_to include(fence)
      end

      it "keeps the whole content inside one listing under asciidoctor" do
        html = Asciidoctor.convert(
          listing_of(schema), header_footer: false, standalone: false
        )
        listings = html.scan(/<pre[^>]*><code>(.*?)<\/code><\/pre>/m)

        expect(listings.length).to eq(1)
        expect(listings[0][0]).to include("dashed block")
        expect(listings[0][0]).to include("More prose.")
      end

      it "renders the same block through a liquid template" do
        listing = listing_of(schema)
        template = Liquid::Template
          .parse("{{ schema.formatted_hyperlinked_adoc_listing }}")

        expect(template.render("schema" => schema.to_liquid)).to eq(listing)
      end

      it "prints the schema prose exactly once" do
        expect(listing_of(schema).scan('(*"listing_schema"').length)
          .to eq(1)
      end
    end

    context "with an EXPRESS-G remark carrying svgmap figures" do
      let(:schema) do
        write_schema_file(<<~EXP)
          SCHEMA listing_schema;

          (*"listing_schema"
          Schema prose.
          *)

          ENTITY point;
            x : INTEGER;
          END_ENTITY;

          ENTITY circle;
            centre : point;
          END_ENTITY;

          (*"listing_schema.__expressg"
          [[expg_listing_schema_1]]
          [.svgmap]
          ====
          image::diag1.svg[]

          * <<listing_schema.point>>; 1
          * <<listing_schema.circle>>; 2
          ====
          *)
          END_SCHEMA;
        EXP
        decorated_schema
      end

      it "keeps the EXPRESS source, not the figures, inside the listing" do
        lines = listing_of(schema).split("\n")
        closing = lines.rindex(lines[1])
        inside = lines[2...closing]

        expect(inside.join("\n")).to include("END_SCHEMA")
        expect(inside.join("\n")).to include("ENTITY point;")
        expect(inside.join("\n")).to include('(*"listing_schema"')
        expect(inside.join("\n")).not_to include("[.svgmap]")
        expect(inside.join("\n")).not_to include("image::diag1.svg")
        expect(inside.join("\n")).not_to include("__expressg")
      end

      it "emits the figure blocks after the closing fence" do
        lines = listing_of(schema).split("\n")
        closing = lines.rindex(lines[1])
        after = lines[(closing + 1)..].join("\n")

        expect(after).to include("[[expg_listing_schema_1]]")
        expect(after).to include("[.svgmap]")
        expect(after).to include("image::diag1.svg[]")
        expect(after).to include("<<listing_schema.point>>; 1")
      end

      it "renders the figures as images under asciidoctor" do
        html = Asciidoctor.convert(
          listing_of(schema), header_footer: false, standalone: false
        )
        listings = html.scan(/<pre[^>]*><code>(.*?)<\/code><\/pre>/m)

        expect(listings.length).to eq(1)
        expect(listings[0][0]).to include("END_SCHEMA")
        expect(html).to include('<img src="diag1.svg"')
        expect(html).to include("svgmap")
        expect(html).not_to include("image::")
        expect(html).not_to include("====")
      end
    end

    context "with an EXPRESS-G figure and imagesdir entries stashed" do
      let(:schema) do
        write_schema_file(<<~EXP)
          SCHEMA listing_schema;
          ENTITY point;
            x : INTEGER;
          END_ENTITY;

          (*"listing_schema.__expressg"
          [.svgmap]
          ====
          image::diag1.svg[]
          ====
          *)
          END_SCHEMA;
        EXP
        document.attributes["imagesdir"] = "author-images"
        File.write(File.join(schema_directory, "diag1.svg"), "<svg/>")
        decorated_schema(document: document)
      end

      it "emits the figures inside the schema's imagesdir entries" do
        lines = listing_of(schema).split("\n")

        expect(lines[0])
          .to eq(":imagesdir: #{File.expand_path(schema_directory)}")
        expect(lines[-1]).to eq(":imagesdir: author-images")
        expect(lines).to include("image::diag1.svg[]")
        expect(lines.index("image::diag1.svg[]")).to be < lines.length - 2
      end

      it "resolves the figure image through the imagesdir entries" do
        # A real schema page carries a section heading before the listing;
        # a document cannot start on an attribute entry.
        html = Asciidoctor.convert(
          "== listing_schema\n\n#{listing_of(schema)}",
          header_footer: false, standalone: false,
        )

        expect(html).to include(
          %(<img src="#{File.expand_path(schema_directory)}/diag1.svg"),
        )
      end
    end

    context "with imagesdir values stashed by decoration" do
      let(:schema) do
        write_schema_file(<<~EXP)
          SCHEMA listing_schema;
          ENTITY thing;
            name : STRING;
          END_ENTITY;
          END_SCHEMA;
        EXP
        document.attributes["imagesdir"] = "author-images"
        decorated_schema(document: document)
      end

      it "wraps the block in imagesdir attribute entries" do
        lines = listing_of(schema).split("\n")

        expect(lines[0])
          .to eq(":imagesdir: #{File.expand_path(schema_directory)}")
        expect(lines[1]).to eq("")
        expect(lines[-2]).to eq("")
        expect(lines[-1]).to eq(":imagesdir: author-images")
      end
    end

    context "without an imagesdir (no document, undecorated schema)" do
      it "emits the pure block without attribute entries" do
        write_schema_file(<<~EXP)
          SCHEMA listing_schema;
          ENTITY thing;
            name : STRING;
          END_ENTITY;
          END_SCHEMA;
        EXP
        repository = Expressir::Express::Parser.from_file(schema_file)
        described_class.apply

        listing = repository.schemas.first.to_liquid
          .formatted_hyperlinked_adoc_listing

        expect(listing).not_to include(":imagesdir:")
        expect(listing.split("\n")[0])
          .to eq('[source%unnumbered,subs="+macros"]')
      end
    end

    private

    def listing_of(schema)
      schema.to_liquid.formatted_hyperlinked_adoc_listing
    end
  end
end
