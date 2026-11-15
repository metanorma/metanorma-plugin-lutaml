# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      class ExpressRemarksDecorator
        RELATIVE_PREFIX_MACRO_REGEXP = %r{
          ^                                # Start of line
          (link|image|video|audio|include) # Capture group 1: content type
          (:+)?                            # Capture group 2: optional colons
          (?!                              # Negative lookahead
            [^/:]+://|                     # Don't match URLs (http://, etc.)
            [A-Z]:/|                       # Don't match Windows paths
            /                              # Don't match absolute paths
          )                                # End negative lookahead
          ([^:\[]+)                        # Capture group 3: the path/name
          (\[.*\])?                        # Capture group 4: optional attribute
          $                                # End of line
        }x

        MACRO_LINE_REGEXP = /^(link|image|video|audio|include)::/

        # Asciidoctor's list-item continuation: attaches the next block
        # only when the preceding line is a list item.
        LONE_CONTINUATION_REGEXP = /^\+[[:space:]]*$/

        # A `+` glued to a macro line's trailing `[]` (no whitespace): the
        # form asciidoctor renders as literal text in every context.
        GLUED_CONTINUATION_REGEXP = %r{
          ^(?:link|image|video|audio|include):: .+ \[\][+][[:space:]]*$
        }x
        LIST_ITEM_REGEXP = %r{
          ^(?:[-*]|\d+[.)]|[A-Za-z][.)])\s   # bullets and enumerations
          | \w[[:alnum:] _-]*::\s            # definition lists
        }x

        attr_reader :remark, :options

        def self.call(remark, options)
          new(remark, options).call
        end

        def self.decorate_array(remarks, options)
          return [] unless remarks

          remarks.map { |remark| call(remark, options) }
        end

        def initialize(remark, options)
          @remark = remark
          @options = options
        end

        def call
          result = normalise_dangling_continuations(remark)
          result = normalise_glued_continuations(result)
          if options["relative_path_prefix"]
            result = update_relative_paths(result,
                                           options["relative_path_prefix"])
          end
          result
        end

        private

        # A `+` GLUED to a macro's closing bracket (`image::x.gif[]+`) is
        # parsed by asciidoctor as literal text in EVERY context — list
        # item or paragraph (TRThurman's trial, iso-10303#862: the
        # kinematic_structure_schema `direction_vectors` continuation) —
        # so it never performs the attachment the author wrote it for.
        # Strip it: the macro renders as its block, and any intended
        # continuation of the following text stays with the following
        # text.
        def normalise_glued_continuations(string)
          strip = lambda do |line|
            line.match?(GLUED_CONTINUATION_REGEXP) ? line[..-2] : line
          end
          string.split("\n").map(&strip).join("\n")
        end

        # A lone `+` is asciidoctor's list-item continuation: it attaches
        # the next block only when the preceding line is a list item.
        # Authored after plain paragraphs (the corpus's `term - definition`
        # style), it folds the following macro line into a literal text
        # paragraph — printing the macro source with the decorator's
        # expanded path inside it, which leaks the build directory into
        # published text (iso-10303#862: kinematic_structure_schema's
        # figure continuations). After a paragraph there is nothing to
        # attach to, so the `+` becomes a blank line: the macro renders
        # as the standalone block the author intended, directly after the
        # text. Continuations after genuine list items keep their `+`.
        def normalise_dangling_continuations(string)
          lines = string.split("\n")
          lines.each_with_index
            .map do |line, idx|
            dangling_continuation?(lines, idx) ? "" : line
          end
            .join("\n")
        end

        def dangling_continuation?(lines, idx)
          return false unless lines[idx].match?(LONE_CONTINUATION_REGEXP)
          return false unless lines[idx + 1].to_s.match?(MACRO_LINE_REGEXP)

          prev = idx.positive? && lines[idx - 1]
          return false if prev&.match?(LIST_ITEM_REGEXP)

          true
        end

        def update_relative_paths(string, path_prefix)
          expand_line = lambda do |line|
            if line.match?(RELATIVE_PREFIX_MACRO_REGEXP)
              prefix_relative_paths(line, path_prefix)
            else
              line
            end
          end
          string.split("\n").map(&expand_line).join("\n")
        end

        def prefix_relative_paths(line, path_prefix)
          # Decorated remarks live on models shared across documents and
          # preprocess passes: a second pass over an already-decorated line
          # would stack the prefix again (paths like
          # ../schemas/schemas/schemas/... rendered unusable). Idempotent:
          # a line that carries this prefix is left alone.
          return line if path_prefix && line.include?(path_prefix)

          line.gsub(RELATIVE_PREFIX_MACRO_REGEXP) do |_match|
            # Expand against the docfile directory (passed by the adapter
            # as relative_path_base), NOT the process CWD: a CWD expansion
            # produced absolute image paths under whatever directory the
            # build was launched from (e.g. <repo>/../../schemas/...).
            # The absolute result is deliberate: relative targets are
            # re-anchored by asciidoctor's imagesdir handling
            # (images/../../schemas collapses a level), which made every
            # decorated diagram unresolvable at render time.
            full_path = File.expand_path(
              File.join(path_prefix, $3.strip),
              options["relative_path_base"] || Dir.pwd,
            )
            "#{$1}#{$2}#{full_path}#{$4}"
          end
        end
      end
    end
  end
end
