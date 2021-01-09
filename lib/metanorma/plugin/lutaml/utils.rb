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
      end
    end
  end
end
