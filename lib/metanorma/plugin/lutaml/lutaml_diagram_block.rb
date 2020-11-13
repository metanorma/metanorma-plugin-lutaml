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
        enable_dsl
        on_context :listing

        def abort(parent, reader, attrs, msg)
          warn(msg)
          attrs["language"] = "lutaml"
          create_listing_block(
            parent,
            reader.source,
            attrs.reject { |k, v| k == 1 })
        end

        def process(parent, reader, attrs)
          filename = generate_file(parent, reader)
          through_attrs = generate_attrs(attrs)
          through_attrs["target"] = filename
          create_image_block(parent, through_attrs)
        rescue => e
          abort(parent, reader, attrs, e.message)
        end

        private

        # if no :imagesdir: leave image file in lutaml
        def generate_file(parent, reader)
          lutaml_temp = Tempfile.new(['lutaml', '.lutaml'])
          lutaml_temp.puts(reader.read)
          lutaml_temp.rewind

          uml_document = ::Lutaml::Uml::Parsers::Dsl.parse(lutaml_temp)
          formatter = ::Lutaml::Uml::Formatter::Graphviz.new
          formatter.type = :png

          imagesdir = parent.document.attr('imagesdir').to_s
          result_path = Utils
                          .relative_file_path(
                            parent.document,
                            File.join(imagesdir, 'lutaml'))
          result_pathname = Pathname.new(result_path)
          result_pathname.mkpath
          File.writable?(result_pathname) or raise "Destination path #{result_path} not writable for Lutaml!"

          outfile = Tempfile.new(['lutaml', '.png'])
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
          through_attrs = %w(id align float title role width height alt).
            inject({}) do |memo, key|
            memo[key] = attrs[key] if attrs.has_key? key
            memo
          end
        end
      end
    end
  end
end
