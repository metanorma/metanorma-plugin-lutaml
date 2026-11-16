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
      module ExpressSchemaListing
        SOURCE_BLOCK_HEADING = '[source%unnumbered,subs="+macros"]'
        # A dash run of two or more at line start: only such a run can
        # close a listing fence (asciidoctor closes a listing only on a
        # line of dashes of the SAME length as its opening fence).
        DASH_RUN_REGEXP = /\A(-{2,})/
        # Asciidoctor's shortest valid listing fence: a three-dash line
        # is not a block delimiter at all.
        MIN_FENCE_LENGTH = 4

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

          private

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
        # cannot be changed inside the listing itself.
        module DropMethods
          def formatted_hyperlinked_adoc_listing
            content = @object.formatted_hyperlinked_adoc.to_s
            fence = ExpressSchemaListing.fence(content)
            listing = [
              SOURCE_BLOCK_HEADING,
              fence,
              content,
              fence,
            ].join("\n")
            with_imagesdir_entries(listing)
          end

          private

          def with_imagesdir_entries(listing)
            return listing unless @object.respond_to?(:listing_imagesdir)

            dir = @object.listing_imagesdir
            return listing unless dir

            restore = @object.listing_imagesdir_restore
            closing = restore ? ":imagesdir: #{restore}" : ":!imagesdir:"
            ":imagesdir: #{dir}\n\n#{listing}\n\n#{closing}"
          end
        end
      end
    end
  end
end
