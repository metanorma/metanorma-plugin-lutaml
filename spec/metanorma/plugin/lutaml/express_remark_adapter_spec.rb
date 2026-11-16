# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  describe ".for" do
    it "returns CachedRepoAdapter for Cache" do
      cache = Expressir::Model::Cache.new
      adapter = described_class.for(cache)
      expect(adapter).to be_a(described_class::CachedRepoAdapter)
    end

    it "returns RepoAdapter for Repository" do
      repo = Expressir::Model::Repository.new
      adapter = described_class.for(repo)
      expect(adapter).to be_a(described_class::RepoAdapter)
    end

    it "returns RepoAdapter for ExpFile" do
      file = Expressir::Model::ExpFile.new
      adapter = described_class.for(file)
      expect(adapter).to be_a(described_class::RepoAdapter)
    end

    it "returns ModelAdapter for ModelElement" do
      schema = Expressir::Model::Declarations::Schema.new(id: "test")
      adapter = described_class.for(schema)
      expect(adapter).to be_a(described_class::ModelAdapter)
    end

    it "returns NullAdapter for unknown types" do
      adapter = described_class.for("string")
      expect(adapter).to be_a(described_class::NullAdapter)
    end
  end

  describe "CachedRepoAdapter#unwrap" do
    it "returns the cache content" do
      repo = Expressir::Model::Repository.new
      cache = Expressir::Model::Cache.new
      allow(cache).to receive(:content).and_return(repo)

      adapter = described_class.for(cache)
      expect(adapter.unwrap).to eq(repo)
    end
  end

  describe "RepoAdapter#unwrap" do
    it "returns the repository itself" do
      repo = Expressir::Model::Repository.new
      adapter = described_class.for(repo)
      expect(adapter.unwrap).to eq(repo)
    end
  end

  describe "NullAdapter" do
    it "returns nil for unwrap" do
      adapter = described_class.for("anything")
      expect(adapter.unwrap).to be_nil
    end

    it "does nothing for decorate_remarks" do
      adapter = described_class.for("anything")
      expect { adapter.decorate_remarks({}) }.not_to raise_error
    end
  end

  describe "ModelAdapter#decorate_remarks" do
    it "leaves remark text untouched (source fidelity)" do
      schema = Expressir::Model::Declarations::Schema.new(
        id: "test_schema",
        remarks: ["original remark"],
      )

      described_class.for(schema).decorate_remarks({})

      expect(schema.remarks).to eq(["original remark"])
    end

    it "leaves the remark items of child models untouched" do
      entity = Expressir::Model::Declarations::Entity.new(
        id: "test_entity",
        remarks: [],
      )
      ri = Expressir::Model::Declarations::RemarkItem.new(
        remarks: ["original"],
      )
      allow(entity).to receive(:remark_items).and_return([ri])

      described_class.for(entity).decorate_remarks({})

      expect(ri.remarks).to eq(["original"])
    end
  end

  describe "source fidelity of decorated remarks" do
    # Decoration used to rewrite remark text: absolute path expansion
    # into image macros (leaking the build directory into published
    # pages) and the 0.7.68/0.7.69 continuation passes, which blanked
    # legitimate interior `+` lines of list chains. It now rewrites
    # nothing; wrong `+` lines in sources are WG 12's to fix
    # (filings TCSC410303-3232/3233).
    let(:schema_directory) { Dir.mktmpdir }
    let(:schema_file) { File.join(schema_directory, "chain_schema.exp") }

    let(:schema) do
      Expressir::Express::Parser.from_file(schema_file).schemas.first
    end

    def decorate
      described_class.for(schema).decorate_remarks({})
    end

    context "with Tom's trial continuation chain" do
      # trial_continuation_chain.zip: a `. step one` item whose chain of
      # three images and two text paragraphs is legitimate asciidoctor
      # structure — the SRL corpus measured 11 interior `+` lines
      # blanked inside two such chains (kinematic_structure_schema.exp
      # lines 2405/2727), detaching 6 figures.
      let(:chain) do
        <<~REMARK
          The method is:

          . step one
          +
          image::first_image.gif[]
          +
          image::second_image.gif[]
          +
          text after the second image
          +
          image::third_image.gif[]
          +
          final text paragraph
        REMARK
      end

      before do
        File.write(schema_file, <<~EXP)
          SCHEMA chain_schema;

          (*"chain_schema"
          #{chain}*)

          ENTITY thing;
            name : STRING;
          END_ENTITY;

          END_SCHEMA;
        EXP
      end

      it "passes the chain through the decoration area unchanged" do
        decorate
        printed = schema.remarks.join

        expect(printed).to include(chain.chomp)
      end

      it "does not alter the remark array" do
        before = schema.remarks.dup
        decorate

        expect(schema.remarks).to eq(before)
      end
    end

    context "with relative image macro targets" do
      before do
        File.write(schema_file, <<~EXP)
          SCHEMA chain_schema;

          (*"chain_schema"
          The diagram:

          image::diagram.gif[]

          A linked document:

          link::details.html[Details]
          *)

          ENTITY thing;
            name : STRING;
          END_ENTITY;

          END_SCHEMA;
        EXP
      end

      it "keeps the macro targets relative" do
        decorate
        printed = schema.remarks.join

        expect(printed).to include("image::diagram.gif[]")
        expect(printed).to include("link::details.html[Details]")
        expect(printed).not_to include(Dir.tmpdir)
        expect(printed).not_to include(schema_directory)
      end
    end
  end
end
