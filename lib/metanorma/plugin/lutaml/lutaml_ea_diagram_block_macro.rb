# frozen_string_literal: true

require "metanorma/plugin/lutaml/lutaml_diagram_base"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlEaDiagramBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlDiagramBase

        use_dsl
        named :lutaml_ea_diagram

        def process(parent, _target, attrs)
          orig_doc = get_original_document(parent)
          diagram = fetch_diagram_by_name(orig_doc, attrs["name"])
          return if diagram.nil?

          through_attrs = generate_attrs(attrs)
          through_attrs["target"] =
            img_src_path(parent.document, attrs, diagram)
          through_attrs["title"] = diagram.name

          create_image_block(parent, through_attrs)
        end

        private

        def get_original_document(parent)
          doc = parent.document.attributes["lutaml_xmi_cache"].values.first
          return doc if doc.instance_of?(::Lutaml::XMI::RootDrop)

          doc.original_document
        end

        def img_src_path(document, attrs, diagram)
          base_path = attrs["base_path"]
          format = attrs["format"] || "png"
          img_path = Utils.relative_file_path(document, base_path)

          "#{img_path}/#{diagram.xmi_id}.#{format}"
        end

        def fetch_diagram_by_name(orig_doc, name)
          found_diagrams = []
          loop_sub_packages(orig_doc.packages.first, name, found_diagrams)
          found_diagrams.first
        end

        def loop_sub_packages(package, name, found_diagrams)
          found_diagram = package.diagrams.find { |diag| diag.name == name }

          found_diagrams << found_diagram if found_diagram

          package.packages.each do |sub_package|
            loop_sub_packages(sub_package, name, found_diagrams)
          end
        end
      end
    end
  end
end
