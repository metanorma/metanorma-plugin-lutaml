module Metanorma
  module Plugin
    module Lutaml
      class ExpressRemarksDecorator
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
          result
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
