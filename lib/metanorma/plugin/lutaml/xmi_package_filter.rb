# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module XmiPackageFilter
        def sort_and_filter_out_packages(all_packages, options) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
          return all_packages if options.packages.nil?

          all_packages =
            filter_out_all_skipped_packages(options, all_packages)

          result = []
          select_supplied_packages_by_pattern(options, all_packages, result)
        end

        def filter_out_all_skipped_packages(options, all_packages) # rubocop:disable Metrics/AbcSize
          return all_packages if options.skip.nil?

          options.skip.each do |skip_package|
            entity_regexp = config_entity_regexp(skip_package)
            all_packages.delete_if do |package|
              package.name =~ entity_regexp
            end
          end

          all_packages
        end

        def select_supplied_packages_by_pattern(options, all_packages, result) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          options.packages.each do |package|
            entity_regexp = config_entity_regexp(package.name)
            all_packages.each do |p|
              if p.name&.match?(entity_regexp)
                result.push(p)
                all_packages.delete_if do |nest_package|
                  nest_package.name == p.name
                end
              end
            end
          end

          result
        end

        def package_entities(package, type)
          case type
          when "class" then package.classes
          when "enum" then package.enums
          when "data_type" then package.data_types
          else raise ArgumentError, "Unknown package entity type: #{type}"
          end
        end

        def package_hash(options, key)
          return {} unless options.packages

          options.packages
            .select { |p| p.collection_for(key) }
            .to_h { |p| [p.name, p.collection_for(key).to_h { |n| [n, true] }] }
        end

        def package_level(lutaml_document, level)
          return lutaml_document if level <= 0

          package_level(lutaml_document.packages.first, level - 1)
        end
      end
    end
  end
end
