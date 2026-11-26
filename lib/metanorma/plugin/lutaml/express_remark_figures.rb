# frozen_string_literal: true

require "digest"
require "fileutils"
require "pathname"

module Metanorma
  module Plugin
    module Lutaml
      # The drop-facing rewrite of a schema's remark figure macros.
      #
      # The __expressg remarks carry bare image macros
      # (`image::<name>.svg[]`) whose files sit next to the schema's .exp
      # file. The source listing resolves them through the listing-scoped
      # :imagesdir: entries (ExpressSchemaListing), but templates that
      # render the remark text OUTSIDE the listing -- the SRL member
      # documents' annex-diagram templates print the remark verbatim --
      # resolve the bare name against the document's :imagesdir:, which
      # names the document's own images/ folder. The figure is not there,
      # and the missing-image check stops the build (issue #359).
      #
      # The fix composes each bare figure target as the path from the
      # document's imagesdir DIRECTORY to the resolved figure file, the
      # only relative form that survives asciidoctor's resolution: an
      # image target is joined with the document's imagesdir before use
      # (one "../" per imagesdir segment is consumed by the join), so a
      # target expressed relative to that directory lands on the file
      # whether the document sets :imagesdir:, and with no :imagesdir:
      # the imagesdir directory is the docfile directory and the target
      # is the plain docfile-relative path -- the form the working
      # collection builds carry in their document.xml. Every emitted
      # target is document-relative: no build path enters the output.
      #
      # The imagesdir in force at parse time is known only from the
      # source: attribute entries apply at parse, after preprocessing,
      # so the preprocessors stash the value they scan from the source
      # lines (scan_source_imagesdir) and the resolver falls back to the
      # document's programmatic attributes where no entry exists.
      #
      # The rewrite rides the RemarkItem liquid drop, never the model:
      # the source listing prints the model's formatted source and must
      # keep showing the macros as written, while every drop-facing
      # rendering gets the resolved targets. Figures that do not resolve
      # under the schema keep their macros, so genuinely missing assets
      # still surface loudly.
      module ExpressRemarkFigures
        # A bare relative image macro: `image::name.svg[]`. Absolute
        # paths, URLs, data URIs, liquid references and macros carrying
        # an attribute list stay as written.
        # An optional attribute list is allowed: the WG12 remark figures
        # carry captions (`image::images/x.svg[EXPRESS-G diagram]`), and
        # the empty-list-only form skipped them silently (#371).
        IMAGE_MACRO_REGEXP = /\Aimage::([^:\s{}]+)\[[^\]]*\]\s*\z/

        # An imagesdir attribute entry; the bang form unsets. The LAST
        # entry in the source is the one in force where the member
        # document's annexes render.
        # Linear form: one dispatch space then the rest of the line;
        # surrounding whitespace is stripped by the caller. An
        # end-anchored [ \t]* after .* backtracks quadratically
        # (CodeQL rb/polynomial-redos).
        IMAGESDIR_ENTRY_REGEXP = /\A:(!)?imagesdir:(?:[ \t](.*))?\z/

        SOURCE_IMAGESDIR_ATTRIBUTE = "lutaml-source-imagesdir"

        class << self
          # Stashes the imagesdir value the source lines set, the only
          # form the parse-time resolution can see (attribute entries
          # apply at parse, after preprocessing). Called from the
          # preprocessors' process with the document's full source.
          def scan_source_imagesdir(document, lines)
            found = false
            value = nil
            lines.reverse_each do |line|
              entry = IMAGESDIR_ENTRY_REGEXP.match(line) or next
              value = entry[1] ? "" : (entry[2] || "").strip
              found = true
              break
            end
            return unless found

            document.attributes[SOURCE_IMAGESDIR_ATTRIBUTE] = value
          end

          # The imagesdir the figure targets are composed against: the
          # source-set value when the source carries an entry, else the
          # document's programmatic attributes. An empty string is the
          # explicit unset form.
          def effective_imagesdir(document)
            scanned = document.attributes[SOURCE_IMAGESDIR_ATTRIBUTE]
            scanned.nil? ? document.attributes["imagesdir"] : scanned
          end

          # Patches the RemarkItem drop class the way
          # ExpressSchemaListing.apply patches the Schema drop class:
          # applied before the first template render of a repository
          # (lutaml_preprocessor's update_repo), whose Liquid memoizes a
          # drop class's invokable methods on first render.
          def apply
            klass = remark_item_class
            return unless klass

            klass.ensure_liquid_registered!
            drop_class = klass.base_drop_class
            return unless drop_class
            return if drop_class.include?(DropMethods)

            drop_class.include(DropMethods)
          end

          private

          def remark_item_class
            return unless defined?(::Expressir::Model::Declarations::RemarkItem)

            ::Expressir::Model::Declarations::RemarkItem
          end
        end

        module DropMethods
          def remarks
            if @object.respond_to?(:expressg_figure_remarks)
              @object.expressg_figure_remarks
            else
              @object.remarks
            end
          end

          # The bare rendering surface. Liquid stringifies a rendered drop
          # through to_s, and Liquid::Drop#to_s is the drop's CLASS NAME,
          # so every remark_items loop that prints the item verbatim
          # ("{{ remark }}") printed the object dump instead of the remark
          # text (issue #369). The text is the figure-resolved remarks --
          # the same values the drop-facing `remarks` accessor returns,
          # joined the way expressir's remark formatter joins them --
          # while the model-level methods keep the source listing
          # printing the macros as written.
          def to_s
            remarks.join("\n")
              .gsub(/^[ \t]+(?=image::)/, "")
              .gsub(/^(?!$)(image::)/) { "\n\n#{Regexp.last_match(1)}" }
          end
        end

        # Composes the drop-facing remark text for one decorated schema.
        # +docfile+ and +imagesdir+ are the document's attributes;
        # +schema_directory+ is the schema's imagesdir (its source
        # directory as the document resolves it,
        # ExpressRemarkAdapter.schema_imagesdir).
        class TargetResolver
          def initialize(docfile, imagesdir, schema_directory)
            docdir = File.dirname(File.expand_path(docfile.to_s))
            @docdir = docdir
            # Asciidoctor's default imagesdir is empty: a document that
            # sets none resolves every bare image target against the
            # docfile directory itself, and an explicit `:!imagesdir:`
            # unset behaves identically. `File.expand_path` with an empty
            # base returns the docdir, so both cases stage at the exact
            # spot the bare target resolves to.
            @imagesdir_directory = File.expand_path(imagesdir.to_s, docdir)
            @schema_directory = schema_directory
            @errors = []
          end

          def remarks(texts)
            texts.map { |text| remark(text) }
          end

          # The resolved text plus any figure-error lines emitted along
          # the way (a missing figure surfaces as a visible error, never
          # as a broken macro).
          def remark(text)
            text.each_line.map { |line| rewrite_line(line) }.join
          end

          def errors
            @errors.dup
          end

          private

          # The figure file is STAGED into the resolved imagesdir
          # directory at the exact path the imagesdir join computes for
          # its target — asciidoctor joins every image target with the
          # imagesdir (the author's value, or its own "images" default)
          # before use, so staging MIRRORS the target path under that
          # directory and the emitted line stands exactly as written:
          # the target is a static path whose composed location exists.
          # No target rewriting, no imagesdir attribute entry
          # (metanorma-plugin-lutaml#371). Only when that static spot is
          # taken by a DIFFERENT figure (two schemas shipping a same-named
          # file) does the line rewrite — to the unique staged path,
          # still static.
          def rewrite_line(line)
            match = IMAGE_MACRO_REGEXP.match(line) or return line
            before = @errors.length
            final = final_target(match[1])
            if final.nil? && @errors.length > before
              return @errors[before..].join("\n")
            end

            return line if final == match[1]

            trailing = line.length - line.rstrip.length
            suffix = trailing.positive? ? line[-trailing, trailing] : ""
            "#{line[/\Aimage::/]}#{final}[]#{suffix}"
          end

          def final_target(target)
            return target if target.start_with?("/")
            return flat_target(target) if target.include?("/")

            file = File.expand_path(target, @schema_directory.to_s)
            unless File.file?(file)
              # An already-resolved line fed back on a second pass
              # (metanorma-plugin-lutaml#388) stands staged: pass it
              # through unchanged instead of erroring.
              return target if File.file?(File.join(@imagesdir_directory,
                                                    target))

              # A missing figure must NOT reach asciidoctor as a broken
              # image macro — metanorma's image-existence check then
              # FATALs the whole build (#371). Emit a visible, localized
              # error line in its place: what was expected, where it was
              # looked for.
              @errors << "[EXPRESS-G figure error] '#{target}' not found beside " \
                         "the schema (looked in '#{@schema_directory}')"
              return
            end

            staged = File.join(@imagesdir_directory, target)
            if File.file?(staged)
              return target if FileUtils.identical?(file, staged)

              unique = File.join(@imagesdir_directory,
                                 Digest::SHA256.file(file).hexdigest[0, 12],
                                 target)
              return target if File.file?(unique)

              FileUtils.mkdir_p(File.dirname(unique))
              FileUtils.cp(file, unique)
              return unique.sub("#{@imagesdir_directory}/", "")
            end

            FileUtils.mkdir_p(File.dirname(staged))
            FileUtils.cp(file, staged)
            target
          end

          # A target carrying a path segment (as written in the schema
          # source, e.g. `images/image-02.png`) is emitted FLAT: the
          # staged spot must equal the imagesdir-join of the emitted
          # target, and a subpath target would double under the join
          # (`images/images/...`, #381). A basename collision with a
          # different file disambiguates through a digest directory,
          # whose emitted path is itself staged at its own join.
          def flat_target(target)
            file = File.expand_path(target, @schema_directory.to_s)
            unless File.file?(file)
              # A second pass may feed this resolver its own output -
              # the flat name, or the digest-qualified form (#388).
              # Both stand staged after the first pass; pass them
              # through unchanged.
              flat = File.basename(target)
              return flat if target == flat &&
                File.file?(File.join(@imagesdir_directory, flat))
              return target if File.file?(File.join(@imagesdir_directory,
                                                    target))

              @errors << "[EXPRESS-G figure error] '#{target}' not found beside " \
                         "the schema (looked in '#{@schema_directory}')"
              return
            end

            flat = File.basename(target)
            staged = File.join(@imagesdir_directory, flat)
            if File.file?(staged)
              return flat if FileUtils.identical?(file, staged)

              digest = Digest::SHA256.file(file).hexdigest[0, 12]
              unique = File.join(digest, flat)
              staged_unique = File.join(@imagesdir_directory, unique)
              return unique if File.file?(staged_unique)

              FileUtils.mkdir_p(File.dirname(staged_unique))
              FileUtils.cp(file, staged_unique)
              return unique
            end

            FileUtils.mkdir_p(@imagesdir_directory)
            FileUtils.cp(file, staged)
            flat
          end
        end
      end
    end
  end
end
