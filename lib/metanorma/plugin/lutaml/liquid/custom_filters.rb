# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module Liquid
        module CustomFilters
        end
      end
    end
  end
end

require_relative "custom_filters/html2adoc"
require_relative "custom_filters/values"
require_relative "custom_filters/replace_regex"
require_relative "custom_filters/loadfile"
require_relative "custom_filters/file_exist"
