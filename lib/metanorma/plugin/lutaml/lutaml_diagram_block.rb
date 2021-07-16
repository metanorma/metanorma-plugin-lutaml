# frozen_string_literal: true

require "liquid"
require "asciidoctor"
require "asciidoctor/reader"
require "lutaml"
require "lutaml/uml"
require "metanorma/plugin/lutaml/utils"

module Metanorma
  module Plugin
    module Lutaml
      class LutamlDiagramBlock < Asciidoctor::Extensions::BlockProcessor
        use_dsl
        named :lutaml_diagram
        on_context :literal
        parse_content_as :raw

        def abort(parent, reader, attrs, msg)
          warn(msg)
          attrs["language"] = "lutaml"
          create_listing_block(
            parent,
            reader.source,
            attrs.reject { |k, _v| k == 1 }
          )
        end

        def process(parent, reader, attrs)
          uml_document = ::Lutaml::Uml::Parsers::Dsl.parse(lutaml_temp(parent.document, reader))
          filename = generate_file(parent, reader, uml_document)
          through_attrs = generate_attrs(attrs)
          through_attrs["target"] = filename
          through_attrs["title"] = uml_document.caption
          create_image_block(parent, through_attrs)
        rescue StandardError => e
          abort(parent, reader, attrs, e.message)
        end

        private

        def lutaml_temp(document, reader)
          temp_file = Tempfile.new(["lutaml", ".lutaml"], Utils.relative_file_path(document, ''))
          temp_file.puts(reader.read)
          temp_file.rewind
          temp_file
        end

        # if no :imagesdir: leave image file in lutaml
        def generate_file(parent, _reader, uml_document)
          formatter = ::Lutaml::Uml::Formatter::Graphviz.new
          formatter.type = :png

          imagesdir = if parent.document.attr("imagesdir")
                        File.join(parent.document.attr("imagesdir"), "lutaml")
                      else
                        "lutaml"
                      end
          result_path = Utils.relative_file_path(parent.document, imagesdir)
          result_pathname = Pathname.new(result_path)
          result_pathname.mkpath
          File.writable?(result_pathname) || raise("Destination path #{result_path} not writable for Lutaml!")

          outfile = Tempfile.new(["lutaml", ".png"])
          outfile.binmode
          outfile.puts(formatter.format(uml_document))

          # Warning: metanorma/metanorma-standoc#187
          # Windows Ruby 2.4 will crash if a Tempfile is "mv"ed.
          # This is why we need to copy and then unlink.
          filename = File.basename(outfile.path)
          FileUtils.cp(outfile, result_pathname) && outfile.unlink

          File.join(result_pathname, filename)
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
