# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  # Re-decorating a schema for a second document must take effect in its
  # printed source: expressir memoizes each formatted form in an ivar on
  # first format, so without the decoration's memo reset a process that
  # renders several documents sharing one index keeps printing the first
  # document's resolution — its staging and figure targets (#381).
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

  def document_for(docroot)
    document_class.new(
      { "docfile" => File.join(docroot, "doc", "doc.adoc") },
      path_resolver,
    )
  end

  let(:root) { Dir.mktmpdir("memo-reset") }
  let(:doc_a) { document_for(File.join(root, "one")) }
  let(:doc_b) { document_for(File.join(root, "two")) }

  # One parsed model shared by both documents, located through a
  # docfile-relative path: document one's schemas carry the figure file,
  # document two's do not — so the two resolutions disagree and only the
  # second decoration's outcome proves the memo was reset.
  let(:schema_file) do
    dir = File.join(root, "one", "schemas")
    FileUtils.mkdir_p(File.join(dir, "images"))
    File.write(File.join(dir, "images", "fig1.svg"), "<svg xmlns=\"http://www.w3.org/2000/svg\"/>")
    file = File.join(dir, "schema_a.exp")
    File.write(file, <<~EXP)
      SCHEMA schema_a;
      (*"schema_a"
      The figure:
      image::images/fig1.svg[]
      *)
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      END_SCHEMA;
    EXP
    FileUtils.mkdir_p(File.join(root, "two", "schemas"))
    FileUtils.cp(file, File.join(root, "two", "schemas", "schema_a.exp"))
    Expressir::Express::Parser.from_file(file).schemas.first
  end

  let(:model) { schema_file }

  def options_for(document)
    { "document" => document }
  end

  after do
    FileUtils.rm_rf(root)
  end

  it "recomputes the formatted source after re-decoration for another document" do
    described_class.for(model).decorate_remarks(options_for(doc_a))
    first = model.formatted_hyperlinked_adoc
    expect(first).to include("image::fig1.svg[]")

    described_class.for(model).decorate_remarks(options_for(doc_b))
    second = model.formatted_hyperlinked_adoc

    # Document two's schemas carry no figure file: the re-decoration
    # must take effect — the stale first-document rewrite (the bare
    # target) is gone, replaced by the visible missing-figure error.
    expect(second).not_to include("image::fig1.svg[]")
    expect(second).to include("[EXPRESS-G figure error]")
  end
end
