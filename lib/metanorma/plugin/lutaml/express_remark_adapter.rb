# frozen_string_literal: true

require "expressir"

module Metanorma
  module Plugin
    module Lutaml
      module ExpressRemarkAdapter
        # Resolves the directory of a schema's source file the way the
        # document resolves any referenced path (the document's
        # PathResolver#system_path against the docfile directory). The
        # result is the schema's imagesdir: image macros in the schema's
        # remarks then resolve as written and no build path enters the
        # remark text (TRThurman's source-fidelity requirement: the
        # 0.7.x path rewriting leaked /home/runner/... into 639 image
        # macros and 3,470 remark headers across the SRL corpus).
        def self.schema_imagesdir(options, model)
          document = options && options["document"]
          return unless document
          return unless model.respond_to?(:file) && model.file

          document.path_resolver.system_path(
            File.dirname(model.file),
            File.dirname(document.attributes["docfile"] || "."),
          )
        end

        def self.for(model)
          case model
          when Expressir::Model::Cache
            CachedRepoAdapter.new(model)
          when Expressir::Model::Repository, Expressir::Model::ExpFile
            RepoAdapter.new(model)
          when Expressir::Express::LazyRepository
            # Remark decoration walks real models; hydrate the lazy
            # repository up front. The artifact still wins on load —
            # wire JSON hydrates per file instead of a full re-parse.
            RepoAdapter.new(model.to_eager)
          when Expressir::Model::ModelElement
            ModelAdapter.new(model)
          else
            NullAdapter.new(model)
          end
        end

        # Prints one source format of a decorated schema: the format runs
        # without the promoted prose item (so expressir >= 2.4.59, which
        # formats remark_items, does not double-print it), and the prose
        # block is then spliced into the printed source right after the
        # SCHEMA line — its standard position. When the format's own print
        # already carries the block (the print of remark_items depends on
        # the expressir version), the output stands as printed: the prose
        # shows exactly once either way.
        class ProseSplicer
          def initialize(schema, format, prose, block)
            @schema = schema
            @format = format
            @prose = prose
            @block = block
            @schema_head = %r{
              \ASCHEMA\s+#{Regexp.escape(schema.id.to_s)}[^\n;]*;[^\n]*
            }x
          end

          def call
            printed = format_without_prose
            return printed if printed.include?(@block)
            return printed unless printed.match?(@schema_head)

            printed.sub(@schema_head) { |line| "#{line}\n\n#{@block}" }
          end

          private

          def format_without_prose
            items = @schema.remark_items
            @schema.remark_items = items - [@prose]
            @format.call.to_s
          ensure
            @schema.remark_items = items
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
            promote_schema_prose
            stash_listing_imagesdir(options)
          end

          private

          # A bare (*"Schema_name" ...*) remark is the schema-level prose:
          # expressir models it in Schema#remarks, not as a RemarkItem, so
          # renders that walk remark_items (every clause-4 template) drop
          # it (iso-10303#720). Promote it to a leading RemarkItem keyed
          # by the schema path, the same way an entity-tagged remark names
          # its target.
          #
          # Since expressir 2.4.59 (expressir#603) the formatters print
          # remark_items, so the synthetic item is hidden from them — and
          # then spliced back into the printed source in its standard
          # position (right after the SCHEMA line), so the source listing
          # shows the prose exactly once, as written.
          def promote_schema_prose
            return unless @model.is_a?(Expressir::Model::Declarations::Schema)
            return if @model.remarks.to_a.empty?

            items = @model.remark_items.to_a
            return if items.any? { |ri| ri.id == @model.id }

            prose = Expressir::Model::Declarations::RemarkItem.new(
              id: @model.id,
              remarks: @model.remarks.dup,
            )
            @model.remark_items = [prose] + items
            hide_from_source_formats(prose)
          end

          # Each format is still computed lazily and memoized by expressir;
          # it just runs without the promoted item in remark_items.
          def hide_from_source_formats(prose)
            blocks = SOURCE_FORMATS.to_h do |name|
              [name, SOURCE_FORMATTERS[name].format(prose)]
            end
            SOURCE_FORMATS.each do |name|
              splice_prose_into_format(name, prose, blocks[name])
            end
          end

          def splice_prose_into_format(name, prose, block)
            format = @model.method(name)
            splicer = ProseSplicer.new(@model, format, prose, block)

            @model.define_singleton_method(name) { splicer.call }
          end

          # The per-schema imagesdir for the listing's attribute entries
          # (formatted_hyperlinked_adoc_listing), plus the document's
          # imagesdir at decoration time so the listing can restore it
          # after the schema's content. The values ride on the schema as
          # singleton readers: the liquid drop has no access to the
          # asciidoctor document.
          def stash_listing_imagesdir(options)
            document = options["document"]
            dir = ExpressRemarkAdapter.schema_imagesdir(options, @model)
            previous = document && document.attributes["imagesdir"]
            @model.define_singleton_method(:listing_imagesdir) { dir }
            @model.define_singleton_method(:listing_imagesdir_restore) do
              previous
            end
          end
        end

        class RepoAdapter < Base
          def decorate_remarks(options)
            @model.schemas.each do |schema|
              ExpressRemarkAdapter.for(schema).decorate_remarks(options)
            end
          end

          private

          # NO document-level imagesdir here: metanorma's figure
          # absolutization joins document.attributes["imagesdir"] with
          # svgmap-synthesized targets that are ALREADY docfile-relative
          # (the express-g assembly writes `../../schemas/...`), doubling
          # the directory segments and failing the image-existence check
          # (suma's dummy-collection repro). The remark content is served
          # by the listing-scoped attribute entries emitted around each
          # source block, which only affect asciidoctor resolution inside
          # the listing.
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

        SOURCE_FORMATS = %i[
          formatted formatted_hyperlinked formatted_hyperlinked_adoc
        ].freeze

        # The formatter family behind each source format, so the spliced
        # prose prints the way its format prints references.
        SOURCE_FORMATTERS = {
          formatted: Expressir::Express::Formatter,
          formatted_hyperlinked: Expressir::Express::SourceFormatter,
          formatted_hyperlinked_adoc: Expressir::Express::AdocSourceFormatter,
        }.freeze
      end
    end
  end
end
