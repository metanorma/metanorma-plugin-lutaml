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
      end
    end
  end
end
