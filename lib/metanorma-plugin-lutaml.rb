require "metanorma/plugin/lutaml/version"
require "metanorma/plugin/lutaml/lutaml_preprocessor"
require "metanorma/plugin/lutaml/lutaml_uml_attributes_table_preprocessor"
require "metanorma/plugin/lutaml/lutaml_uml_datamodel_description_preprocessor"
require "metanorma/plugin/lutaml/lutaml_diagram_block"
require "metanorma/plugin/lutaml/lutaml_diagram_block_macro"
require "metanorma/plugin/lutaml/lutaml_figure_inline_macro"
require "metanorma/plugin/lutaml/lutaml_table_inline_macro"

module Metanorma
  module Plugin
    module Lutaml
    end
  end

  Asciidoctor::Extensions.register do
    preprocessor Metanorma::Plugin::Lutaml::LutamlPreprocessor
    preprocessor Metanorma::Plugin::Lutaml::LutamlUmlAttributesTablePreprocessor
    preprocessor Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor
    inline_macro Metanorma::Plugin::Lutaml::LutamlFigureInlineMacro
    inline_macro Metanorma::Plugin::Lutaml::LutamlTableInlineMacro
    block_macro Metanorma::Plugin::Lutaml::LutamlDiagramBlockMacro
    block Metanorma::Plugin::Lutaml::LutamlDiagramBlock
  end
end
