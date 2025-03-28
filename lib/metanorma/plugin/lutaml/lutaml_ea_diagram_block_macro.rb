# frozen_string_literal: true

require "metanorma/plugin/lutaml/lutaml_diagram_base"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlEaDiagramBlockMacro < ::Asciidoctor::Extensions::BlockMacroProcessor
        include LutamlDiagramBase
        include LutamlEaXmiBase

        use_dsl
        named :lutaml_ea_diagram

        def process(parent, _target, attrs)
          orig_doc = get_original_document(parent, attrs["index"])
          diagram = fetch_diagram_by_name(orig_doc, attrs)
          return if diagram.nil?

          through_attrs = generate_attrs(attrs)
          through_attrs["target"] =
            img_src_path(parent.document, attrs, diagram)
          through_attrs["title"] = diagram.name

          create_image_block(parent, through_attrs)
        end

        private

        def parse_result_document(full_path, guidance = nil)
          ::Lutaml::XMI::Parsers::XML.serialize_xmi_to_liquid(
            File.new(full_path, encoding: "UTF-8"),
            guidance,
          )
        end

        def get_original_document(parent, index = nil)
          path = get_path_from_index(parent, index) if index

          if index && path
            doc = lutaml_document_from_file_or_cache(
              parent.document, path,
              Metanorma::Plugin::Lutaml::Config::Root.new
            )
          end

          doc ||= parent.document.attributes["lutaml_xmi_cache"].values.first
          doc
        end

        def get_path_from_index(parent, index_name) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          lutaml_xmi_index = parent.document
            .attributes["lutaml_xmi_index"][index_name]

          if lutaml_xmi_index.nil? || lutaml_xmi_index[:path].nil?
            ::Metanorma::Util.log(
              "[metanorma-plugin-lutaml] lutaml_xmi_index error: " \
              "XMI index #{index_name} path not found!",
              :error,
            )

            return nil
          end

          lutaml_xmi_index[:path]
        end

        def img_src_path(document, attrs, diagram)
          base_path = attrs["base_path"]
          format = attrs["format"] || "png"
          img_path = Utils.relative_file_path(document, base_path)

          "#{img_path}/#{diagram.xmi_id}.#{format}"
        end

        def fetch_diagram_by_name(orig_doc, attrs)
          name = attrs["name"]
          package_name = attrs["package"]
          found_diagrams = []

          loop_sub_packages(
            orig_doc.packages.first, name, found_diagrams, package_name
          )

          found_diagrams.first
        end

        def loop_sub_packages(package, name, found_diagrams, package_name) # rubocop:disable Metrics/CyclomaticComplexity
          found_diagram = package.diagrams.find { |diag| diag.name == name }

          if found_diagram && package_name &&
              found_diagram.package_name != package_name
            found_diagram = nil
          end

          found_diagrams << found_diagram if found_diagram

          package.packages.each do |sub_package|
            loop_sub_packages(sub_package, name, found_diagrams, package_name)
          end
        end
      end
    end
  end
end
