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
  spec/metanorma/plugin/lutaml/lutaml_klass_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_enum_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_index_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_uml_preprocessor_spec.rb
].freeze

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:fast) do |t|
  t.pattern =
    FileList["spec/**/*_spec.rb"] - XMI_SPEC_FILES - XMI_HEAVY_SPEC_FILES
end

RSpec::Core::RakeTask.new(:xmi) do |t|
  t.pattern = FileList[XMI_SPEC_FILES]
end

RSpec::Core::RakeTask.new(:xmi_heavy) do |t|
  t.pattern = FileList[XMI_HEAVY_SPEC_FILES]
end

# The full suite in one process accumulates enough parse memory to be
# killed on some runners (metanorma-plugin-lutaml#304); run the two
# halves as separate rspec processes so memory is reclaimed between.
task default: %i[fast xmi]
