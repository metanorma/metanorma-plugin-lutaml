# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module XmiCache
        XMI_PARSE_CACHE = XmiParseCache.new

        def lutaml_document_from_file_or_cache(document, file_path, yaml_config,
yaml_config_path = nil)
          full_path = Utils.relative_file_path(document, file_path)
          load_ea_extensions(yaml_config, yaml_config_path)
          guidance = get_guidance(document, yaml_config.guidance)
          paths = (document.attributes["lutaml_xmi_paths"] ||= [])
          paths << full_path unless paths.include?(full_path)
          XMI_PARSE_CACHE.fetch_drop(full_path, guidance: guidance)
        end

        def build_uml_document(xmi_path, _document = nil)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path)
          [parsed.parser, parsed.uml_document]
        end

        def load_ea_extensions(yaml_config, yaml_config_path)
          yaml_config.ea_extension&.each do |ea_extension_path|
            ea_extension_full_path = File.expand_path(
              ea_extension_path, File.dirname(yaml_config_path)
            )
            unless Xmi::EaRoot.loaded_extensions.value?(ea_extension_full_path)
              Xmi::EaRoot.load_extension(ea_extension_full_path)
            end
          end
        end

        def build_drop_options(parser)
          lookup = ::Lutaml::Xmi::XmiLookupService.new(
            parser.xmi_root_model, parser.id_name_mapping
          )
          {
            xmi_root_model: parser.xmi_root_model,
            id_name_mapping: parser.id_name_mapping,
            lookup: lookup,
            with_gen: true,
            with_absolute_path: true,
          }
        end

        def find_uml_node_by_xmi_id(container, xmi_id, collection)
          found = container.public_send(collection)
            .find { |node| node.xmi_id == xmi_id }
          return found if found

          container.packages.each do |pkg|
            nested = find_uml_node_by_xmi_id(pkg, xmi_id, collection)
            return nested if nested
          end
          nil
        end

        def find_packaged_klass(index, path, root_model_name: nil)
          segments = path.split("::").reject(&:empty?)
          if root_model_name && segments.first == root_model_name
            segments.shift
          end
          if segments.one?
            index.find_packaged_by_name_and_types(
              segments.first, ["uml:Class", "uml:AssociationClass"]
            )
          else
            find_packaged_klass_by_path(index, segments)
          end
        end

        def find_packaged_klass_by_path(index, segments)
          klass_name = segments.pop

          candidates = ["uml:Class", "uml:AssociationClass"]
            .flat_map { |t| index.packaged_elements_of_type(t) }
            .select { |e| e.name == klass_name }

          candidates.find do |klass|
            match_parent_chain?(index, klass, segments)
          end
        end

        def match_parent_chain?(index, element, parent_segments)
          current = element
          parent_segments.reverse_each do |pkg_name|
            parent = index.find_parent(current.id)
            return false unless parent && parent.name == pkg_name

            current = parent
          end
          true
        end

        def find_packaged_enum(index, name)
          index.packaged_elements_of_type("uml:Enumeration")
            .find { |e| e.name == name }
        end

        def serialize_klass_drop_by_name(xmi_path, name, document = nil,
guidance = nil)
          parser, uml_doc = build_uml_document(xmi_path, document)
          root_model_name = parser.xmi_root_model.model.name
          raw_klass = find_packaged_klass(parser.xmi_index, name,
                                          root_model_name: root_model_name)
          warn "Class not found for name: #{name}" if raw_klass.nil?
          klass = raw_klass && find_uml_node_by_xmi_id(
            uml_doc, raw_klass.id, :classes
          )
          ::Lutaml::Xmi::LiquidDrops::KlassDrop.new(
            klass, guidance, build_drop_options(parser)
          )
        end

        def serialize_enum_drop_by_name(xmi_path, name, document = nil)
          parser, uml_doc = build_uml_document(xmi_path, document)
          raw_enum = find_packaged_enum(parser.xmi_index, name)
          warn "Enumeration not found for name: #{name}" if raw_enum.nil?
          enum = raw_enum && find_uml_node_by_xmi_id(
            uml_doc, raw_enum.id, :enums
          )
          ::Lutaml::Xmi::LiquidDrops::EnumDrop.new(
            enum, build_drop_options(parser)
          )
        end
      end
    end
  end
end
