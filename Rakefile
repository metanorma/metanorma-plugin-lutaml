require "bundler/gem_tasks"
require "rspec/core/rake_task"

XMI_SPEC_FILES = %w[
  spec/metanorma/plugin/lutaml/lutaml_ea_xmi_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_uml_datamodel_description_preprocessor_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_klass_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_enum_table_block_macro_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_index_spec.rb
  spec/metanorma/plugin/lutaml/lutaml_xmi_uml_preprocessor_spec.rb
].freeze

RSpec::Core::RakeTask.new(:spec)

RSpec::Core::RakeTask.new(:fast) do |t|
  t.pattern = FileList["spec/**/*_spec.rb"] - XMI_SPEC_FILES
end

RSpec::Core::RakeTask.new(:xmi) do |t|
  t.pattern = FileList[XMI_SPEC_FILES]
end

task default: :spec
