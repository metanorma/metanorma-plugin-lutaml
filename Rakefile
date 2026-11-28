require "bundler/gem_tasks"
require "rspec/core/rake_task"

# The lutaml-uml-rendering specs (EA XMI, UML datamodel description)
# balloon memory on ruby 3.3 runners — they are killed mid-suite there
# (#304) while passing on 3.4/4.0 and in this dedicated task elsewhere.
XMI_HEAVY_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_ea_xmi_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_uml_datamodel_description_preprocessor_spec.rb
].freeze

XMI_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_ea_uml_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_klass_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_enum_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_index_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_uml_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/xmi_partial_load_registry_spec.rb
].freeze

# The diagram/GML/XSD/Liquid-rendering families each leave 25-70 MB of
# allocator high-water behind that no GC returns on darwin (measured
# 2026-11-26, #396: RSS is monotonic across file boundaries even with
# full flush + GC, and the bare process boot costs ~350 MB), so one
# process accumulates ~650 MB over the run. Grouping the heavy
# families into small dedicated tasks keeps every peak under the
# budget; the coverage is unchanged.
RENDER_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_ea_diagram_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_express_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_figure_inline_macro_spec.rb
].freeze

GML_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_gml_dictionary_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_gml_dictionary_block_spec.rb
].freeze

SCHEMA_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_jsonschema_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_table_inline_macro_spec.rb
].freeze

RENDER_TEXT_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_text_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xsd_preprocessor_spec.rb
].freeze

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:fast) do |t|
  t.pattern =
    FileList["spec/**/*_spec.rb"] - XMI_SPEC_FILES -
    XMI_HEAVY_SPEC_FILES - RENDER_SPEC_FILES - GML_SPEC_FILES -
    SCHEMA_SPEC_FILES - RENDER_TEXT_SPEC_FILES
end

RSpec::Core::RakeTask.new(:render) do |t|
  t.pattern = FileList[RENDER_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:gml) do |t|
  t.pattern = FileList[GML_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:schema) do |t|
  t.pattern = FileList[SCHEMA_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:render_text) do |t|
  t.pattern = FileList[RENDER_TEXT_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:xmi) do |t|
  t.pattern = FileList[XMI_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:xmi_heavy) do |t|
  t.pattern = FileList[XMI_HEAVY_SPEC_FILES]
end

# The XMI/uml-rendering specs accumulate more memory per process than
# the macos ruby-3.3 runner provides — they are killed mid-suite there
# (#304) no matter the grouping, while passing on 3.4/4.0 and via the
# dedicated tasks. The push gate therefore runs the two bounded
# non-XMI processes; run `rake xmi` and `rake xmi_heavy` (ad hoc /
# nightly) for the heavy sets.
task default: %i[fast render gml schema render_text]
