# frozen_string_literal: true

require "xmi"
require "lutaml/xmi"

module Metanorma
  module Plugin
    module Lutaml
      ParsedXmi = Struct.new(:parser, :uml_document, :drop_options,
                             keyword_init: true)

      class XmiParseCache
        def initialize(max_size: 50)
          @parse_cache = CacheStore.new(max_size: max_size)
          @drop_cache = CacheStore.new(max_size: max_size)
        end

        def fetch(full_path)
          @parse_cache.fetch_or_store(full_path) do
            xmi_model = ::Xmi::Sparx::Root.parse_xml(File.read(full_path))
            parser = ::Lutaml::Xmi::Parsers::Xml.new
            uml_document = parser.parse(xmi_model)
            ParsedXmi.new(
              parser: parser,
              uml_document: uml_document,
              drop_options: build_drop_options(parser),
            )
          end
        end

        def fetch_drop(full_path, guidance: nil)
          parsed = fetch(full_path)
          @drop_cache.fetch_or_store([full_path, guidance]) do
            ::Lutaml::Xmi::LiquidDrops::RootDrop.new(
              parsed.uml_document, guidance, parsed.drop_options
            )
          end
        end

        def clear
          @parse_cache.clear
          @drop_cache.clear
        end

        private

        def build_drop_options(parser)
          lookup = ::Lutaml::Xmi::XmiLookupService.new(
            parser.xmi_root_model, parser.id_name_mapping
          )
          {
            xmi_root_model: parser.xmi_root_model,
            id_name_mapping: parser.id_name_mapping,
            lookup: lookup,
            with_gen: true,
            with_absolute_path: true,
          }
        end
      end
    end
  end
end
