# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "xmi"
require "lutaml/xmi"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"
require "metanorma/plugin/lutaml/lutaml_ea_xmi_base"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values tables
      #  from liquid drop object
      class LutamlEaXmiPreprocessor <
          ::Asciidoctor::Extensions::Preprocessor
        include LutamlEaXmiBase

        MACRO_REGEXP =
          /\[lutaml_ea_xmi,([^,]+),?(.+)?\]/.freeze

        private

        def parse_result_document(full_path)
          ::Lutaml::XMI::Parsers::XML.serialize_xmi_to_liquid(
            File.new(full_path, encoding: "UTF-8"),
          )
        end
      end
    end
  end
end
