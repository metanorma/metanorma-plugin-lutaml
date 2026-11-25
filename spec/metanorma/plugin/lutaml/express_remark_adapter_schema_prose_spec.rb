# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  # iso-10303#720: a bare (*"Schema_name" ...*) remark is the schema-level
  # prose. expressir models it in Schema#remarks, and renders that walk
  # remark_items dropped it from clause 4. The adapter promotes it to a
  # leading RemarkItem keyed by the schema path, keeps that item out of
  # the three source formats (the templates depend on the promoted item;
  # the hiding prevents double-printing under expressir >= 2.4.59 which
  # formats remark_items), and then splices the prose into those formats
  # in its standard position: right after the SCHEMA line, printed once
  # and as written (TRThurman's source-fidelity requirement — 117 of the
  # 125 SRL schemas carry schema-level prose that printed nowhere).
  # On expressir >= 2.4.8x the remark walk moved to ExpFile/RemarkInfo
  # (lutaml/expressir#777) and the formats print the schema-level item
  # themselves at the schema tail; the splicer's exclusion no longer
  # takes effect there and the output stands as printed (ProseSplicer's
  # documented fallback), so the canonical position is the tail.
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

  def decorate
    described_class.for(schema).decorate_remarks({ "document" => nil })
  end

  it "keeps the schema-level prose in Schema#remarks" do
    expect(schema.remarks.join).to include("vertices and the connections")
  end

  it "does not expose it as a RemarkItem before decoration" do
    expect(schema.remark_items.map(&:id)).not_to include("schema_prose")
  end

  it "promotes the prose to a leading RemarkItem when decorated" do
    decorate

    first = schema.remark_items.first
    expect(first.id).to eq("schema_prose")
    expect(first.remarks.join).to include("vertices and the connections")
    expect(schema.remark_items.length).to eq(2)
  end

  it "does not promote twice" do
    decorate
    count = schema.remark_items.length

    decorate
    expect(schema.remark_items.length).to eq(count)
  end

  %i[formatted formatted_hyperlinked formatted_hyperlinked_adoc].each do |fmt|
    it "prints the prose exactly once in Schema##{fmt}" do
      decorate

      printed = schema.public_send(fmt)
      expect(printed.scan('(*"schema_prose"').length).to eq(1)
      expect(printed).to include("vertices and the connections")
    end

    it "prints the prose at the schema tail in Schema##{fmt}" do
      decorate

      expect(schema.public_send(fmt)).to match(
        /\(\*"schema_prose"\nA mesh is defined by its vertices.*\*\)\nEND_SCHEMA;\z/m,
      )
    end

    it "prints the prose block in the exact remark-item shape in #{fmt}" do
      decorate

      item = schema.remark_items.first
      block = Expressir::Express::Formatter.format(item)

      expect(schema.public_send(fmt)).to include(block)
    end

    it "is stable across repeated Schema##{fmt} calls" do
      decorate

      printed = schema.public_send(fmt)
      expect(schema.public_send(fmt)).to eq(printed)
    end
  end

  it "leaves schemas without prose unspliced" do
    plain = Tempfile.new(["schema_plain", ".exp"])
    plain.write(<<~EXP)
      SCHEMA schema_plain;
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      END_SCHEMA;
    EXP
    plain.close
    plain_schema =
      Expressir::Express::Parser.from_files([plain.path]).schemas.first

    described_class.for(plain_schema).decorate_remarks({ "document" => nil })

    expect(plain_schema.formatted_hyperlinked_adoc)
      .not_to include("(*")
  end

  context "with separately stored END_SCHEMA tail comments" do
    before do
      schema.untagged_remarks = [
        Expressir::Model::RemarkInfo.new(
          text: "Closing description", format: "tail",
        ),
        Expressir::Model::RemarkInfo.new(
          text: "Placed comment", format: "tail", placement: "inline",
        ),
      ]
    end

    it "preserves legacy Liquid prose without changing the model remarks" do
      original = schema.remarks.dup
      decorate

      expect(schema.to_liquid.remarks).to eq(original + ["Closing description"])
      expect(schema.remarks).to eq(original)
    end

    it "keeps the legacy promoted tail description and its source comment" do
      decorate

      printed = schema.formatted
      expect(printed).to include('(*"schema_prose" Closing description *)')
      expect(printed.index("Closing description"))
        .to be < printed.index("ENTITY thing")
      expect(printed).to include("END_SCHEMA; -- Closing description")
      expect(schema.remarks.join).to include("vertices and the connections")
    end

    it "does not duplicate legacy prose on repeated decoration" do
      decorate
      decorate

      expect(schema.to_liquid.remarks.count("Closing description")).to eq(1)
      expect(schema.formatted.scan('(*"schema_prose" Closing description *)')
        .length).to eq(1)
    end
  end
end
