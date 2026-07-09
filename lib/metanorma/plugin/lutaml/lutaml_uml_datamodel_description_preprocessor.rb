# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml/uml"
require "lutaml/uml"
require "ea/xmi"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"
require "metanorma/plugin/lutaml/lutaml_ea_xmi_base"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      # TODO: merge with lutaml_ea_xmi
      class LutamlUmlDatamodelDescriptionPreprocessor <
          ::Asciidoctor::Extensions::Preprocessor
        include LutamlEaXmiBase

        MACRO_REGEXP =
          /\[lutaml_uml_datamodel_description,([^,]+),?(.+)?\]/

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
