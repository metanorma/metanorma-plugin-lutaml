# frozen_string_literal: true

require "rspec"
require "tempfile"
require_relative "../../../../lib/metanorma/plugin/lutaml/utils"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressEntityAttributes do
  def parse_entity(body)
    Tempfile.create(["entity", ".exp"]) do |file|
      file.write("SCHEMA test; #{body} END_SCHEMA;")
      file.flush
      Expressir::Express::Parser.from_file(
        file.path, use_core: false
      ).schemas.first.entities.last
    end
  end

  it "parses and formats explicit attributes without the native core" do
    entity = parse_entity(<<~EXP)
      ENTITY thing;
        name : STRING;
        count : INTEGER;
      END_ENTITY;
    EXP

    expect(entity.attributes.map(&:id)).to eq(%w[name count])
    expect(entity.attributes.map(&:kind)).to eq(%w[EXPLICIT EXPLICIT])
    expect(entity.to_s).to include("name : STRING;", "count : INTEGER;")
  end

  it "preserves every attribute in a grouped declaration" do
    entity = parse_entity(<<~EXP)
      ENTITY thing;
        first, second : OPTIONAL STRING;
      END_ENTITY;
    EXP

    expect(entity.attributes.map(&:id)).to eq(%w[first second])
    expect(entity.attributes.map(&:optional)).to eq([true, true])
  end

  it "flattens derived and inverse attributes alongside explicit attributes" do
    entity = parse_entity(<<~EXP)
      ENTITY owner;
        item : thing;
      END_ENTITY;
      ENTITY thing;
        name : STRING;
      DERIVE
        count : INTEGER := 1;
      INVERSE
        owners : SET [0:?] OF owner FOR item;
      END_ENTITY;
    EXP

    expect(entity.attributes.map(&:id)).to eq(%w[name count owners])
    expect(entity.attributes.map(&:kind)).to eq(%w[EXPLICIT DERIVED INVERSE])
    expect(entity.to_s).to include("DERIVE", "INVERSE")
  end

  it "preserves entities without attributes" do
    entity = parse_entity("ENTITY thing; END_ENTITY;")

    expect(entity.attributes).to eq([])
    expect(entity.to_s).to include("ENTITY thing;", "END_ENTITY;")
  end
end
