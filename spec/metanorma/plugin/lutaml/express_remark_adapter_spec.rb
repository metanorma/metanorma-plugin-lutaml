# frozen_string_literal: true

require "spec_helper"
require "expressir"
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
    it "decorates remarks on the model" do
      schema = Expressir::Model::Declarations::Schema.new(
        id: "test_schema",
        remarks: ["original remark"],
      )
      allow(schema).to receive(:children).and_return([])

      described_class.for(schema).decorate_remarks(
        { "relative_path_prefix" => "/some/path" },
      )

      expect(schema.remarks).to eq(["original remark"])
    end

    it "decorates remark_items on models that include HasRemarkItems" do
      entity = Expressir::Model::Declarations::Entity.new(
        id: "test_entity",
        remarks: [],
      )
      ri = Expressir::Model::Declarations::RemarkItem.new(
        remarks: ["original"],
      )
      allow(entity).to receive_messages(remark_items: [ri], children: [])

      described_class.for(entity).decorate_remarks(
        { "remark_format" => "prefix" },
      )

      expect(ri.remarks).not_to be_empty
    end

    it "does not raise when a RemarkItem appears in children" do
      schema = Expressir::Model::Declarations::Schema.new(
        id: "test_schema",
        remarks: [],
      )
      remark_item = Expressir::Model::Declarations::RemarkItem.new(
        remarks: ["some remark"],
      )
      allow(schema).to receive(:children).and_return([remark_item])

      expect do
        described_class.for(schema).decorate_remarks({})
      end.not_to raise_error
    end
  end
end
