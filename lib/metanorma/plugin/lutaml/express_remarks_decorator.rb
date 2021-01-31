module Metanorma
  module Plugin
    module Lutaml
      class ExpressRemarksDecorator
        RELATIVE_PREFIX_MACRO_REGEXP = /(link|image|video|audio|include)(:+)(?![^\/:]+:\/\/|[A-Z]:\/|\/)([^:\[]+)(\[.*\])/.freeze

        attr_reader :remark, :options

        def self.call(remark, options)
          new(remark, options).call
        end

        def initialize(remark, options)
          @remark = remark
          @options = options
        end

        def call
          result = remark
          if options["leveloffset"]
            result = process_remark_offsets(result, options["leveloffset"].to_i)
          end
          if options["relative_path_prefix"]
            result = update_relative_paths(result,
                                           options["relative_path_prefix"])
          end
          result
        end

        private

        def update_relative_paths(string, path_prefix)
          string
            .split("\n")
            .map do |line|
              if line.match?(RELATIVE_PREFIX_MACRO_REGEXP)
                prefix_relative_paths(line, path_prefix)
              else
                line
              end
            end
            .join("\n")
        end

        def prefix_relative_paths(line, path_prefix)
          line.gsub(RELATIVE_PREFIX_MACRO_REGEXP) do |_match|
            prefixed_path = File.join(path_prefix, $3)
            "#{$1}#{$2}#{prefixed_path}#{$4}"
          end
        end

        def process_remark_offsets(string, offset)
          string
            .split("\n")
            .map do |line|
              if line.match?(/^=/)
                set_string_offsets(line, offset)
              else
                line
              end
            end
            .join("\n")
        end

        def set_string_offsets(string, offset)
          return "#{'=' * offset}#{string}" if offset.positive?

          string.gsub(/^={#{offset * -1}}/, "")
        end
      end
    end
  end
end
