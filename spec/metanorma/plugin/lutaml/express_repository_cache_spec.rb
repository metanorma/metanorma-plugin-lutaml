# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "expressir"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRepositoryCache do
  let(:dir) { Dir.mktmpdir("mpl-express-cache") }

  let(:alpha_body) do
    <<~EXP
      SCHEMA alpha;
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      END_SCHEMA;
    EXP
  end

  let(:beta_body) do
    <<~EXP
      SCHEMA beta;
      USE FROM alpha (thing);
      ENTITY widget;
        part : thing;
      END_ENTITY;
      END_SCHEMA;
    EXP
  end

  let(:alpha_path) { File.join(dir, "alpha.exp") }
  let(:beta_path) { File.join(dir, "beta.exp") }
  let(:index_path) { File.join(dir, "index.yaml") }

  let(:document) do
    doc = Asciidoctor::Document.new
    doc.attributes["docfile"] = File.join(dir, "document.adoc")
    doc
  end

  before do
    described_class.clear
    write_fixtures(alpha_body)
  end

  after do
    described_class.clear
    FileUtils.remove_entry(dir)
  end

  def load_index
    Metanorma::Plugin::Lutaml::Utils.load_express_repositories(
      path: index_path, cache_path: nil, document: document,
    )
  end

  def write_fixtures(alpha_body)
    File.write(alpha_path, alpha_body)
    File.write(beta_path, beta_body)
    File.write(index_path, <<~YAML)
      schemas:
        alpha:
          path: alpha.exp
        beta:
          path: beta.exp
    YAML
  end

  describe ".source_key" do
    it "is stable for the same sources" do
      key = described_class.source_key([alpha_path, beta_path])
      again = described_class.source_key(%W[#{alpha_path} #{beta_path}])

      expect(again).to eq(key)
    end

    it "changes when a source's content changes" do
      original = described_class.source_key([alpha_path, beta_path])
      File.write(
        alpha_path, alpha_body.sub("name : STRING;", "title : STRING;")
      )

      expect(described_class.source_key([alpha_path, beta_path]))
        .not_to eq(original)
    end

    it "changes with the source order" do
      forward = described_class.source_key([alpha_path, beta_path])
      backward = described_class.source_key([beta_path, alpha_path])

      expect(backward).not_to eq(forward)
    end

    it "changes with the source path" do
      copy_path = File.join(dir, "alpha_copy.exp")
      FileUtils.cp(alpha_path, copy_path)

      expect(described_class.source_key([copy_path]))
        .not_to eq(described_class.source_key([alpha_path]))
    end
  end

  describe ".file_key" do
    let(:cached_path) { File.join(dir, "repo.cache") }

    it "is stable for an unchanged file" do
      File.write(cached_path, "one")
      first = described_class.file_key(cached_path)

      expect(described_class.file_key(cached_path)).to eq(first)
    end

    it "changes when the file is rewritten" do
      File.write(cached_path, "one")
      first = described_class.file_key(cached_path)
      FileUtils.rm(cached_path)
      File.write(cached_path, "entirely different and longer content")

      expect(described_class.file_key(cached_path)).not_to eq(first)
    end
  end

  describe ".fetch_or_store" do
    it "parses once for repeated keys and hands back the same object" do
      key = described_class.source_key([alpha_path, beta_path])
      parses = 0

      first = described_class.fetch_or_store(key) do
        parses += 1
        Expressir::Express::Parser.from_files([alpha_path, beta_path])
      end
      second = described_class.fetch_or_store(key) do
        parses += 1
        Expressir::Express::Parser.from_files([alpha_path, beta_path])
      end

      expect(parses).to eq(1)
      expect(second).to be(first)
    end

    it "runs the block again for a new key" do
      parses = 0
      alpha_only = described_class.source_key([alpha_path])
      both = described_class.source_key([alpha_path, beta_path])

      described_class.fetch_or_store(alpha_only) do
        parses += 1
        Expressir::Express::Parser.from_files([alpha_path])
      end
      changed = described_class.fetch_or_store(both) do
        parses += 1
        Expressir::Express::Parser.from_files([alpha_path, beta_path])
      end

      expect(parses).to eq(2)
      expect(changed.schemas.map(&:id)).to contain_exactly("alpha", "beta")
    end
  end

  context "when a schema index is loaded twice" do
    it "returns the same parsed repository for the same sources" do
      first = load_index
      second = load_index

      expect(first).to be_a(Expressir::Model::Repository)
      expect(second).to be(first)
      expect(first.schemas.map(&:id)).to contain_exactly("alpha", "beta")
    end

    it "re-parses when a source changes" do
      original = load_index

      extended_body = alpha_body.sub(
        "END_ENTITY;",
        "END_ENTITY;\nENTITY extra;\n  code : STRING;\nEND_ENTITY;",
      )
      write_fixtures(extended_body)
      reloaded = load_index

      expect(reloaded).not_to be(original)
      entity_ids = reloaded.schemas.flat_map { |s| s.entities.map(&:id) }
      expect(entity_ids).to include("extra")
    end
  end

  context "when a schema folder is loaded twice" do
    it "returns the same parsed repository" do
      utils = Metanorma::Plugin::Lutaml::Utils
      first = utils.load_express_repositories(
        path: dir, cache_path: nil, document: document,
      )
      second = utils.load_express_repositories(
        path: dir, cache_path: nil, document: document,
      )

      expect(second).to be(first)
    end
  end

  context "when a single .exp file is loaded through a macro" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:

        [lutaml_express_liquid,#{alpha_path},my_context]
        ----
        {% for schema in my_context.schemas %}
        == {{ schema.id }}
        {% endfor %}
        ----
      TEXT
    end

    it "shares the parse through the process-wide cache" do
      metanorma_convert(input)

      cached = described_class.fetch(described_class.source_key([alpha_path]))
      expect(cached).to be_a(Expressir::Model::ExpFile)
    end
  end

  context "when a compiled-set artifact is loaded twice" do
    before do
      skip "native extension not compiled" unless
        Expressir::Express::Core::NATIVE_AVAILABLE
    end

    it "returns the same lazy repository handle" do
      artifact_path = File.join(dir, "set.exscs")
      Expressir::Express::Parser.from_files(
        [alpha_path, beta_path], compiled_set: artifact_path
      )

      utils = Metanorma::Plugin::Lutaml::Utils
      first = utils.load_express_repositories(
        path: artifact_path, cache_path: nil, document: document,
      )
      second = utils.load_express_repositories(
        path: artifact_path, cache_path: nil, document: document,
      )

      expect(first).to be_a(Expressir::Express::LazyRepository)
      expect(second).to be(first)
    end
  end

  context "when the per-document cache flush runs" do
    it "keeps the parsed repositories so collection documents share them" do
      first = load_index

      Metanorma::Plugin::Lutaml::CacheRegistry.clear_all

      expect(load_index).to be(first)
    end
  end
end
