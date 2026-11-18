# frozen_string_literal: true

require "spec_helper"
require "asciidoctor"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"
require "metanorma/plugin/lutaml/express_remark_figures"
require "metanorma/plugin/lutaml/express_schema_listing"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkFigures do
  # The drop-class patch must exist before the first liquefaction of a
  # remark item: Liquid memoizes a drop class's invokable methods on
  # first render.
  before { described_class.apply }

  # The schema's imagesdir is its source directory resolved the way the
  # document resolves referenced paths.
  def path_resolver
    Class.new do
      def system_path(path, base) = File.expand_path(path, base)
    end.new
  end

  def document_class
    Class.new do
      attr_reader :attributes, :path_resolver

      def initialize(attributes, path_resolver)
        @attributes = attributes
        @path_resolver = path_resolver
      end
    end
  end

  let(:document) do
    document_class.new(
      { "docfile" => File.join(docfile_directory, "test.adoc"),
        "imagesdir" => imagesdir }.compact,
      path_resolver,
    )
  end

  let(:docfile_directory) { File.join(corpus_root, "documents", "part") }
  let(:imagesdir) { nil }
  let(:corpus_root) { Dir.mktmpdir }
  let(:schema_directory) { File.join(corpus_root, "schemas", "gizmo") }

  let(:diagram_name) { "gizmo_armexpg1.svg" }

  let(:schema_file) do
    FileUtils.mkdir_p(schema_directory)
    file = File.join(schema_directory, "gizmo_arm.exp")
    File.write(file, <<~EXP)
      SCHEMA gizmo_arm;
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      (*"gizmo_arm.__expressg"
      [[gizmo_arm_expg1]]
      [.svgmap]
      ====
      image::#{diagram_name}[]

      * <<express:gizmo>>; 1
      ====
      *)
      END_SCHEMA;
    EXP
    FileUtils.touch(File.join(schema_directory, diagram_name))
    file
  end

  let(:repository) { Expressir::Express::Parser.from_file(schema_file) }

  def decorate
    Metanorma::Plugin::Lutaml::ExpressRemarkAdapter.for(repository)
      .decorate_remarks({ "document" => document })
  end

  def decorated_schema
    decorate
    repository.schemas.first
  end

  def drop_facing_remarks(schema)
    schema.remark_items.flat_map(&:to_liquid).map(&:remarks).join("\n")
  end

  describe "drop-facing remark figures" do
    it "keeps bare figure macros as written and stages the figure into the default imagesdir" do
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
      expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
        .to be(true)
    end

    # Decoration itself stages: templates that print the remark item
    # verbatim ("{{ remark }}") never call the resolved accessor, so
    # the staged copy must exist by the time decoration completes.
    it "stages the figure eagerly, at decoration" do
      decorated_schema

      expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
        .to be(true)
    end

    it "composes targets through the document's imagesdir directory" do
      document.attributes["imagesdir"] = "images"
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
      expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
        .to be(true)
    end

    # The load-bearing property: asciidoctor joins an image target with
    # the document's imagesdir before resolution, so the emitted target
    # must land on the figure file once joined and cleaned.
    it "emits targets asciidoctor resolves back to the figure" do
      document.attributes["imagesdir"] = "images"
      schema = decorated_schema
      macro = drop_facing_remarks(schema)
        .each_line.find { |line| line.start_with?("image::") }
      bare = macro[/\Aimage::(.*?)\[\]/, 1]

      resolved = Asciidoctor::PathResolver.new.web_path(bare, "images")
      expect(File.expand_path(resolved, docfile_directory))
        .to eq(File.expand_path(File.join(docfile_directory, "images", diagram_name)))
    end

    it "keeps the printed source listing free of rewritten paths" do
      schema = decorated_schema

      expect(schema.formatted_hyperlinked_adoc)
        .to include("image::#{diagram_name}[]")
    end

    it "keeps the model remarks untouched" do
      schema = decorated_schema
      item = schema.remark_items.find { |ri| ri.id == "__expressg" }

      expect(item.remarks.join("\n")).to include("image::#{diagram_name}[]")
    end

    it "leaves macros of figures missing under the schema as written" do
      schema_file
      FileUtils.rm(File.join(schema_directory, diagram_name))
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
    end

    it "leaves absolute targets as written" do
      absolute = File.join(schema_directory, diagram_name)
      schema = rewrite_remarks_with("image::#{absolute}[]")

      expect(drop_facing_remarks(schema)).to include(
        "image::#{absolute}[]",
      )
    end

    it "leaves URL targets as written" do
      schema = rewrite_remarks_with("image::https://example.invalid/a.svg[]")

      expect(drop_facing_remarks(schema)).to include(
        "image::https://example.invalid/a.svg[]",
      )
    end

    it "passes undecorated remark items through unchanged" do
      undecorated = Expressir::Model::Declarations::RemarkItem.new(
        id: "plain", remarks: ["image::#{diagram_name}[]"],
      )

      expect(undecorated.to_liquid.remarks)
        .to eq(["image::#{diagram_name}[]"])
    end

    # Attribute entries apply at parse, after preprocessing, so the
    # imagesdir in force at the rendered macro comes from the source
    # lines the preprocessors scan.
    it "composes targets through the source-set imagesdir entry" do
      described_class
        .scan_source_imagesdir(document, [":imagesdir: images", ""])
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
      expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
        .to be(true)
    end

    it "prefers the source-set entry over the programmatic attribute" do
      document.attributes["imagesdir"] = "author-images"
      described_class.scan_source_imagesdir(
        document, [":imagesdir: images"]
      )
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
      expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
        .to be(true)
    end

    it "anchors targets at the docfile on an explicit source unset" do
      described_class.scan_source_imagesdir(
        document, [":imagesdir: images", "text", ":!imagesdir:"]
      )
      schema = decorated_schema

      expect(drop_facing_remarks(schema)).to include(
        "image::#{diagram_name}[]",
      )
    end
  end

  describe ".scan_source_imagesdir" do
    it "stashes the last entry's value" do
      described_class.scan_source_imagesdir(
        document, [":imagesdir: a", ":imagesdir:  images "]
      )

      expect(document.attributes["lutaml-source-imagesdir"]).to eq("images")
    end

    it "stashes the explicit unset as empty" do
      described_class.scan_source_imagesdir(document, [":!imagesdir:"])

      expect(document.attributes["lutaml-source-imagesdir"]).to eq("")
    end

    it "stashes nothing without an entry" do
      described_class.scan_source_imagesdir(document, ["plain text"])

      expect(document.attributes).not_to have_key("lutaml-source-imagesdir")
    end
  end

  describe ".apply" do
    it "is idempotent" do
      described_class.apply

      expect { described_class.apply }.not_to raise_error
    end
  end

  def rewrite_remarks_with(macro)
    item = decorated_schema.remark_items
      .find { |ri| ri.id == "__expressg" }
    item.remarks = [macro]
    decorated_schema
  end
end
