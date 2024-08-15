# frozen_string_literal: true

require "ogc/gml"
require "liquid"
require_relative "liquid_drops/gml_dictionary_drop"
require_relative "liquid_drops/gml_dictionary_entry_drop"

module Metanorma
  module Plugin
    module Lutaml
      module LutamlGmlDictionaryBase
        private

        def render(tmpl, parent, attrs, orig_gml_path)
          dict = get_gml_dictionary(parent, orig_gml_path)
          tmpl.assigns[attrs["context"]] = GmlDictionaryDrop.new(dict)
          rendered_tmpl = tmpl.render
          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_tmpl, attrs)
        end

        def get_gml_dictionary(parent, orig_gml_path)
          gml_path = Utils.relative_file_path(
            parent.document, orig_gml_path
          )
          Ogc::Gml::Dictionary.from_xml(xml_content(gml_path))
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
