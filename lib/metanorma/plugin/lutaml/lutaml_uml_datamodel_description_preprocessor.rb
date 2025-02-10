# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "lutaml/xmi"
require "metanorma/plugin/lutaml/utils"
require "metanorma/plugin/lutaml/asciidoctor/preprocessor"
require "metanorma/plugin/lutaml/lutaml_ea_xmi_base"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      class LutamlUmlDatamodelDescriptionPreprocessor <
          ::Asciidoctor::Extensions::Preprocessor
        include LutamlEaXmiBase

        MACRO_REGEXP =
          /\[lutaml_uml_datamodel_description,([^,]+),?(.+)?\]/.freeze

        private

        def parse_result_document(full_path, _guidance = nil)
          ::Lutaml::Parser.parse(File.new(full_path, encoding: "UTF-8")).first
        end
      end
    end
  end
end
