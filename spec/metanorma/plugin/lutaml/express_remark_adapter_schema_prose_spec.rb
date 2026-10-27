# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require_relative "../../../../lib/metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  # iso-10303#720: a bare (*"Schema_name" ...*) remark is the schema-level
  # prose. expressir models it in Schema#remarks, and renders that walk
  # remark_items dropped it from clause 4. The adapter promotes it to a
  # leading RemarkItem keyed by the schema path.
  let(:tempfile) do
    f = Tempfile.new(["schema_prose", ".exp"])
    f.write(<<~EXP)
      SCHEMA schema_prose;

      (*"schema_prose"
      A mesh is defined by its vertices and the connections between the
      vertices.
      *)

      (*"schema_prose.__identifier"
      WG12 N0000
      *)

      ENTITY thing;
        name : STRING;
      END_ENTITY;

      END_SCHEMA;
    EXP
    f.close
    f
  end

  let(:schema) do
    Expressir::Express::Parser.from_files([tempfile.path]).schemas.first
  end

  it "keeps the schema-level prose in Schema#remarks" do
    expect(schema.remarks.join).to include("vertices and the connections")
  end

  it "does not expose it as a RemarkItem before decoration" do
    expect(schema.remark_items.map(&:id)).not_to include("schema_prose")
  end

  it "promotes the prose to a leading RemarkItem when decorated" do
    described_class.for(schema).decorate_remarks(
      { "document" => nil, "relative_path_prefix" => Dir.tmpdir },
    )

    first = schema.remark_items.first
    expect(first.id).to eq("schema_prose")
    expect(first.remarks.join).to include("vertices and the connections")
    expect(schema.remark_items.length).to eq(2)
  end

  it "does not promote twice" do
    options = { "document" => nil, "relative_path_prefix" => Dir.tmpdir }
    described_class.for(schema).decorate_remarks(options)
    count = schema.remark_items.length

    described_class.for(schema).decorate_remarks(options)
    expect(schema.remark_items.length).to eq(count)
  end
end
