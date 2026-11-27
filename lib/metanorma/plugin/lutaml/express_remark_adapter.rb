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
            @schema.remark_items = items - [@prose]
            @format.call(@schema).to_s
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
            prose = promote_schema_prose
            stash_figure_remarks(options)
            # The document faces are installed for every decorated schema:
            # figures ride remark items regardless of whether schema-level
            # prose exists, and expressir's own faces strip remarks since
            # 2.4.89. The spliced prose blocks are built after the figure
            # rewrite so they print the resolved targets — and rebuilt on
            # every decoration, so a process rendering several documents
            # off one index prints each document's own resolution rather
            # than the first document's (#381).
            install_document_faces
            splice_schema_prose(prose) if prose
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
            return if @model.remarks.to_a.empty?

            prose = Expressir::Model::Declarations::RemarkItem.new(
              id: @model.id,
              remarks: @model.remarks.dup,
            )
            @model.remark_items = [prose] + items
            prose
          end

          # The faces render per call. The plain face must reach the
          # model's expressir memo through the CLASS method — binding
          # `formatted` off the instance would resolve through the
          # singleton these very definitions install and recurse — so
          # it is bound from the class hierarchy instead.
          def document_faces
            class_formatted = @model.class
              .instance_method(:formatted).bind(@model)
            {
              formatted: ->(_schema) { class_formatted.call },
              formatted_hyperlinked: ->(schema) do
                DocumentSourceFormatter.format(schema)
              end,
              formatted_hyperlinked_adoc: ->(schema) do
                ExpressRemarkAdapter.hyperlinked_adoc(schema)
              end,
            }
          end

          # The faces are Schema-level (only Schema carries the formatted
          # methods); child-model decorations install nothing.
          def install_document_faces
            return unless @model.is_a?(Expressir::Model::Declarations::Schema)

            document_faces.each do |name, face|
              @model.define_singleton_method(name) { face.call(self) }
            end
          end

          # The splicer reprints each face without the promoted prose
          # item and splices the prose block back right after the
          # SCHEMA line — its standard position — so the listing shows
          # the resolved prose exactly once.
          def splice_schema_prose(prose)
            document_faces.each do |name, face|
              splicer = ProseSplicer.new(@model, face, prose, name)
              @model.define_singleton_method(name) { splicer.call }
            end
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

        class NullAdapter
          def initialize(_model); end

          def unwrap; end

          def decorate_remarks(_options); end
        end

        # Document faces for decorated schemas. expressir 2.4.89's
        # prebuilt SourceFormatter/AdocSourceFormatter faces print
        # without tagged description blocks (metanorma-cli#522,
        # expressir#704) — their `initialize` hard-codes no_remarks and
        # discards caller options. On a decorated schema the remark
        # items are the document content: the __expressg figure blocks
        # stage through them (#360/#371) and the schema prose prints
        # through the splicer. These subclasses restore the
        # remark-bearing form of the same faces — for the models this
        # adapter decorates only; undecorated prints keep expressir's
        # plain faces.
        #
        # The base face's round-trip form prints every remark item's
        # raw tag (`(*"schema.entity.__note" text *)`), but keyed prose
        # items print through the document's note machinery, not the
        # listing — so the faces drop the keyed __note/__example items
        # (metanorma-plugin-lutaml#429, the iso-10303 gate regression)
        # and keep the keyed __figure blocks, which stage the
        # EXPRESS-G figures.
        KEYED_PROSE_ITEM = /__(?:note|example)\z/.freeze

        class DocumentSourceFormatter < Expressir::Express::Formatter
          include Expressir::Express::HyperlinkFormatter

          def owner_tagged_blocks?
            false
          end

          def format_remark_item(node)
            return "" if node.id.to_s.match?(KEYED_PROSE_ITEM)

            super
          end
        end

        class DocumentAdocSourceFormatter < Expressir::Express::Formatter
          include Expressir::Express::AdocHyperlinkFormatter

          def owner_tagged_blocks?
            false
          end

          def format_remark_item(node)
            return "" if node.id.to_s.match?(KEYED_PROSE_ITEM)

            super
          end
        end

        # The adoc face's post-formatting chain, mirroring
        # Schema#formatted_hyperlinked_adoc.
        def self.hyperlinked_adoc(schema)
          mod = Expressir::Express::AdocHyperlinkFormatter
          text = DocumentAdocSourceFormatter.format(schema)
          mod.keep_opening_parentheses(
            mod.keep_plus_signs(mod.neutralise_stem_macros(text)),
          )
        end

        # The formatter family behind each source format, so the spliced
        # prose prints the way its format prints references. The
        # hyperlinked faces are the document formatters above —
        # expressir's prebuilt faces strip remarks since 2.4.89.
        SOURCE_FORMATTERS = {
          formatted: Expressir::Express::Formatter,
          formatted_hyperlinked: DocumentSourceFormatter,
          formatted_hyperlinked_adoc: DocumentAdocSourceFormatter,
        }.freeze
      end
    end
  end
end
