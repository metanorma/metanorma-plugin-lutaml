# frozen_string_literal: true

require "pathname"
require_relative "utils"

module Metanorma
  module Plugin
    module Lutaml
      # Loads the XMI sources of table macros partially, through
      # Ea::Xmi.load_graph's partial mode.
      #
      # EA exports of plateau scale reach ~100 MB, more than half of it
      # diagram presentation data, and fully materializing the Xmi tree
      # plus the Ea graph costs 10+ GB of live objects - more than a
      # standard build runner has. With the `lutaml-ea-xmi-load` document
      # attribute set to `partial`, every klass and enum table macro's
      # (package, name) pair seeds a per-package reference closure; one
      # streaming pass per source assembles the closures in memory and
      # each macro parses only its own package's slice. Nothing is
      # written to disk.
      #
      # Without the attribute nothing is preloaded and behavior is
      # byte-for-byte the whole-load path.
      module XmiPartialLoadRegistry
        MACRO_REGEXP = /lutaml_(?:klass|enum)_table::([^\[<]+)\[([^\]]*)\]/
        MIN_SOURCE_BYTES = 2 * 1024 * 1024

        class << self
          # Rewrites (xmi_path, name_path) to the partial-load form of
          # the macro's class: [path, bare name, slice token]. The
          # token is nil when no slice was prepared, in which case the
          # macro whole-loads the source unchanged.
          def rewrite(xmi_path, name_path)
            return [xmi_path, name_path, nil] unless @registry

            entry = @registry[xmi_path]
            return [xmi_path, name_path, nil] unless entry

            group_key = entry[name_path] || entry[bare_name(name_path)]
            return [xmi_path, name_path, nil] unless group_key

            [xmi_path, bare_name(name_path), [xmi_path, group_key]]
          end

          # The prepared slice for a token from #rewrite.
          def slice_string(token)
            @slices[token]
          end

          def slice?(xmi_path)
            return false unless @registry

            entry = @registry[xmi_path]
            !entry.nil? && entry.any?
          end

          def reset!
            @registry = nil
            @slices = nil
          end

          def prepare(document, lines) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
            reset!
            # header attributes are parsed after preprocessors run, so
            # the opt-in is also detected in the raw lines
            return unless enabled?(document, lines)

            groups = collect_groups(document, lines)
            return if groups.empty?

            @registry = {}
            @slices = {}
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
              # one index pass and one write pass over the source; the
              # slices stay in memory for the parse cache to consume,
              # so nothing is written to disk
              ::Ea::Xmi::Slicer.slices(path, slice_groups).each do |group_key, xml|
                token = [path, group_key]
                @slices[token] = xml
                macro_keys[group_key]&.each do |k|
                  (@registry[path] ||= {})[k] = group_key
                end
              end
            end
            @registry = nil if @registry.empty?
          end

          private

          def enabled?(document, lines)
            document.attributes["lutaml-ea-xmi-load"] == "partial" ||
              lines.any? { |l| l.match?(/\A:lutaml-ea-xmi-load:\s*partial\s*$/) }
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
        end
      end

      # Scans the fully expanded document source once, before parsing,
      # and prepares the partial-load seeds for every table macro. The
      # lines pass through unchanged; reading them through the incoming
      # reader expands include directives, which is where plateau
      # documents keep their table macros.
      class XmiPartialLoadPreprocessor < ::Asciidoctor::Extensions::Preprocessor
        def process(document, reader)
          input_lines = reader.readlines
          XmiPartialLoadRegistry.prepare(document, input_lines)
          reader.class.new(document, input_lines)
        end
      end
    end
  end
end
