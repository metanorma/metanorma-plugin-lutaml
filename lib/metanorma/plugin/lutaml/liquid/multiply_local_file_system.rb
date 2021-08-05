module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        class LocalFileSystem
          attr_accessor :roots, :patterns

          def initialize(roots, patterns = ["_%s.liquid"])
            @roots    = roots
            @patterns = patterns
          end

          def read_template_file(template_path)
            full_path = full_path(template_path)
            raise FileSystemError, "No such template '#{template_path}'" unless File.exist?(full_path)

            File.read(full_path)
          end

          def full_path(template_path)
            raise ::Liquid::FileSystemError, "Illegal template name '#{template_path}'" unless %r{\A[^./][a-zA-Z0-9_/]+\z}.match?(template_path)

            result_path = if template_path.include?('/')
              roots
                .map do |root|
                  patterns.map do |pattern|
                    File.join(root, File.dirname(template_path), pattern % File.basename(template_path))
                  end
                end
                .flatten
                .find { |path| File.file?(path) }
            else
              roots
                .map do |root|
                  patterns.map do |pattern|
                    File.join(root, pattern % template_path)
                  end
                end
                .flatten
                .find { |path| File.file?(path) }
            end

            unless roots.any? { |root| File.expand_path(result_path).start_with?(File.expand_path(root)) }
              raise ::Liquid::FileSystemError, "Illegal template path '#{File.expand_path(result_path)}'"
            end

            result_path
          end
        end
      end
    end
  end
end
