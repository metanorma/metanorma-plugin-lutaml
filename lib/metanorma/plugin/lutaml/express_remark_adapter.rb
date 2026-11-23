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

        # Keep the pre-split remarks surface used by existing templates and
        # promoted prose. Placed comments retain their source-only placement.
        def self.schema_remarks(schema)
          remarks = schema.remarks.to_a
          remarks + schema_tail_remarks(schema)
            .reject { |text| remarks.include?(text) }
        end

        def self.schema_tail_remarks(schema)
          return [] unless schema.respond_to?(:untagged_remarks)

          Array(schema.untagged_remarks).filter_map do |remark|
            next if remark.respond_to?(:placement) && remark.placement

            remark.text if remark.tail?
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
          def initialize(schema, format, prose, format_name)
            @schema = schema
            @format = format
            @prose = prose
            @format_name = format_name
            @schema_head = %r{
              \ASCHEMA\s+#{Regexp.escape(schema.id.to_s)}[^\n;]*;[^\n]*
            }x
          end

          # The prose block is formatted at call time from the item's
          # current remarks: re-decoration for another document rewrites
          # the remarks (figure staging), and a process rendering several
          # documents off one index must print each document's own
          # resolution — a block captured at decoration time would print
          # the first document's forever (#381).
          def call
            block = SOURCE_FORMATTERS.fetch(@format_name).format(@prose)
            printed = format_without_prose
            return printed if printed.include?(block)
            return printed unless printed.match?(@schema_head)

            printed.sub(@schema_head) { |line| "#{line}\n\n#{block}" }
          end

          private

          def format_without_prose
            items = @schema.remark_items
            remarks = @schema.remarks
            @schema.remark_items = items - [@prose]
            # Recent Expressir formatters print the schema's own remarks
            # independently of remark_items. Suppress both copies while
            # formatting, then splice the promoted prose at the head.
            @schema.remarks = []
            @format.call.to_s
          ensure
            @schema.remark_items = items
            @schema.remarks = remarks
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
            expose_schema_tail_remarks
            prose = promote_schema_prose
            stash_figure_remarks(options)
            # The spliced prose blocks are built here, after the figure
            # rewrite, so they print the resolved targets — and rebuilt
            # on every decoration, so a process rendering several
            # documents off one index prints each document's own
            # resolution rather than the first document's (#381).
            hide_from_source_formats(prose) if prose
          end

          private

          # Expressir now stores untagged END_SCHEMA comments separately.
          # Preserve the legacy template-facing remarks array.
          def expose_schema_tail_remarks
            return unless @model.is_a?(Expressir::Model::Declarations::Schema)

            @model.class.ensure_liquid_registered!
            drop = @model.class.base_drop_class
            drop.include(SchemaRemarks) unless drop.include?(SchemaRemarks)
          end

          # A bare (*"Schema_name" ...*) remark is the schema-level prose:
          # expressir models it in Schema#remarks, not as a RemarkItem, so
          # renders that walk remark_items (every clause-4 template) drop
          # it (iso-10303#720). Promote it to a leading RemarkItem keyed
          # by the schema path, the same way an entity-tagged remark names
          # its target.
          #
          # Since expressir 2.4.59 (expressir#603) the formatters print
          # remark_items, so the synthetic item is hidden from them — the
          # caller splices it back into the printed source in its standard
          # position (right after the SCHEMA line) once the figure rewrite
          # has run, so the source listing shows the resolved prose
          # exactly once.
          def promote_schema_prose
            return unless @model.is_a?(Expressir::Model::Declarations::Schema)

            items = @model.remark_items.to_a
            existing = items.find { |ri| ri.id == @model.id }
            return existing if existing

            remarks = ExpressRemarkAdapter.schema_remarks(@model)
            return if remarks.empty?

            prose = Expressir::Model::Declarations::RemarkItem.new(
              id: @model.id,
              remarks: remarks,
            )
            @model.remark_items = [prose] + items
            prose
          end

          # Each format is still computed lazily and memoized by expressir;
          # it just runs without the promoted item in remark_items. The
          # prose block itself is formatted per render by the splicer.
          def hide_from_source_formats(prose)
            SOURCE_FORMATS.each do |name|
              splice_prose_into_format(name, prose)
            end
          end

          def splice_prose_into_format(name, prose)
            format = @model.method(name)
            splicer = ProseSplicer.new(@model, format, prose, name)

            @model.define_singleton_method(name) { splicer.call }
          end

          # Stages the schema's EXPRESS-G figures into the directory the
          # document's image targets resolve against and rewrites the
          # remark texts to the staged files' bare basenames — the
          # plugin never sets, checks, or restores the document's
          # imagesdir (metanorma-plugin-lutaml#371): every figure macro
          # the templates print, inside the listing or out, carries a
          # bare target that resolves as-is.
          def stash_figure_remarks(options)
            document = options["document"]
            schema_directory = ExpressRemarkAdapter.schema_imagesdir(
              options, @model
            )
            return unless document && schema_directory
            return unless @model.is_a?(Expressir::Model::Declarations::Schema)

            resolver = ExpressRemarkFigures::TargetResolver.new(
              document.attributes["docfile"],
              ExpressRemarkFigures.effective_imagesdir(document),
              schema_directory,
            )
            @model.remark_items.each do |item|
              rewrite_item(item, resolver)
            end
            # Figures also ride remarks tagged to nested declarations — an
            # entity- or attribute-tagged remark hangs off that element,
            # not the schema (solid_shape_element_schema carries its
            # L-section figure blocks on an attribute remark). And under
            # expressir 2.4.70+ (the untagged-remarks rework) such owner
            # remarks sit on the owner's `remarks` string array with
            # `remark_items` EMPTY, so both channels must be rewritten:
            # the corpus templates print `attribute.remarks` directly.
            walk_remark_item_owners(Array(@model.children)) do |owner|
              if owner.respond_to?(:remark_items)
                owner.remark_items.each { |item| rewrite_item(item, resolver) }
              end
              next unless owner.respond_to?(:remarks) && owner.remarks.to_a.any?

              resolved = resolver.remarks(owner.remarks)
              owner.define_singleton_method(:expressg_figure_remarks) do
                resolved
              end
              owner.remarks = resolved
            end
            reset_format_memos
          end

          def rewrite_item(item, resolver)
            resolved = resolver.remarks(item.remarks)
            item.define_singleton_method(:expressg_figure_remarks) do
              resolved
            end
            # Resolve in place: the annex templates print `item.remarks`
            # verbatim, outside the listing and outside any accessor.
            item.remarks = resolved
          end

          def walk_remark_item_owners(elements, &block)
            elements.each do |element|
              next unless element.is_a?(Expressir::Model::ModelElement)
              # RemarkItems appear in their owner's children; they are
              # leaves for this purpose — re-entering one would resolve
              # its (already rewritten) remarks a second time.
              next if element.is_a?(Expressir::Model::Declarations::RemarkItem)

              has_items = element.respond_to?(:remark_items) && element.remark_items.to_a.any?
              has_remarks = element.respond_to?(:remarks) && element.remarks.to_a.any?
              block.call(element) if has_items || has_remarks
              walk_remark_item_owners(Array(element.children), &block)
            end
          end

          # expressir memoizes each printed source form in an ivar the
          # first time it is formatted. The prose block is re-spliced per
          # render, but the rest of the printed source — including the
          # __expressg figure blocks — comes from that memo, so a process
          # rendering several documents sharing one index must clear it
          # on re-decoration or every document after the first prints the
          # first document's figure targets (#381). expressir exposes no
          # reset API; these are its memo ivars.
          FORMAT_MEMO_IVARS = %i[
            @formatted
            @formatted_no_remarks
            @formatted_hyperlinked
            @formatted_hyperlinked_adoc
          ].freeze

          def reset_format_memos
            FORMAT_MEMO_IVARS.each do |ivar|
              @model.remove_instance_variable(ivar) if @model.instance_variable_defined?(ivar)
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
          # svgmap-synthesized targets that are ALREADY document-relative
          # (the drop-facing remark figures compose their targets through
          # the document's imagesdir directory, ExpressRemarkFigures),
          # doubling the directory segments and failing the
          # image-existence check (suma's dummy-collection repro). The
          # remark content is served by the listing-scoped attribute
          # entries emitted around each source block, which only affect
          # asciidoctor resolution inside the listing.
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

        module SchemaRemarks
          def remarks
            ExpressRemarkAdapter.schema_remarks(@object)
          end
        end

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
