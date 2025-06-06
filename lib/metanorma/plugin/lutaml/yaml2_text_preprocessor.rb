# frozen_string_literal: true

require_relative "content"
require_relative "base_structured_text_preprocessor"

module Metanorma
  module Plugin
    module Lutaml
      class Yaml2TextPreprocessor < BaseStructuredTextPreprocessor
        include Content
        # search document for block `yaml2text`
        #   after that take template from block and read file into this template
        #   example:
        #     [yaml2text,foobar.yaml]
        #     ----
        #     === {item.name}
        #     {item.desc}
        #
        #     {item.symbol}:: {item.symbol_def}
        #     ----
        #
        #   with content of `foobar.yaml` file equal to:
        #     - name: spaghetti
        #       desc: wheat noodles of 9mm diameter
        #       symbol: SPAG
        #       symbol_def: the situation is message like spaghetti at a kid's
        #
        #   will produce:
        #     === spaghetti
        #     wheat noodles of 9mm diameter
        #
        #     SPAG:: the situation is message like spaghetti at a kid's meal

        def initialize(config = {})
          super
          @config[:block_name] = "yaml2text"
        end
      end
    end
  end
end
