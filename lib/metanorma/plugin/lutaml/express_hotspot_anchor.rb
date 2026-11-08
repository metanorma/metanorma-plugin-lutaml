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
      module ExpressHotspotAnchor
        Metanorma::Collection::Renderer
          .register_reference_anchor_resolver do |bibitemid, lookup|
            next unless bibitemid.start_with?("express_")

            lookup.call(bibitemid.sub(/\Aexpress_/, ""))
          end
      end
    end
  end
end
