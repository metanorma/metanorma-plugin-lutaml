# frozen_string_literal: true

require "metanorma/plugin/lutaml/gc_budget"

module Metanorma
  module Plugin
    module Lutaml
      module XmiCache
        # Bounded parse-once cache: every macro touching a source (the
        # full file, or its package slice under lutaml-ea-xmi-load: partial)
        # reuses the one parsed graph; the LRU bound keeps the retained
        # graphs to a few live at once, which the section-ordered
        # macros of a document turn into near-perfect reuse.
        XMI_PARSE_CACHE = XmiParseCache.new(max_size: 4)

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

        def find_packaged_datatype(index, path, root_model_name: nil)
          segments = path.split("::").reject(&:empty?)
          if root_model_name && segments.first == root_model_name
            segments.shift
          end
          if segments.one?
            index.find_packaged_by_name_and_types(
              segments.first, ["uml:DataType"]
            )
          else
            find_packaged_datatype_by_path(index, segments)
          end
        end

        def find_packaged_datatype_by_path(index, segments)
          datatype_name = segments.pop

          candidates = ["uml:DataType"]
            .flat_map { |t| index.packaged_elements_of_type(t) }
            .select { |e| e.name == datatype_name }

          candidates.find do |datatype|
            match_parent_chain?(index, datatype, segments)
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

        def serialize_klass_or_datatype_drop_by_name(xmi_path,
          name, _document = nil, guidance = nil)
          serialize_klass_drop_by_name(xmi_path, name, _document, guidance) ||
            serialize_datatype_drop_by_name(xmi_path, name, _document)
        end

        def serialize_klass_drop_by_name(xmi_path,
          name, _document = nil, guidance = nil)
          GcBudget.gc_when_bloated!
          xmi_path, name, slice = XmiPartialLoadRegistry.rewrite(xmi_path, name)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path, slice: slice)
          klass = resolve_packaged_klass(parsed, name)
          if klass.nil?
            warn "Class not found for name: #{name}"
            return nil
          end

          ::Ea::Xmi::LiquidDrops::KlassDrop.new(
            klass, guidance, parsed.drop_options
          )
        end

        def serialize_datatype_drop_by_name(xmi_path, name, _document = nil)
          GcBudget.gc_when_bloated!
          xmi_path, name, slice = XmiPartialLoadRegistry.rewrite(xmi_path, name)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path, slice: slice)
          datatype = resolve_packaged_datatype(parsed, name)
          if datatype.nil?
            warn "Datatype not found for name: #{name}"
            nil
          end

          ::Ea::Xmi::LiquidDrops::DataTypeDrop.new(
            datatype, parsed.drop_options
          )
        end

        def serialize_enum_drop_by_name(xmi_path, name, _document = nil)
          GcBudget.gc_when_bloated!
          xmi_path, name, slice = XmiPartialLoadRegistry.rewrite(xmi_path, name)
          parsed = XMI_PARSE_CACHE.fetch(xmi_path, slice: slice)
          raw_enum = find_packaged_enum(parsed.parser.xmi_index, name)
          if raw_enum.nil?
            warn "Enumeration not found for name: #{name}"
            return nil
          end

          enum = parsed.xmi_id_index[raw_enum.id]
          ::Ea::Xmi::LiquidDrops::EnumDrop.new(
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
          raw_klass && parsed.xmi_id_index[raw_klass.id]
        end

        def resolve_packaged_datatype(parsed, name)
          root_model_name = parsed.parser.xmi_root_model.model.name
          raw_datatype = find_packaged_datatype(
            parsed.parser.xmi_index, name,
            root_model_name: root_model_name
          )
          raw_datatype && parsed.xmi_id_index[raw_datatype.id]
        end
      end
    end
  end
end
