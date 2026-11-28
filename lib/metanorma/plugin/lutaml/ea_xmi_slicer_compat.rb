# frozen_string_literal: true

# Carries the Ea::Xmi::Slicer primitive-types closure fix from
# lutaml/ea#280 until a released ea ships it (the change lands upstream
# in lutaml/ea; this shim retires on the first ea release that contains
# it). Without it the slicer's reference closure drops EA's primitive
# types: they live in the extension's <primitivetypes> block, which
# section_for maps to :drop, and their ids carry the EAJava_ prefix,
# which the slicer's EA_ID_RE does not match. A sliced klass table of
# a class whose inherited attributes reference gml::/xs:: primitives
# then renders the raw id (EAJava_gml__LengthType) where the
# whole-load path renders the type name (gml::LengthType) - the
# byte-parity gap the corpus gate exists to catch.
#
# Three pieces, mirroring the upstream change:
# - EA_ID_RE recognizes the EAJava_ id prefix, so references to the
#   primitives are collected;
# - the extension's primitivetypes/profiles blocks map to a gated
#   :primitivetypes section instead of :drop, so referenced entries
#   become keepable nodes;
# - closure keeps the ancestry of kept :primitivetypes nodes, so the
#   EA_PrimitiveTypes_Package wrappers survive the writer's
#   parent-key chain.
module Ea
  module Xmi
    class Slicer
      # The released slicer fix redefines EA_ID_RE with the EAJava_
      # alternative; when it is present, the whole shim retires.
      unless EA_ID_RE.source.include?("EAJava")
        remove_const :EA_ID_RE
        EA_ID_RE = /\A(?:EAID|EAPK|EAEM|EAJava)_[0-9A-Za-z_]+\z/
        private_constant :EA_ID_RE

        remove_const :GATED
        GATED = {
          model: ["packagedElement", "umldi:Diagram"].freeze,
          elements: ["element"].freeze,
          connectors: ["connector"].freeze,
          primitivetypes: ["packagedElement"].freeze,
          diagrams: ["diagram"].freeze,
        }.freeze
        private_constant :GATED

        remove_const :SECTION_CHILD
        SECTION_CHILD = {
          "elements" => :elements,
          "connectors" => :connectors,
          "primitivetypes" => :primitivetypes,
          "profiles" => :primitivetypes,
          "diagrams" => :drop,
        }.freeze
        private_constant :SECTION_CHILD

        class IndexHandler
          def section_for(name, current)
            return :model if name == "uml:Model"
            return :extension if name == "xmi:Extension"

            if current == :extension
              SECTION_CHILD.fetch(name, :drop)
            elsif current == :drop
              :drop
            else
              current
            end
          end
        end

        class GroupWriter
          def section_for(name, current)
            return :model if name == "uml:Model"
            return :extension if name == "xmi:Extension"

            if current == :extension
              SECTION_CHILD.fetch(name, :drop)
            elsif current == :drop
              :drop
            else
              current
            end
          end
        end

        # The slicer's closure with one extension: kept
        # :primitivetypes nodes keep their package ancestry, exactly
        # as :model nodes do - the writer's parent-key chain drops
        # children of unkept gated containers, so the
        # EA_PrimitiveTypes_Package wrappers have to be kept for a
        # referenced primitive to reach the slice. The method mirrors
        # the upstream one (whose Metrics allowances are grandfathered
        # in the ea gem) plus the single ancestry extension.
        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # rubocop:disable Metrics/BlockNesting
        ANCESTRY_SECTIONS = %i[model primitivetypes].freeze
        private_constant :ANCESTRY_SECTIONS

        def closure(nodes, seeds)
          keep = {}
          frontier = seeds.map { |i| [i, false] }
          until frontier.empty?
            id, via_links = frontier.pop
            next if keep[id]

            node = nodes[id]
            next unless node
            # links references only buy the connector record they name;
            # following them further pulled every relation's endpoints
            # into a class's closure (half the model per class)
            next if via_links && node.section != :connectors

            keep[id] = true
            node.refs.each { |r| frontier << [r, false] }
            node.links_refs.each { |r| frontier << [r, true] }
            # keeping a model element keeps its package ancestry
            next unless ANCESTRY_SECTIONS.include?(node.section)

            anc = nodes[node.parent_id]
            while anc && !keep[anc.id]
              keep[anc.id] = true
              unless anc.section == :model
                anc.refs.each { |r| frontier << [r, false] }
              end
              anc = nodes[anc.parent_id]
            end
          end
          keep_diagrams(nodes, keep)
          keep
        end
        # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
        # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # rubocop:enable Metrics/BlockNesting
      end
    end
  end
end
