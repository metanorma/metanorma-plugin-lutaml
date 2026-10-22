require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::Config::Guidance do
  describe "#from_yaml" do
    subject(:guidance) { described_class.from_yaml(yaml) }

    let(:yaml) do
      <<~TEXT
        ---
        classes:
          - name: Building
            attributes:
              - name: gml:boundedBy
                used: false
                guidance: |
                  Class guidance.
        data_types:
          - name: Height
            attributes:
              - name: Root:value
                used: false
                guidance: |
                  Datatype guidance.
      TEXT
    end

    it "contains classes" do
      expect(guidance.classes.map(&:name)).to(eq(["Building"]))
      expect(guidance.classes.first.attributes.map(&:name))
        .to(eq(["gml:boundedBy"]))
    end

    it "contains data_types" do
      expect(guidance.data_types.map(&:name)).to(eq(["Height"]))
      expect(guidance.data_types.first.attributes.map(&:name))
        .to(eq(["Root:value"]))
      expect(guidance.data_types.first.attributes.first.guidance)
        .to(eq("Datatype guidance.\n"))
    end

    it "serializes data_types to yaml hash for drops" do
      hash = guidance.to_yaml_hash
      expect(hash["data_types"].first["name"]).to(eq("Height"))
      expect(hash["data_types"].first["attributes"].first["used"])
        .to(be(false))
    end

    it "tolerates guidance without data_types" do
      class_only = described_class.from_yaml(<<~TEXT)
        ---
        classes:
          - name: Building
            attributes: []
      TEXT

      expect(class_only.data_types).to(eq([]))
      expect(class_only.to_yaml_hash["data_types"]).to(eq([]))
      expect(class_only.to_yaml_hash["classes"]).not_to(be_nil)
    end
  end
end
