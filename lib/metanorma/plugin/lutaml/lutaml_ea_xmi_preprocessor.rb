# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml/uml"
require "xmi"
require "ea/xmi"
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
          /\[lutaml_ea_xmi,([^,]+),?(.+)?\]/

        private

        def parse_result_document(full_path, guidance)
          ::Ea::Xmi::Parser.serialize_to_liquid(
            File.new(full_path, encoding: "UTF-8"),
            guidance,
          )
        end
      end
    end
  end
end
