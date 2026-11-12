# frozen_string_literal: true

# The registration is guarded on the renderer seam being defined: load
# metanorma's renderer first, then the registration file (the entry-point
# require ran earlier under spec_helper, before metanorma, when the guard
# still skipped).
# The registration needs the renderer seam defined first: requiring the
# metanorma umbrella defines Renderer and the registry; the entry-point
# require in spec_helper ran before metanorma, when the guard still
# skipped, so the registration file is loaded here directly.
require "metanorma"
require "metanorma/plugin/lutaml/express_hotspot_anchor"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressHotspotAnchor do
  # Mirrors the renderer's hotspot_prefix_lookup: exact, then unique
  # front-prefix.
  let(:idx) do
    {
      "geometry_schema.cartesian_point_ISO_10303-42_2025_a" => :decl_cartesian,
      "geometry_schema.line_ISO_10303-42_2025_b" => :decl_line,
    }
  end
  let(:lookup) do
    ->(base) {
      return idx[base] if idx.key?(base)
      c = idx.keys.select { |k| k.start_with?("#{base}_") }
      c.one? ? idx[c.first] : nil
    }
  end
  let(:registry) do
    Metanorma::Collection::Renderer.reference_anchor_resolvers
  end
  let(:resolver) do
    registry.find { |r| r.call("express_geometry_schema.line", lookup) == :decl_line }
  end

  it "registers exactly one express-family resolver at load" do
    expect(registry.count do |r|
      r.call("express_anything", ->(_b) { :hit })
    end).to eq(1)
  end

  it "maps a clean express reference to its declaration" do
    expect(resolver).not_to be_nil
  end

  it "strips the express_ prefix before the lookup" do
    seen = []
    # Discriminate the express resolver by family: a truthy lookup makes
    # exactly the express-family resolver answer (non-express resolvers
    # decline the express_ prefix).
    probe = registry.reverse.find do |r|
      r.call("express_a.b", ->(_base) { :decl }) == :decl
    end
    seen.clear
    expect(probe.call("express_a.b", ->(base) { seen << base; :decl })).to eq(:decl)
    expect(seen.first).to eq("a.b")
  end

  it "resolves a bibitemid carrying the citing page's suffix chain" do
    # The split pass suffixes the hidden bibitems per page: the svgmap
    # eref's bibitemid names the entity followed by the citing page's
    # stamp chain. The declaration still binds (iso-10303#825).
    stamped = "express_geometry_schema.line_ISO_DIS_10303-108_2025_" \
              "ISO_DIS_10303-108_2025_Annex_D__informative__EXPRESS-G_diagrams"
    expect(resolver.call(stamped, lookup)).to eq(:decl_line)
  end

  it "terminates on the doubled-underscore annex chain (#346)" do
    # The annex page chain carries "__": once the walk strips down to
    # "..._Annex_D_", the old /_[^_]+\z/ cut stopped matching, the name
    # never shrank again, and the walk spun forever (millions of
    # identical lookups in the reinflate). The walk must end within a
    # bounded number of lookups and bind the declaration via the
    # unique front-prefix.
    seen = 0
    counting = ->(base) {
      seen += 1
      raise "runaway prefix walk: #{seen} lookups, at #{base.inspect}" if seen > 60

      lookup.call(base)
    }
    annexed = "express_geometry_schema.line_ISO_10303-42_2025_" \
              "ISO_10303-42_2025_Annex_D__informative"
    expect(resolver.call(annexed, counting)).to eq(:decl_line)
  end

  it "terminates when the bibitemid ends in an underscore" do
    # Same #346 shape one character earlier: a trailing "_" alone must
    # not wedge the walk.
    trailing = "express_geometry_schema.line_ISO_10303-42_2025_b_"
    expect(resolver.call(trailing, lookup)).to eq(:decl_line)
  end

  it "never migrates an undeclared entity onto another declaration (#825)" do
    # metanorma/iso-10303#825 case 7 of #346: line_segment is not
    # declared anywhere; the old walk stripped INTO the entity name and
    # adopted line's record. The trim stops at the stamp boundary (the
    # first digit/capital segment), so an undeclared entity stays
    # untargeted.
    asked = "express_trial_geo_schema.line_segment_iso10303-9002"
    expect(resolver.call(asked, lookup)).to be_nil
  end

  it "trims only the stamp chain, never the entity's own segments" do
    # An entity whose own name carries a stamp-shaped tail segment
    # (lowercase "9002"-style) keeps it when it is what the index holds:
    # the full form is tried first and exact matches win.
    idx2 = {
      "geometry_schema.line_segment_9002" => :decl_segment_9002,
    }
    l2 = ->(base) {
      idx2[base] || begin
        c = idx2.keys.select { |k| k.start_with?("#{base}_") }
        c.one? ? idx2[c.first] : nil
      end
    }
    expect(resolver.call("express_geometry_schema.line_segment_9002", l2))
      .to eq(:decl_segment_9002)
  end

  it "returns nil for references outside the express family" do
    expect(resolver.call("iso_17301", ->(_b) { :hit })).to be_nil
  end
end
