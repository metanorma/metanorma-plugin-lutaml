# frozen_string_literal: true

require "ogc/gml"
require "liquid"

require "metanorma/plugin/lutaml/gc_budget"

module Metanorma
  module Plugin
    module Lutaml
      module LutamlGmlDictionaryBase
        private

        def render(tmpl, parent, attrs, orig_gml_path)
          GcBudget.gc_when_bloated!
          dict = get_gml_dictionary(parent, orig_gml_path)
          tmpl.assigns[attrs["context"]] = GmlDictionaryDrop.new(dict)
          rendered_tmpl = tmpl.render
          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_tmpl, attrs)
        end

        # A document-scale compile resolves the same dictionary files many
        # times (the plateau corpus cites codelists up to 34 times each);
        # re-reading and re-parsing per macro was pure duplicate work.
        GML_DICTIONARY_CACHE = CacheStore.new(max_size: 512)

        def get_gml_dictionary(parent, orig_gml_path)
          gml_path = Utils.relative_file_path(
            parent.document, orig_gml_path
          )

          GML_DICTIONARY_CACHE.fetch_or_store(gml_path) do
            ::Ogc::Gml::Dictionary.from_xml(xml_content(gml_path))
          end
        end

        def xml_content(filepath)
          File.read(filepath).gsub(
            'xmlns:gml="http://www.opengis.net/gml"',
            'xmlns:gml="http://www.opengis.net/gml/3.2"',
          )
        end
      end
    end
  end
end
