# frozen_string_literal: true

require_relative "./lutaml_uml_class_preprocessor.rb"

module Metanorma
  module Plugin
    module Lutaml
      #  Macro for quick rendering of datamodel attributes/values table
      #  @example [lutaml_uml_attributes_table,path/to/lutaml,EntityName]
      class LutamlUmlAttributesTablePreprocessor < LutamlUmlClassPreprocessor
        MACRO_REGEXP =
          /\[lutaml_uml_attributes_table,([^,]+),?([^,]+),?(.+?)?\]/

        # rubocop:disable Layout/IndentHeredoc
        def template(options)
          skip_headers = options[:skip_headers]

          <<~TEMPLATE
          #{"=== {{ definition.name }}" unless skip_headers}
          {{ definition.definition }}

          {% if definition.attributes %}
          {% if definition.keyword == 'enumeration' %}
          .{{ definition.name }} values
          |===
          |Name |Definition

          {% for item in definition.attributes %}
          |{{ item.name }} |{{ item.definition }}
          {% endfor %}
          |===
          {% else %}
          .{{ definition.name }} attributes
          |===
          |Name |Definition |Mandatory / Optional / Conditional |Max Occur |Data Type

          {% for item in definition.attributes %}
          |{{ item.name }} |{% if item.definition %}{{ item.definition }}{% endif %} |{% if item.cardinality.min == "0" %}O{% else %}M{% endif %} |{% if item.cardinality.max == "*" %}N{% else %}1{% endif %} |{% if item.origin %}<<{{ item.origin }}>>{% endif %} `{{ item.type }}`
          {% endfor %}
          |===
          {% endif %}
          {% endif %}

          TEMPLATE
        end
        # rubocop:enable Layout/IndentHeredoc
      end

    end
  end
end
