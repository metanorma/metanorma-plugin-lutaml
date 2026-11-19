# frozen_string_literal: true

# TEMPORARY CI diagnostic — remove after root-causing.
require "spec_helper"

RSpec.describe "CI diagnostic: xref decision state" do
  it "reports inventory and anchors for the entity_list fixture" do
    input = <<~TEXT
      = Document title
      Author
      :nodoc:
      :novalid:
      :no-isobib:
      :imagesdir: spec/assets

      [lutaml_ea_xmi,#{fixtures_path("large_test.xmi")},#{fixtures_path("lutaml_uml_datamodel_description_config.yml")}]
      --
      [.include_block, package="Another", base_path="spec/fixtures/lutaml/"]
      ...
      my text
      ...
      --
    TEXT
    require "metanorma/plugin/lutaml/xmi_model_reference"
    Metanorma::Plugin::Lutaml::XmiModelReference.prepend(Module.new do
      def process(parent, target, attrs)
        document = self.class.root_document(parent.document)
        inventory = document.attributes.fetch(
          Metanorma::Plugin::Lutaml::XmiModelReference::INVENTORY_ATTRIBUTE, {}
        )
        warn "CIDIAG target=#{target[0, 24]} in_inventory=#{inventory.key?(target)} " \
             "anchored=#{document.catalog[:refs].key?("section-#{target}")} " \
             "inventory_size=#{inventory.size} refs=#{document.catalog[:refs].size} " \
             "ruby=#{RUBY_VERSION}"
        super
      end
    end)
    xml = metanorma_convert(input)
    warn "CIDIAG has_xref_element=#{xml.include?("<xref")}"
    expect(xml).to be_present
  end
end
