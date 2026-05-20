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

        def find_class_by_xmi_id(container, xmi_id)
          container.classes.find { |node| node.xmi_id == xmi_id } ||
            container.packages
              .lazy
              .filter_map { |pkg| find_class_by_xmi_id(pkg, xmi_id) }
              .first
        end

        def find_enum_by_xmi_id(container, xmi_id)
          container.enums.find { |node| node.xmi_id == xmi_id } ||
            container.packages
              .lazy
              .filter_map { |pkg| find_enum_by_xmi_id(pkg, xmi_id) }
              .first
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

        def serialize_klass_drop_by_name(xmi_path, name, _document = nil,
guidance = nil)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path)
          klass = resolve_packaged_klass(parsed, name)
          warn "Class not found for name: #{name}" if klass.nil?
          ::Lutaml::Xmi::LiquidDrops::KlassDrop.new(
            klass, guidance, parsed.drop_options
          )
        end

        def serialize_enum_drop_by_name(xmi_path, name, _document = nil)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path)
          raw_enum = find_packaged_enum(parsed.parser.xmi_index, name)
          warn "Enumeration not found for name: #{name}" if raw_enum.nil?
          enum = raw_enum && find_enum_by_xmi_id(
            parsed.uml_document, raw_enum.id
          )
          ::Lutaml::Xmi::LiquidDrops::EnumDrop.new(
            enum, parsed.drop_options
          )
        end

        private

        def resolve_packaged_klass(parsed, name)
          root_model_name = parsed.parser.xmi_root_model.model.name
          raw_klass = find_packaged_klass(
            parsed.parser.xmi_index, name,
            root_model_name: root_model_name
          )
          raw_klass && find_class_by_xmi_id(
            parsed.uml_document, raw_klass.id
          )
        end
      end
    end
  end
end
