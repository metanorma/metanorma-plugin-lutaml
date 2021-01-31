module Metanorma
  module Plugin
    module Lutaml
      # Helpers for lutaml macroses
      module Utils
        module_function

        def relative_file_path(document, file_path)
          docfile_directory = File.dirname(
            document.attributes["docfile"] || "."
          )
          document
            .path_resolver
            .system_path(file_path, docfile_directory)
        end

        def render_liquid_string(template_string:, context_items:,
                                 context_name:)
          liquid_template = Liquid::Template.parse(template_string)
          rendered_string = liquid_template
            .render(context_name => context_items,
                    strict_variables: true,
                    error_mode: :warn)
          [rendered_string, liquid_template.errors]
        end

        def notify_render_errors(document, errors)
          errors.each do |error_obj|
            document
              .logger
              .warn("Liquid render error: #{error_obj.message}")
          end
        end

        def process_express_index(folder, name, idxs, document)
          idxs[name] = []
          Dir["#{Utils.relative_file_path(document, folder)}/*"].each do |path|
            next if [".", ".."].include?(path)

            begin
              idxs[name]
                .push(::Lutaml::Parser.parse(File.new(path, encoding: "UTF-8")))
            rescue StandardError => e
              document.logger.warn("Failed to load #{path}: #{e.message}")
            end
          end
        end

        def parse_document_express_indexes(document, input_lines)
          express_indexes = {}
          loop do
            line = input_lines.next
            break if line.length.zero?

            _, name, folder = line.match(/^:lutaml-express-index:(.+?);(.+?)$/)&.to_a
            if folder && name
              process_express_index(
                folder.strip.gsub(";", ""),
                name.strip,
                express_indexes,
                document
              )
            end
          end
          express_indexes
        rescue StopIteration
          express_indexes
        ensure
          input_lines.rewind
        end
      end
    end
  end
end
