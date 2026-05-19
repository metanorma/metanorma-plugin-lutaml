# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module XmiContextBuilder
        def create_context_object( # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          lutaml_document, additional_context, options,
          context_name = "context"
        )
          root_package = package_level(lutaml_document.to_liquid,
                                       options.package_root_level || 1)
          contexts = create_default_context_object(
            context_name, root_package, additional_context, options
          )

          if options.packages.nil?
            contexts[context_name]["render_nested_packages"] = true
            contexts[context_name]["packages"] = root_package.packages
            add_model_anchor_context(contexts[context_name], root_package,
                                     options)

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
          add_model_anchor_context(contexts[context_name], root_package,
                                   options)

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
              .merge("external_classes" => options.external_classes),
            "skip_unrecognized_connector" => !!options
              .skip_unrecognized_connector,
          }
          contexts
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

        def add_model_anchor_context(context, root_package, options)
          context["additional_context"]["model_anchors"] =
            model_anchors(model_packages(root_package))
          context["additional_context"]["rendered_model_anchors"] =
            model_anchors(rendered_packages(context, options))
        end

        def model_packages(root_package)
          packages_tree(root_package)
            .compact
            .uniq { |package| package.xmi_id || package.name }
        end

        def rendered_packages(context, options)
          packages = []
          packages.concat(Array(context["root_packages"])) if options.include_root
          packages.concat(Array(context["packages"]))
          if context["render_nested_packages"]
            packages = packages.flat_map { |package| packages_tree(package) }
          end
          packages.compact.uniq { |package| package.xmi_id || package.name }
        end

        def packages_tree(package)
          [package, *child_packages(package).flat_map do |child|
            packages_tree(child)
          end]
        end

        def child_packages(package)
          children = []
          if package.respond_to?(:children_packages)
            children.concat(Array(package.children_packages))
          end
          children.concat(Array(package.packages)) if package.respond_to?(:packages)
          children.compact.uniq { |child| child.xmi_id || child.name }
        end

        def model_anchors(packages)
          packages.each_with_object({}) do |package, anchors|
            add_model_anchor(anchors, package.xmi_id, package.name)
            %w[classes enums data_types].each do |collection|
              next unless package.respond_to?(collection)

              Array(package.public_send(collection)).each do |entity|
                add_model_anchor(anchors, entity.xmi_id, entity.name)
              end
            end
          end
        end

        def add_model_anchor(anchors, xmi_id, name)
          anchors[xmi_id] = name if xmi_id && !xmi_id.empty?
        end
      end
    end
  end
end
