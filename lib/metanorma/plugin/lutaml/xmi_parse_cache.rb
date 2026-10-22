# frozen_string_literal: true

require "stringio"
require "xmi"
require "ea/xmi"

module Metanorma
  module Plugin
    module Lutaml
      class XmiParseCache
        def initialize(max_size: 50)
          @parse_cache = CacheStore.new(max_size: max_size)
          @drop_cache = CacheStore.new(max_size: max_size)
        end

        # slice: a XmiPartialLoadRegistry token; when given, the macro parses
        # the package slice prepared for it instead of the whole source
        def fetch(full_path, retain: true, slice: nil)
          key = slice || full_path
          return fetch_unretained(full_path, slice) unless retain

          @parse_cache.fetch_or_store(key) do
            load_parsed(full_path, slice)
          end
        end

        def fetch_unretained(full_path, slice = nil)
          load_parsed(full_path, slice)
        end

        def fetch_drop(full_path, guidance: nil, slice: nil)
          parsed = fetch(full_path, slice: slice)
          @drop_cache.fetch_or_store([key_for(full_path, slice), guidance]) do
            ::Ea::Xmi::LiquidDrops::RootDrop.new(
              parsed.uml_document, guidance, parsed.drop_options
            )
          end
        end

        def clear
          @parse_cache.clear
          @drop_cache.clear
        end

        private

        def key_for(full_path, slice)
          slice || full_path
        end

        # The prepared slice is parsed whole: assembling it already
        # streamed the source once, so nothing re-reads the original
        # export here.
        def load_parsed(full_path, slice)
          if slice
            xml = XmiPartialLoadRegistry.slice_string(slice)
            ::Ea::Xmi.load_graph(StringIO.new(xml))
          else
            ::Ea::Xmi.load_graph(full_path)
          end
        end
      end
    end
  end
end
