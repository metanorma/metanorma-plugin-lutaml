# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # The EXPRESS vocabulary svgmap figures carry hidden bibliography
      # entries (bibitemid "express_<schema>.<entity>") whose declarations
      # live on the owning member's section pages as <schema>.<entity>
      # followed by that member's edition suffix chain. Register the
      # collection renderer's reference-anchor resolver for this family,
      # so EXPRESS figure hotspot links bind to the declaration pages
      # instead of falling to the reference list (metanorma#656 family;
      # the core renderer registers no resolvers of its own).
      #
      # On section-split pages the split pass suffixes the hidden
      # bibitems per page, so the svgmap eref's bibitemid carries the
      # citing page's own suffix chain after the entity name
      # ("express_geometry_schema.line_ISO_DIS_10303-108_2025_..._Annex_D_...").
      # Lookup therefore walks prefixes from the full name down to
      # "<schema>.<entity>", first unique match wins - the shortest
      # candidate is the declaration closest to the asked entity.
      module ExpressHotspotAnchor
        Metanorma::Collection::Renderer
          .register_reference_anchor_resolver do |bibitemid, lookup|
            next unless bibitemid.start_with?("express_")

            name = bibitemid.sub(/\Aexpress_/, "")
            schema_part, entity_full = name.include?(".") ? name.split(".", 2) : [nil, name]

            # The entity name is fixed; only the page-stamp suffix chain
            # after it is stripped. A stamp segment announces itself with
            # an uppercase letter or a digit (ISO_DIS_10303-108_2025,
            # Annex_D, EXPRESS-G_diagrams, iso10303-9002) - entity names
            # are lowercase snake_case, so the trim can never migrate the
            # asked entity onto a different declaration (#825: an
            # undeclared line_segment must stay untargeted, not adopt
            # line's record).
            entity = stamp_trim(entity_full)
            asked = [schema_part, entity_full].compact.join(".")
            candidate = [schema_part, entity].compact.join(".")
            lookup.call(asked) || lookup.call(candidate)
          end

        # Drops the trailing stamp segments: everything from the first
        # underscore-segment carrying an uppercase letter or a digit.
        def self.stamp_trim(entity_full)
          segments = entity_full.split("_")
          kept = segments.take_while { |segment| segment !~ /[A-Z0-9]/ }
          kept.empty? ? entity_full : kept.join("_")
        end
      end
    end
  end
end
