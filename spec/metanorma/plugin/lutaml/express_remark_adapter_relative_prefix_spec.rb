# frozen_string_literal: true

require "spec_helper"
require "expressir"
require_relative "../../../../lib/metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  describe ".relative_path_prefix" do
    # The prefix lands inside emitted image macros: an absolute build path
    # made image/@src differ between two builds of the same tree
    # (metanorma/metanorma-plugin-lutaml#325). It must be relative to the
    # docfile directory.
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

    it "returns a path relative to the docfile directory" do
      prefix = described_class.relative_path_prefix(
        { "document" => document }, model,
      )

      expect(prefix).to eq("../schemas")
      expect(File.expand_path(prefix, docfile_directory)).to eq(schema_directory)
    end

    it "returns nil without a document" do
      expect(described_class.relative_path_prefix({}, model)).to be_nil
    end
  end
end
