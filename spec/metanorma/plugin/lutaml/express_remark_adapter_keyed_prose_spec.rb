# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"

# The document faces (873c488) subclass expressir's BASE formatter,
# whose round-trip form prints every remark item's raw tag. Keyed
# prose items print through the document's note machinery instead, so
# the faces drop them — while keeping the keyed __figure blocks, which
# stage the EXPRESS-G figures (#360/#371). Without the drop, every
# schema_docs page leaks `(*"schema.entity.__note" ... *)` into the
# listing (metanorma-plugin-lutaml#429, the iso-10303 gate regression:
# keyed 0 -> 24 on smol, 0 -> 1,869 on srl).
RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  let(:tempfile) do
    f = Tempfile.new(["keyed_prose", ".exp"])
    f.write(<<~EXP)
      SCHEMA keyed_prose;

      (*"keyed_prose.__note"
      Schema-level note.
      *)

      ENTITY widget;
        size : INTEGER;
        (*"keyed_prose.widget.size.__example"
        size equals 3 for the reference case.
        *)
        (*"keyed_prose.widget.__figure"
        Figure block for the diagram.
        *)
      END_ENTITY;

      END_SCHEMA;
    EXP
    f.close
    f
  end

  let(:schema) do
    Expressir::Express::Parser.from_file(tempfile.path).schemas.first
  end

  after do
    tempfile.unlink
  end

  %i[DocumentSourceFormatter DocumentAdocSourceFormatter].each do |face|
    describe "##{face}.format" do
      let(:output) do
        described_class.const_get(face).format(schema)
      end

      it "drops the keyed prose items' tags" do
        expect(output).not_to include("__note")
        expect(output).not_to include("__example")
      end

      it "keeps the keyed figure block" do
        expect(output).to include("__figure")
      end

      it "keeps the entity source" do
        expect(output).to include("ENTITY widget;")
      end
    end
  end
end
