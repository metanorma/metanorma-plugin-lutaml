# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module XmiContextBuilder
        MODEL_COLLECTIONS = %i[classes data_types].freeze

        def create_context_object( # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          lutaml_document, additional_context, options,
          context_name = "context"
        )
          root_context = lutaml_document.to_liquid
          root_package = package_level(
            root_context, options.package_root_level || 1
          )
          contexts = create_default_context_object(
            context_name, root_package, additional_context, options
          )

          if options.packages.nil?
            contexts[context_name]["render_nested_packages"] = true
            contexts[context_name]["packages"] = root_package.packages
            add_model_anchor_context(contexts[context_name], root_context)

            return contexts
          end

          all_packages = [root_package, *root_package.children_packages]
          contexts[context_name].merge!(
            {
              "packages" => sort_and_filter_out_packages(all_packages, options),
              "package_entities" => package_hash(options, "render_entities"),
              "package_skip_sections" => package_hash(options, "skip_tables"),
              "render_nested_packages" => !!options.render_nested_packages,
            },
          )
          add_model_anchor_context(contexts[context_name], root_context)

          contexts
        end

        def create_default_context_object(
          context_name, root_package, additional_context, options
        )
          contexts = {}
          contexts[context_name] = {
            "name" => root_package.name,
            "root_packages" => [root_package],
            "additional_context" => additional_context
              .merge(
                "external_classes" => external_model_targets(
                  options.external_classes,
                ),
              ),
            "skip_unrecognized_connector" => !!options
              .skip_unrecognized_connector,
          }
          contexts
        end

        def external_model_targets(external_classes)
          external_classes&.transform_values do |target|
            if target.is_a?(String) && target.match?(/\Asection-[^\s#]+\z/)
              "##{target}"
            else
              target
            end
          end
        end

        def fill_in_entities_refs_attributes(document, # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
          lutaml_document, _options)
          all_children_packages = lutaml_document.packages
            .map(&:children_packages).flatten
          package_flat_packages = lambda do |pks|
            pks.to_h do |package|
              [package.name, package.xmi_id]
            end
          end
          children_pks = package_flat_packages.call(all_children_packages)
          ref_dictionary = package_flat_packages.call(lutaml_document.packages)
            .merge(children_pks)
          %w[class enum data_type].each do |type|
            package_flat = lambda do |pks|
              pks.each_with_object({}) do |package, res|
                entities = package_entities(package, type)
                entities.map do |entity|
                  res["#{type}:#{package.name}:#{entity.name}"] = entity.xmi_id
                end
              end
            end
            children_pks_diags = package_flat.call(all_children_packages)
            ref_dictionary = ref_dictionary
              .merge(package_flat.call(lutaml_document.packages)
                                      .merge(children_pks_diags))
          end
          document.attributes["lutaml_entity_id"] = ref_dictionary
        end

        def fill_in_diagrams_attributes(document, lutaml_document) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          package_flat_diagrams = lambda do |pks|
            pks.each_with_object({}) do |package, res|
              package.diagrams.map do |diag|
                res["#{package.name}:#{diag.name}"] = diag.xmi_id
              end
            end
          end
          children_pks_diags = package_flat_diagrams.call(
            lutaml_document.packages.map(&:children_packages).flatten,
          )

          document.attributes["lutaml_figure_id"] = package_flat_diagrams
            .call(lutaml_document.packages)
            .merge(children_pks_diags)
        end

        def add_model_anchor_context(context, root_package)
          packages = model_packages(root_package)
          context["additional_context"]["model_anchors"] =
            model_reference_targets(packages)
              .merge(model_anchors(packages))
              .merge(model_stub_anchors(root_package))
        end

        # Ids the XMI templates link to (attribute types, association ends),
        # including ones the XMI never defines. Unnamed; anchors override.
        def model_reference_targets(packages)
          model_entities(packages).each_with_object({}) do |entity, targets|
            Array(entity_list(entity, :attributes)).each do |attribute|
              add_model_anchor(targets, object_xmi_id(attribute), nil)
            end
            Array(entity_list(entity, :associations)).each do |association|
              add_model_anchor(targets, association_target(association), nil)
            end
          end
        end

        def model_entities(packages)
          packages.flat_map do |package|
            MODEL_COLLECTIONS.flat_map do |collection|
              Array(entity_list(package, collection))
            end
          end
        end

        def entity_list(object, collection)
          object.public_send(collection) if object.respond_to?(collection)
        end

        def association_target(association)
          return unless association.respond_to?(:member_end_xmi_id)

          association.member_end_xmi_id
        end

        def model_packages(root_package)
          packages_tree(root_package)
            .compact
            .uniq { |package| package_key(package) }
        end

        def packages_tree(package)
          [package, *child_packages(package).flat_map do |child|
            packages_tree(child)
          end]
        end

        def child_packages(package)
          Array(package.packages).compact.uniq { |child| package_key(child) }
        end

        def package_key(package)
          xmi_id = package.xmi_id if package.respond_to?(:xmi_id)
          xmi_id || package.name
        end

        def model_anchors(packages)
          collections = %w[classes enums data_types]
          packages.each_with_object({}) do |package, anchors|
            add_model_anchor(anchors, object_xmi_id(package), package.name)
            collections.each do |collection|
              next unless package.respond_to?(collection)

              Array(package.public_send(collection)).each do |entity|
                add_model_anchor(anchors, object_xmi_id(entity), entity.name)
              end
            end
          end
        end

        def object_xmi_id(object)
          object.xmi_id if object.respond_to?(:xmi_id)
        end

        def add_model_anchor(anchors, xmi_id, name)
          anchors[xmi_id] = name if xmi_id.is_a?(String) && !xmi_id.empty?
        end

        def model_stub_anchors(root_package)
          xmi_root_model = root_package.instance_variable_get(:@xmi_root_model)
          Array(xmi_root_model&.extension&.ea_stub)
            .each_with_object({}) do |stub, anchors|
              add_model_anchor(anchors, stub.id, stub.name)
            end
        end
      end
    end
  end
end
