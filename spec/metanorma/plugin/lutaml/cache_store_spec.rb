# frozen_string_literal: true

require "spec_helper"
require_relative "../../../../lib/metanorma/plugin/lutaml/cache_store"

RSpec.describe Metanorma::Plugin::Lutaml::CacheStore do
  subject(:cache) { described_class.new(max_size: 3) }

  describe "#fetch_or_store" do
    it "computes and caches a value" do
      calls = 0
      result = cache.fetch_or_store(:a) do
        calls += 1
        "value_a"
      end

      expect(result).to eq("value_a")
      expect(calls).to eq(1)

      cached = cache.fetch_or_store(:a) { "other" }
      expect(cached).to eq("value_a")
      expect(calls).to eq(1)
    end

    it "evicts oldest entry when max_size is reached" do
      cache.fetch_or_store(:a) { "1" }
      cache.fetch_or_store(:b) { "2" }
      cache.fetch_or_store(:c) { "3" }

      cache.fetch_or_store(:d) { "4" }

      expect(cache.fetch(:a)).to be_nil
      expect(cache.fetch(:d)).to eq("4")
    end
  end

  describe "#fetch" do
    it "returns nil for missing keys" do
      expect(cache.fetch(:missing)).to be_nil
    end
  end

  describe "#store" do
    it "stores a value" do
      cache.store(:key, "val")
      expect(cache.fetch(:key)).to eq("val")
    end
  end

  describe "#clear" do
    it "empties the cache" do
      cache.store(:x, 1)
      cache.store(:y, 2)
      cache.clear

      expect(cache.fetch(:x)).to be_nil
      expect(cache.fetch(:y)).to be_nil
      expect(cache.size).to eq(0)
    end
  end

  describe "#size" do
    it "returns the number of cached entries" do
      expect(cache.size).to eq(0)
      cache.store(:a, 1)
      expect(cache.size).to eq(1)
    end
  end

  describe "thread safety" do
    it "handles concurrent fetch_or_store without data corruption" do
      cache = described_class.new(max_size: 100)
      threads = Array.new(10) do |i|
        Thread.new do
          100.times { cache.fetch_or_store("key_#{i}") { i } }
        end
      end
      threads.each(&:join)

      10.times { |i| expect(cache.fetch("key_#{i}")).to eq(i) }
    end
  end
end
