# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"
require "metanorma/plugin/lutaml/express_schema_listing"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  # The schema's imagesdir is its source directory resolved the way the
  # document resolves referenced paths (PathResolver#system_path against
  # the docfile directory): image macros in the schema's remarks then
  # resolve as written, replacing the retired in-text path rewriting
  # whose absolute results leaked the build directory into published
  # pages (TRThurman's source-fidelity requirement).
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
      { "docfile" => File.join(docfile_directory, "test.adoc") },
      path_resolver,
    )
  end

  let(:docfile_directory) { File.expand_path("/build/one/doc") }
  let(:schema_directory) { File.expand_path("/build/one/schemas") }

  let(:model_class) do
    Struct.new(:file)
  end

  let(:model) do
    model_class.new(File.join(schema_directory, "schema_a.exp"))
  end

  def write_schema(directory, id)
    file = File.join(directory, "#{id}.exp")
    File.write(file, <<~EXP)
      SCHEMA #{id};
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      END_SCHEMA;
    EXP
    file
  end

  describe ".schema_imagesdir" do
    it "returns the schema directory as the document resolves it" do
      dir = described_class.schema_imagesdir(
        { "document" => document }, model
      )

      expect(dir).to eq(File.expand_path(schema_directory))
    end

    it "returns nil without a document" do
      expect(described_class.schema_imagesdir({}, model)).to be_nil
    end

    it "returns nil without a schema file" do
      model = model_class.new(nil)

      expect(
        described_class.schema_imagesdir({ "document" => document }, model),
      ).to be_nil
    end
  end

  describe "imagesdir on decoration" do
    let(:schema_directory) { Dir.mktmpdir }
    let(:schema_file) { write_schema(schema_directory, "schema_a") }
    let(:repository) { Expressir::Express::Parser.from_file(schema_file) }

    def decorate(repo, document)
      described_class.for(repo).decorate_remarks({ "document" => document })
    end

    # Decoration never touches the document's imagesdir (#371): the
    # document-level value belongs to the author and outside tooling;
    # the plugin stages figures itself and emits static targets.
    it "leaves the document imagesdir unset for a single-schema repository" do
      decorate(repository, document)

      expect(document.attributes["imagesdir"]).to be_nil
    end

    it "leaves the document imagesdir unset when the directory is shared" do
      other = write_schema(schema_directory, "schema_b")
      repository = Expressir::Express::Parser.from_files(
        [schema_file, other],
      )
      decorate(repository, document)

      expect(document.attributes["imagesdir"]).to be_nil
    end

    it "does not set a document-level imagesdir across directories" do
      other_directory = Dir.mktmpdir
      repository = Expressir::Express::Parser.from_files(
        [schema_file, write_schema(other_directory, "schema_c")],
      )
      decorate(repository, document)

      expect(document.attributes["imagesdir"]).to be_nil
    end

    it "does not override an imagesdir the document already carries" do
      document.attributes["imagesdir"] = "author-images"
      decorate(repository, document)

      expect(document.attributes["imagesdir"]).to eq("author-images")
    end
  end
end
