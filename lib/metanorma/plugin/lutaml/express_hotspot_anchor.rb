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
            rec = lookup.call(name)
            # Cut at the LAST underscore: page-suffix chains carry doubled
            # underscores ("..._Annex_D__informative__EXPRESS-G_diagrams"),
            # and a trailing "_" defeats /_[^_]+\z/ entirely - the name
            # would never shrink and the walk would never end (#346).
            while rec.nil? && (idx = name.rindex("_"))
              name = name[0...idx]
              rec = lookup.call(name)
            end
            rec
          end
      end
    end
  end
end
