# frozen_string_literal: true

require "metanorma/plugin/lutaml"

RSpec.describe Metanorma::Plugin::Lutaml::ExpressHotspotAnchor do
  let(:registry) do
    Metanorma::Collection::Renderer::Svg.reference_anchor_resolvers
  end

  # The registration happens at gem load; find this gem's resolver among
  # whatever the registry carries.
  let(:resolver) do
    registry.find do |r|
      r.call("express_geometry_schema.cartesian_point",
             ->(_base) { :sentinel_base_lookup }) == :sentinel
    end
  end

  it "registers exactly one express-family resolver at load" do
    expect(registry.count do |r|
      r.call("express_anything", ->(_b) { :hit })
    end).to eq(1)
  end

  it "maps an express reference to its declaration base through lookup" do
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

  it "returns nil for references outside the express family" do
    expect(resolver.call("iso_17301", ->(_b) { :hit })).to be_nil
  end
end
