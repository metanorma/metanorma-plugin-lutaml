# frozen_string_literal: true

require "pathname"
require_relative "utils"

module Metanorma
  module Plugin
    module Lutaml
      # Prunes large XMI sources to per-class slices before the parse
      # pipeline ever sees them.
      #
      # EA exports of plateau scale reach ~100 MB, more than half of it
      # diagram presentation data, and fully materializing the Xmi tree
      # plus the Ea graph costs 10+ GB of live objects - more than a
      # standard build runner has. Ea::Xmi::Slicer streams the source
      # once and emits one standalone slice per referenced class, so
      # each klass-table macro parses a few MB containing exactly its
      # class's subgraph, and the existing parse path is unchanged.
      #
      # Activation is opt-in through the `lutaml-xmi-slices` document
      # attribute; without it nothing is sliced and behavior is
      # byte-for-byte the full-file path.
      module XmiSliceRegistry
        MACRO_REGEXP = /lutaml_(?:klass|enum)_table::([^\[<]+)\[([^\]]*)\]/
        MIN_SOURCE_BYTES = 2 * 1024 * 1024

        class << self
          # Rewrites (xmi_path, name_path) to the class's slice when one
          # was prepared, else returns the inputs unchanged.
          def rewrite(xmi_path, name_path)
            return [xmi_path, name_path] unless @registry

            entry = @registry[xmi_path]
            return [xmi_path, name_path] unless entry

            slice = entry[name_path] || entry[bare_name(name_path)]
            return [xmi_path, name_path] unless slice

            [slice, bare_name(name_path)]
          end

          def slice?(xmi_path)
            return false unless @registry

            entry = @registry[xmi_path]
            !entry.nil? && entry.any?
          end

          def reset!
            @registry = nil
            @dir&.rmtree if @dir&.exist?
            @dir = nil
          end

          def prepare(document, lines) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
            reset!
            # header attributes are parsed after preprocessors run, so
            # the opt-in is also detected in the raw lines
            return unless enabled?(document, lines)

            groups = collect_groups(document, lines)
            return if groups.empty?

            @registry = {}
            require "tmpdir"
            @dir = Pathname.new(Dir.mktmpdir("lutaml_xmi_slices"))
            groups.each do |path, entries|
              next unless File.size(path) >= MIN_SOURCE_BYTES

              slice_groups = {}
              macro_keys = {}
              entries.each do |key, value|
                if value.is_a?(Array) # group_key => wanted pairs
                  slice_groups[key] = value
                else # macro key => group_key
                  (macro_keys[value] ||= []) << key
                end
              end
              slice_paths = ::Ea::Xmi::Slicer.slices(
                path, slice_groups, dir: @dir.join(digest(path)).to_s
              )
              @registry[path] ||= {}
              macro_keys.each do |group_key, keys|
                slice = slice_paths[group_key]
                next unless slice

                keys.each { |k| @registry[path][k] = slice }
              end
            end
          end

          private

          def enabled?(document, lines)
            document.attributes["lutaml-xmi-slices"] ||
              lines.any? { |l| l.match?(/\A:lutaml-xmi-slices:/) }
          end

          # Slices are grouped per package, not per class: the tables
          # of classes in one package share most of their closure
          # (partners, connectors, ancestors), so a package slice
          # carries each shared subtree once instead of once per class.
          def collect_groups(document, lines)
            groups = Hash.new { |h, k| h[k] = {} }
            lines.each do |line|
              MACRO_REGEXP.match(line) do |m|
                path = Utils.relative_file_path(document, m[1].strip)
                package = m[2][/&?(?:^|,)package="([^"]+)"/, 1]
                name = m[2][/&?(?:^|,)name="([^"]+)"/, 1]
                next if name.nil?

                key = package ? "#{package}::#{name}" : name
                group_key = package || "_"
                (groups[path][group_key] ||= []) << [package, name]
                groups[path][key] = group_key
              end
            end
            groups
          end

          def bare_name(name_path)
            name_path.to_s.split("::").last
          end

          def digest(text)
            require "digest"
            Digest::SHA256.hexdigest(text.to_s)[0, 16]
          end
        end
      end

      # Scans the fully expanded document source once, before parsing,
      # and prepares per-class XMI slices for every table macro. The
      # lines pass through unchanged; reading them through the incoming
      # reader expands include directives, which is where plateau
      # documents keep their table macros.
      class XmiSlicesPreprocessor < ::Asciidoctor::Extensions::Preprocessor
        def process(document, reader)
          input_lines = reader.readlines
          XmiSliceRegistry.prepare(document, input_lines)
          reader.class.new(document, input_lines)
        end
      end
    end
  end
end
