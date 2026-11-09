# frozen_string_literal: true

# The registration is guarded on the renderer seam being defined: load
# metanorma's renderer first, then the registration file (the entry-point
# require ran earlier under spec_helper, before metanorma, when the guard
# still skipped).
# The seam file moved across metanorma releases: 2.5.19 keeps it at
# collection/collection.rb; the require fallback covers older layouts.
begin
  require "metanorma/collection/collection"
rescue LoadError
  require "metanorma/collection/renderer"
end
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
    seen = nil
    probe = registry.find do |r|
      r.call("express_a.b", ->(base) { seen = base; nil })
    end
    probe.call("express_a.b", ->(base) { seen = base; nil })
    expect(seen).to eq("a.b")
  end

  it "resolves a bibitemid carrying the citing page's suffix chain" do
    # The split pass suffixes the hidden bibitems per page: the svgmap
    # eref's bibitemid names the entity followed by the citing page's
    # stamp chain. The declaration still binds (iso-10303#825).
    stamped = "express_geometry_schema.line_ISO_DIS_10303-108_2025_" \
              "ISO_DIS_10303-108_2025_Annex_D__informative__EXPRESS-G_diagrams"
    expect(resolver.call(stamped, lookup)).to eq(:decl_line)
  end

  it "returns nil for references outside the express family" do
    expect(resolver.call("iso_17301", ->(_b) { :hit })).to be_nil
  end
end
