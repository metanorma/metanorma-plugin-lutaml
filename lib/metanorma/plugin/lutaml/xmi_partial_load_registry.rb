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
      # standard build runner has. Partial loading is the default: every
      # klass and enum table macro's (package, name) pair seeds a
      # per-package reference closure; one streaming pass per source
      # assembles the closures in memory and each macro parses only its
      # own package's slice. Sources smaller than MIN_SOURCE_BYTES are
      # whole-loaded - slicing them costs more than parsing them.
      # Nothing is written to disk.
      #
      # A document opts out with the `lutaml-ea-xmi-load` document
      # attribute set to `whole`; without any attribute the partial
      # path engages, and with the opt-out the behavior is byte-for-byte
      # the whole-load path.
      #
      # When a macro's (path, name) resolves to no slice in an engaged
      # document and the source is large enough that whole-loading it is
      # the memory-death path, a warning through the Asciidoctor logger
      # names the document, the class and the source: a silent fallback
      # here hides an out-of-memory behind an apparently successful
      # build.
      module XmiPartialLoadRegistry
        MACRO_REGEXP = /lutaml_(?:klass|enum)_table::([^\[<]+)\[([^\]]*)\]/
        MIN_SOURCE_BYTES = 2 * 1024 * 1024
        WHOLE_LOAD_REGEXP = /\A:lutaml-ea-xmi-load:\s*whole\s*$/

        class << self
          # Rewrites (xmi_path, name_path) to the partial-load form of
          # the macro's class: [path, bare name, slice token]. The
          # token is nil when no slice was prepared, in which case the
          # macro whole-loads the source unchanged - warned about when
          # the document is engaged and the source is large.
          def rewrite(xmi_path, name_path)
            return [xmi_path, name_path, nil] unless @registry

            entry = @registry[xmi_path]
            return whole_load_fallback(xmi_path, name_path) unless entry

            group_key = entry[name_path] || entry[bare_name(name_path)]
            return whole_load_fallback(xmi_path, name_path) unless group_key

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
            @docfile = nil
            @whole_load_warned = []
          end

          def prepare(document, lines) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
            unless enabled?(document, lines)
              # an explicit opt-out is a main-document decision; drop
              # any slices a previous document left behind
              reset!
              return
            end

            groups = collect_groups(document, lines)
            if groups.empty?
              # standoc re-parses attribute snippets (asciidoc_sub titles
              # and friends) as one-line documents mid-conversion; the
              # global extension registry runs this preprocessor on those
              # fragments too. They carry no table macros and must not
              # wipe the slices prepared for the enclosing document, so
              # only a macro-less main document - one carrying the
              # docfile attribute - drops stale slices.
              reset! if document.attributes["docfile"]
              return
            end

            reset!
            @docfile = document.attributes["docfile"]
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
            return false if
              document.attributes["lutaml-ea-xmi-load"] == "whole"
            return false if lines.any? { |l| l.match?(WHOLE_LOAD_REGEXP) }

            true
          end

          # The whole-load fallback triple, preceded by the loud
          # warning on an engaged document with a large source:
          # silently whole-loading a plateau-scale export is the
          # build runner's out-of-memory.
          def whole_load_fallback(xmi_path, name_path)
            notify_whole_load_fallback(xmi_path, name_path)
            [xmi_path, name_path, nil]
          end

          def notify_whole_load_fallback(xmi_path, name_path)
            return unless whole_load_risk?(xmi_path)

            warned = [xmi_path, name_path]
            return if @whole_load_warned.include?(warned)

            @whole_load_warned << warned
            ::Asciidoctor::LoggerManager.logger.warn(
              "[metanorma-plugin-lutaml] lutaml-ea-xmi-load is partial " \
              "by default, but no slice was prepared for class " \
              "\"#{bare_name(name_path)}\" (#{name_path}) in " \
              "#{xmi_path}: #{document_label} whole-loads the " \
              "#{megabytes(xmi_path)} MB source, the memory-death path " \
              "on plateau-scale corpora. Check the macro's name and " \
              "package options, or set :lutaml-ea-xmi-load: whole to " \
              "acknowledge the whole load.",
            )
          end

          def whole_load_risk?(xmi_path)
            File.file?(xmi_path) && File.size(xmi_path) >= MIN_SOURCE_BYTES
          end

          def document_label
            @docfile ? "document #{@docfile}" : "the document"
          end

          def megabytes(xmi_path)
            (File.size(xmi_path).to_f / (1024 * 1024)).round(1)
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
