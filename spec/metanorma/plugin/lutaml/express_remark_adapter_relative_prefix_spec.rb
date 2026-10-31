# frozen_string_literal: true

require "spec_helper"
require "expressir"
require_relative "../../../../lib/metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  describe ".relative_path_prefix" do
    # The prefix lands inside emitted image macros. metanorma resolves
    # image targets through AsciiDoc's base-dir asset path (the working
    # directory), not the docfile: collection renders and CLI compiles run
    # from other directories, and docfile-relative targets unresolve
    # there, failing every schema figure with "Image not found"
    # (metanorma-plugin-lutaml#329). The prefix must stay absolute; the
    # machine-path-free emission attempted in #325 needs metanorma-side
    # asset-resolution changes first.
    let(:docfile_directory) { "/build/one/doc" }
    let(:schema_directory) { "/build/one/schemas" }

    let(:path_resolver) do
      Class.new do
        def system_path(path, _base) = path
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

    let(:document) do
      document_class.new(
        { "docfile" => File.join(docfile_directory, "test.adoc") },
        path_resolver,
      )
    end

    let(:model_class) do
      Struct.new(:file)
    end

    let(:model) do
      model_class.new(File.join(schema_directory, "schema_a.exp"))
    end

    it "returns an absolute path to the schema directory" do
      prefix = described_class.relative_path_prefix(
        { "document" => document }, model
      )

      # File.expand_path is idempotent only on absolute paths, so this
      # asserts absoluteness portably
      expect(File.expand_path(prefix)).to eq(prefix)
      expect(File.expand_path(prefix))
        .to eq(File.expand_path(schema_directory))
    end

    it "returns nil without a document" do
      expect(described_class.relative_path_prefix({}, model)).to be_nil
    end
  end
end
