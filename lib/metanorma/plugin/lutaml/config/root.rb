# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Config
        class Root < ::Lutaml::Model::Serializable
          attribute :packages, Package, collection: true
          attribute :render_style, :string
          attribute :ea_extension, :string, collection: true
          attribute :template_path, :string
          attribute :section_depth, :integer
          attribute :guidance, :string
          attribute :skip, :string, collection: true
          attribute :include_root, :boolean
          attribute :package_root_level, :integer
          attribute :render_nested_packages, :boolean
          attribute :external_classes, :hash

          yaml do
            map "packages", to: :packages,
                            with: {
                              from: :packages_from_yaml,
                              to: :packages_to_yaml,
                            }
            map "render_style", to: :render_style
            map "ea_extension", to: :ea_extension
            map "template_path", to: :template_path
            map "section_depth", to: :section_depth
            map "guidance", to: :guidance
            map "include_root", to: :include_root
            map "package_root_level", to: :package_root_level
            map "render_nested_packages", to: :render_nested_packages
            map "external_classes", to: :external_classes
          end

          def packages_from_yaml(model, values) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
            values.each do |value| # rubocop:disable Metrics/BlockLength
              if value.is_a?(Hash)
                if value.keys.first == "skip"
                  # contains skip key
                  model.skip ||= []
                  model.skip << value["skip"]
                else
                  # contains skip_tables or render_entities key
                  package = Package.new
                  package.name = value.keys.first
                  package_options = value[package.name]

                  if package_options.key?("skip_tables")
                    package_options["skip_tables"].each do |table|
                      package.skip_tables ||= []
                      package.skip_tables << table
                    end
                  end

                  if package_options.key?("render_entities")
                    package_options["render_entities"].each do |entity|
                      package.render_entities ||= []
                      package.render_entities << entity
                    end
                  end

                  model.packages ||= []
                  model.packages << package
                end
              else
                # only contains package name
                model.packages ||= []
                model.packages << Package.new(name: value)
              end
            end
          end

          def packages_to_yaml(model, doc) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
            doc["packages"] = []
            model.packages.each do |package|
              if package.skip_tables || package.render_entities # rubocop:disable Style/ConditionalAssignment
                doc["packages"] << {
                  package.name => package.to_yaml_hash
                    .reject { |k| k == "name" },
                }
              else
                doc["packages"] << package.name
              end
            end

            model.skip.each do |skip_package|
              doc["packages"] << { "skip" => skip_package }
            end
          end
        end
      end
    end
  end
end
