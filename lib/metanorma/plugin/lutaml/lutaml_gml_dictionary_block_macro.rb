# frozen_string_literal: true

# require "lutaml/ogc-gml"

require "ogc/gml/dictionary"
require "liquid"
require_relative "liquid_drops/gml_dictionary_drop"
require_relative "liquid_drops/gml_dictionary_entry_drop"
require_relative "liquid_drops/gml_dictionary_source_drop"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlGmlDictionaryBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        use_dsl
        named :lutaml_gml_dictionary

        DEFAULT_TEMPLATE = "lib/metanorma/plugin/lutaml/liquid_templates/" \
                           "_gml_dictionary.liquid"

        def process(parent, _target, attrs)
          dict = get_gml_dictionary(parent, attrs)

          tmpl = gml_dictionary_template(
            parent.document,
            attrs["template_path"],
          )
          tmpl.assigns["dict"] = GmlDictionaryDrop.new(dict)
          tmpl.assigns["source"] = GmlDictionarySourceDrop.new(attrs["source"])

          render(tmpl, parent, attrs)
        end

        private

        def render(tmpl, parent, attrs)
          rendered_tmpl = tmpl.render
          block = create_open_block(parent, "", attrs)
          parse_content(block, rendered_tmpl, attrs)
        end

        def get_gml_dictionary(parent, attrs)
          gml_path = Utils.relative_file_path(
            parent.document, attrs["xml_path"]
          )
          Ogc::Gml::Dictionary.from_xml(xml_content(gml_path))
        end

        def xml_content(filepath)
          File.read(filepath).gsub(
            'xmlns:gml="http://www.opengis.net/gml"',
            'xmlns:gml="http://www.opengis.net/gml/3.2"',
          )
        end

        def gml_dictionary_template(document, template_path)
          if template_path.nil?
            template_path = DEFAULT_TEMPLATE
          end

          rel_tmpl_path = Utils.relative_file_path(
            document, template_path
          )

          ::Liquid::Template.parse(File.read(rel_tmpl_path))
        end
      end
    end
  end
end
