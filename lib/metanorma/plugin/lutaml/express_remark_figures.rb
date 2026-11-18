# frozen_string_literal: true

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
        IMAGE_MACRO_REGEXP = /\Aimage::([^\/\s:{}][^:\s{}]*)\[\]\s*\z/

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
        end

        # Composes the drop-facing remark text for one decorated schema.
        # +docfile+ and +imagesdir+ are the document's attributes;
        # +schema_directory+ is the schema's imagesdir (its source
        # directory as the document resolves it,
        # ExpressRemarkAdapter.schema_imagesdir).
        class TargetResolver
          # Asciidoctor's default imagesdir for a document that sets
          # none: bare image targets resolve against "images" under the
          # docfile directory.
          DEFAULT_IMAGESDIR = "images".freeze

          def initialize(docfile, imagesdir, schema_directory)
            docdir = File.dirname(File.expand_path(docfile.to_s))
            @docdir = docdir
            @imagesdir_directory =
              if imagesdir.nil? || imagesdir.empty?
                File.join(docdir, DEFAULT_IMAGESDIR)
              else
                File.expand_path(imagesdir, docdir)
              end
            @schema_directory = schema_directory
          end

          def remarks(texts)
            texts.map { |text| remark(text) }
          end

          def remark(text)
            text.each_line.map { |line| rewrite_line(line) }.join
          end

          private

          # The figure file is STAGED into the resolved imagesdir
          # directory — the one directory this document's image targets
          # resolve against, since asciidoctor joins every target with
          # the imagesdir (the author's value, or its own "images"
          # default) before use — and the emitted target is the staged
          # file's bare basename. A ../-composed target escapes the
          # imagesdir join and is dropped silently by asciidoctor's path
          # handling (measured: the figure vanished from every output
          # format, exit 0), and an absolute target leaks the build path
          # (issue #359's original report). The staged copy is a build
          # artifact; no path enters the output.
          def rewrite_line(line)
            match = IMAGE_MACRO_REGEXP.match(line) or return line
            return line unless stage_figure(match[1])

            trailing = line.length - line.rstrip.length
            suffix = trailing.positive? ? line[-trailing, trailing] : ""
            "#{line[/\Aimage::/]}#{File.basename(match[1])}[]#{suffix}"
          end

          def stage_figure(bare)
            file = File.expand_path(bare, @schema_directory.to_s)
            return unless File.file?(file)

            staged = File.join(@imagesdir_directory, File.basename(bare))
            return true if File.file?(staged)

            FileUtils.mkdir_p(@imagesdir_directory)
            FileUtils.cp(file, staged)
            true
          end
        end
      end
    end
  end
end
