# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "lutaml/formatter"
require "metanorma/plugin/lutaml/utils"

module Metanorma
  module Plugin
    module Lutaml
      module LutamlDiagramBase
        def process(parent, reader, attrs)
          uml_document = ::Lutaml::Uml::Parsers::Dsl
            .parse(lutaml_file(parent.document, reader))
          filename = generate_file(parent, reader, uml_document)
          through_attrs = generate_attrs(attrs)
          through_attrs["target"] = filename
          through_attrs["title"] = uml_document.caption
          create_image_block(parent, through_attrs)
        rescue StandardError => e
          abort(parent, reader, attrs, e.message)
        end

        def lutaml_file(_reader)
          raise "Implement me!"
        end

        protected

        def abort(parent, reader, attrs, msg)
          warn(msg)
          attrs["language"] = "lutaml"
          source = reader.respond_to?(:source) ? reader.source : reader
          create_listing_block(
            parent,
            source,
            attrs.reject { |k, _v| k == 1 },
          )
        end

        # if no :imagesdir: leave image file in lutaml
        def generate_file(parent, _reader, uml_document) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
          formatter = ::Lutaml::Formatter::Graphviz.new
          formatter.type = :png

          path_lutaml = "lutaml"
          imagesdir = if parent.document.attr("imagesdir")
                        File.join(parent.document.attr("imagesdir"),
                                  path_lutaml)
                      else
                        path_lutaml
                      end
          result_path = Utils.relative_file_path(parent.document, imagesdir)
          result_pathname = Pathname.new(result_path)
          result_pathname.mkpath
          File.writable?(result_pathname) ||
            raise("Destination path #{result_path} not writable for Lutaml!")

          outfile = Tempfile.new(["lutaml", ".png"])
          outfile.binmode
          outfile.puts(formatter.format(uml_document))
          outfile.close

          # Warning: metanorma/metanorma-standoc#187
          # Windows Ruby 2.4 will crash if a Tempfile is "mv"ed.
          # This is why we need to copy and then unlink.
          filename = File.basename(outfile.path)
          FileUtils.cp(outfile, result_pathname) && outfile.unlink

          # File.join(result_pathname, filename)
          File.join(path_lutaml, filename)
        end

        def generate_attrs(attrs)
          %w(id align float title role width height alt)
            .reduce({}) do |memo, key|
              memo[key] = attrs[key] if attrs.has_key? key
              memo
            end
        end
      end
    end
  end
end
