# frozen_string_literal: true

require_relative "metanorma/plugin/lutaml/version"
require_relative "metanorma/plugin/lutaml"

module Metanorma
  module Plugin
    module Lutaml
      autoload :Asciidoctor, "metanorma/plugin/lutaml/asciidoctor"
      autoload :BasePreprocessor, "metanorma/plugin/lutaml/base_preprocessor"
      autoload :BaseStructuredTextPreprocessor,
               "metanorma/plugin/lutaml/base_structured_text_preprocessor"
      autoload :CacheStore, "metanorma/plugin/lutaml/cache_store"
      autoload :Config, "metanorma/plugin/lutaml/config"
      autoload :Content, "metanorma/plugin/lutaml/content"
      autoload :Data2TextPreprocessor,
               "metanorma/plugin/lutaml/data2_text_preprocessor"
      autoload :ExpressRemarksDecorator,
               "metanorma/plugin/lutaml/express_remarks_decorator"
      autoload :FileNotFoundError,
               "metanorma/plugin/lutaml/file_not_found_error"
      autoload :Json2TextPreprocessor,
               "metanorma/plugin/lutaml/json2_text_preprocessor"
      autoload :LutamlDiagramBase, "metanorma/plugin/lutaml/lutaml_diagram_base"
      autoload :LutamlDiagramBlock,
               "metanorma/plugin/lutaml/lutaml_diagram_block"
      autoload :LutamlDiagramBlockMacro,
               "metanorma/plugin/lutaml/lutaml_diagram_block_macro"
      autoload :LutamlEaDiagramBlockMacro,
               "metanorma/plugin/lutaml/lutaml_ea_diagram_block_macro"
      autoload :LutamlEaXmiBase, "metanorma/plugin/lutaml/lutaml_ea_xmi_base"
      autoload :LutamlEaXmiPreprocessor,
               "metanorma/plugin/lutaml/lutaml_ea_xmi_preprocessor"
      autoload :LutamlEnumTableBlockMacro,
               "metanorma/plugin/lutaml/lutaml_enum_table_block_macro"
      autoload :LutamlFigureInlineMacro,
               "metanorma/plugin/lutaml/lutaml_figure_inline_macro"
      autoload :LutamlGmlDictionaryBase,
               "metanorma/plugin/lutaml/lutaml_gml_dictionary_base"
      autoload :LutamlGmlDictionaryBlock,
               "metanorma/plugin/lutaml/lutaml_gml_dictionary_block"
      autoload :LutamlGmlDictionaryBlockMacro,
               "metanorma/plugin/lutaml/lutaml_gml_dictionary_block_macro"
      autoload :LutamlKlassTableBlockMacro,
               "metanorma/plugin/lutaml/lutaml_klass_table_block_macro"
      autoload :LutamlPreprocessor,
               "metanorma/plugin/lutaml/lutaml_preprocessor"
      autoload :LutamlTableInlineMacro,
               "metanorma/plugin/lutaml/lutaml_table_inline_macro"
      autoload :LutamlUmlDatamodelDescriptionPreprocessor,
               "metanorma/plugin/lutaml/" \
               "lutaml_uml_datamodel_description_preprocessor"
      autoload :LutamlXmiUmlPreprocessor,
               "metanorma/plugin/lutaml/lutaml_xmi_uml_preprocessor"
      autoload :LutamlXsdPreprocessor,
               "metanorma/plugin/lutaml/lutaml_xsd_preprocessor"
      autoload :ParseError, "metanorma/plugin/lutaml/parse_error"
      autoload :SourceExtractor, "metanorma/plugin/lutaml/source_extractor"
      autoload :Utils, "metanorma/plugin/lutaml/utils"
      autoload :Yaml2TextPreprocessor,
               "metanorma/plugin/lutaml/yaml2_text_preprocessor"
    end
  end
end

autoload :GmlDictionaryDrop,
         "metanorma/plugin/lutaml/liquid_drops/gml_dictionary_drop"
autoload :GmlDictionaryEntryDrop,
         "metanorma/plugin/lutaml/liquid_drops/gml_dictionary_entry_drop"
