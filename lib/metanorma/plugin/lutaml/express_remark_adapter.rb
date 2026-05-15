# frozen_string_literal: true

require "expressir"

module Metanorma
  module Plugin
    module Lutaml
      module ExpressRemarkAdapter
        def self.relative_path_prefix(options, model)
          return if options.nil? || options["document"].nil?

          document = options["document"]
          file_path = File.dirname(model.file)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || ".",
          )
          resolved = document.path_resolver
            .system_path(file_path, docfile_directory)
          File.expand_path(resolved, docfile_directory)
        end

        def self.for(model)
          case model
          when Expressir::Model::Cache
            CachedRepoAdapter.new(model)
          when Expressir::Model::Repository, Expressir::Model::ExpFile
            RepoAdapter.new(model)
          when Expressir::Model::ModelElement
            ModelAdapter.new(model)
          else
            NullAdapter.new(model)
          end
        end

        class Base
          def initialize(model)
            @model = model
          end

          def unwrap
            @model
          end

          def decorate_remarks(options)
            decorate_own_remarks(options)
            decorate_child_remark_items(options)
            traverse_children(options)
          end

          private

          def decorate_own_remarks(options)
            @model.remarks = ExpressRemarksDecorator.decorate_array(
              @model.remarks, options
            )
          end

          def decorate_child_remark_items(options)
            return unless @model.is_a?(Expressir::Model::HasRemarkItems)

            @model.remark_items&.each do |ri|
              ri.remarks = ExpressRemarksDecorator.decorate_array(
                ri.remarks, options
              )
            end
          end

          def traverse_children(options)
            @model.children&.each do |child|
              next unless traversable?(child)

              ExpressRemarkAdapter.for(child).decorate_remarks(options)
            end
          end

          def traversable?(child)
            child.is_a?(Expressir::Model::ModelElement) &&
              !child.is_a?(Expressir::Model::Declarations::RemarkItem)
          end
        end

        class RepoAdapter < Base
          def decorate_remarks(options)
            @model.schemas.each do |schema|
              options["relative_path_prefix"] =
                ExpressRemarkAdapter.relative_path_prefix(options, schema)
              ExpressRemarkAdapter.for(schema).decorate_remarks(options)
            end
          end
        end

        class CachedRepoAdapter < Base
          def unwrap
            @model.content
          end

          def decorate_remarks(options)
            ExpressRemarkAdapter.for(@model.content).decorate_remarks(options)
          end
        end

        class ModelAdapter < Base; end

        class NullAdapter
          def initialize(_model); end

          def unwrap; end

          def decorate_remarks(_options); end
        end
      end
    end
  end
end
