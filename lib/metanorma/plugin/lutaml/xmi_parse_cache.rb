# frozen_string_literal: true

require "xmi"
require "ea/xmi"

module Metanorma
  module Plugin
    module Lutaml
      ParsedXmi = Struct.new(:parser, :uml_document, :drop_options,
                             :xmi_id_index, keyword_init: true)

      class XmiParseCache
        def initialize(max_size: 50)
          @parse_cache = CacheStore.new(max_size: max_size)
          @drop_cache = CacheStore.new(max_size: max_size)
        end

        def fetch(full_path, retain: true)
          return fetch_unretained(full_path) unless retain

          @parse_cache.fetch_or_store(full_path) do
            xmi_model = ::Xmi::Sparx::Root.parse_xml(File.read(full_path))
            parser = ::Ea::Xmi::Parser.new
            uml_document = parser.parse(xmi_model)
            ParsedXmi.new(
              parser: parser,
              uml_document: uml_document,
              drop_options: build_drop_options(parser),
              xmi_id_index: build_xmi_id_index(uml_document),
            )
          end
        end

        # A slice is consumed exactly once (one macro, one class), so
        # retaining its parsed model only accumulates garbage; the full
        # sources keep the memoized path.
        def fetch_unretained(full_path)
          xmi_model = ::Xmi::Sparx::Root.parse_xml(File.read(full_path))
          parser = ::Ea::Xmi::Parser.new
          uml_document = parser.parse(xmi_model)
          ParsedXmi.new(
            parser: parser,
            uml_document: uml_document,
            drop_options: build_drop_options(parser),
            xmi_id_index: build_xmi_id_index(uml_document),
          )
        end

        def fetch_drop(full_path, guidance: nil)
          parsed = fetch(full_path)
          @drop_cache.fetch_or_store([full_path, guidance]) do
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

        # One xmi_id -> node walk per parse. Macro resolution used to
        # recurse the whole package tree per lookup — O(nodes) per macro
        # invocation, hundreds of invocations per document.
        def build_xmi_id_index(uml_document)
          index = {}
          collect = lambda do |container|
            index[container.xmi_id] ||= container if container.respond_to?(:xmi_id)
            if container.respond_to?(:classes)
              container.classes.each { |n| index[n.xmi_id] ||= n }
            end
            if container.respond_to?(:data_types)
              container.data_types.each { |n| index[n.xmi_id] ||= n }
            end
            if container.respond_to?(:enums)
              container.enums.each { |n| index[n.xmi_id] ||= n }
            end
            (container.packages || []).each { |p| collect.call(p) } if container.respond_to?(:packages)
          end
          collect.call(uml_document)
          index
        end

        def build_drop_options(parser)
          lookup = ::Ea::Xmi::LookupService.new(parser)
          {
            xmi_root_model: parser.xmi_root_model,
            id_name_mapping: parser.id_name_mapping,
            lookup: lookup,
            with_gen: true,
            with_assoc: true,
            with_absolute_path: true,
          }
        end
      end
    end
  end
end
