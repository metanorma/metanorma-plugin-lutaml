# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # The liquid-facing source listing for a schema: a complete
      # asciidoctor source block around Schema#formatted_hyperlinked_adoc
      # (including the schema's own remark, spliced in by the adapter),
      # whose fence is computed from the content so that no dash run
      # inside remark prose can close the listing early — 43 of the 125
      # SRL schema listings close early under the templates' hardcoded
      # two-dash fence — plus the imagesdir attribute entries that let
      # the schema's relative image macros resolve as written, with no
      # build path in the remark text (TRThurman's source-fidelity
      # requirements).
      #
      # The schema's EXPRESS-G figure remark (`__expressg`, carrying the
      # svgmap figure blocks) is not source: it is extraction fodder.
      # Inside the fence it prints as listing text and the figures are
      # lost (metanorma/metanorma-plugin-lutaml#360 — the pre-0.7.70
      # listings only rendered figures because their hardcoded fence
      # closed early, an accident the computed fence removed). The
      # listing therefore prints the EXPRESS source only, and the figure
      # blocks are re-emitted after the fence as real adoc, still inside
      # the schema's imagesdir attribute entries so the image macros
      # resolve as written.
      module ExpressSchemaListing
        SOURCE_BLOCK_HEADING = '[source%unnumbered,subs="+macros"]'
        # A dash run of two or more at line start: only such a run can
        # close a listing fence (asciidoctor closes a listing only on a
        # line of dashes of the SAME length as its opening fence).
        DASH_RUN_REGEXP = /\A(-{2,})/
        # Asciidoctor's shortest valid listing fence: a three-dash line
        # is not a block delimiter at all.
        MIN_FENCE_LENGTH = 4
        # An EXPRESS-G figure remark as the source formatter prints it:
        # the `(*"...__expressg"` header at line start, the figure body,
        # and the closing `*)` on its own line. One blank line before the
        # block and the newline after it go with it, so the removal does
        # not stack blank lines around the fence. Remarks do not nest and
        # cannot contain `*)`, so the first line-anchored `*)` closes.
        EXPRESSG_REMARK_REGEXP =
          %r{^\n?\(\*"[^\n]*__expressg[^\n]*"\n.*?^\*\)\n?}m
        # The same remark with the figure body captured.
        EXPRESSG_FIGURE_BODY_REGEXP =
          %r{^\(\*"[^\n]*__expressg[^\n]*"\n(.*?)^\*\)}m

        class << self
          # Makes formatted_hyperlinked_adoc_listing available to liquid
          # templates. lutaml-model materializes the schema's drop class
          # from its `liquid` mappings, which cannot be extended
          # declaratively from outside, so the drop gains the method here.
          # Applied before the first template render: update_repo
          # decorates every loaded repository, and Liquid memoizes a
          # drop class's invokable methods on first render.
          def apply
            schema = schema_class
            return unless schema

            schema.ensure_liquid_registered!
            drop_class = schema.base_drop_class
            return unless drop_class
            return if drop_class.include?(DropMethods)

            drop_class.include(DropMethods)
          end

          def fence_length(content)
            longest = content.each_line
              .filter_map { |line| line[DASH_RUN_REGEXP, 1]&.length }
              .max || 2
            [longest + 1, MIN_FENCE_LENGTH].max
          end

          def fence(content)
            "-" * fence_length(content)
          end

          # Splits a printed schema into its listing source and the
          # EXPRESS-G figure blocks: every `__expressg` remark is lifted
          # out whole and its figure body (the svgmap figure adoc, as
          # written) is kept for emission after the listing. The body's
          # trailing newline belongs to the remark's closing marker, not
          # to the content, and the body's EXPRESS nesting indent comes
          # off as well — asciidoctor opens a delimited block only on a
          # delimiter at column 0, so an indented `[.svgmap]`/`====`
          # figure prints as text. Relative indentation within the body
          # is kept. Content without an EXPRESS-G remark passes through
          # unchanged.
          def extract_expressg_figures(content)
            figures = content.scan(EXPRESSG_FIGURE_BODY_REGEXP)
              .map { |match| dedent(match.first.strip) }
            stripped = content.gsub(EXPRESSG_REMARK_REGEXP, "")
            [stripped, figures.reject(&:empty?)]
          end

          private

          def dedent(body)
            indent = body.each_line
              .reject { |line| line.strip.empty? }
              .filter_map { |line| line[/\A[ \t]+/] }
              .min_by(&:length)
            return body unless indent

            body.gsub(/^#{Regexp.escape(indent)}/, "")
          end

          def schema_class
            return unless defined?(::Expressir::Model::Declarations::Schema)

            ::Expressir::Model::Declarations::Schema
          end
        end

        # Methods mixed into the schema's liquid drop class. The
        # decorated schema carries its imagesdir values as singleton
        # readers (the drop has no access to the asciidoctor document);
        # attribute entries are emitted immediately before and after the
        # block, since attribute entries take effect sequentially and
        # cannot be changed inside the listing itself. The extracted
        # EXPRESS-G figures go after the block, still inside those
        # entries, so their relative image macros resolve as written.
        module DropMethods
          def formatted_hyperlinked_adoc_listing
            source, figures = ExpressSchemaListing
              .extract_expressg_figures(
                @object.formatted_hyperlinked_adoc.to_s,
              )
            fence = ExpressSchemaListing.fence(source)
            listing = [
              SOURCE_BLOCK_HEADING,
              fence,
              source,
              fence,
            ].join("\n")
            with_imagesdir_entries(listing, figures)
          end

          private

          def with_imagesdir_entries(listing, figures = [])
            body = [listing, *figures].reject(&:empty?).join("\n\n")
            return body unless @object.respond_to?(:listing_imagesdir)

            dir = @object.listing_imagesdir
            return body unless dir

            restore = @object.listing_imagesdir_restore
            closing = restore ? ":imagesdir: #{restore}" : ":!imagesdir:"
            ":imagesdir: #{dir}\n\n#{body}\n\n#{closing}"
          end
        end
      end
    end
  end
end
