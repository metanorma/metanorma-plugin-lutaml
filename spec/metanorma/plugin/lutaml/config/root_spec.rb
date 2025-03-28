require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::Config::Root do
  let(:yaml) do
    <<~TEXT
      ---
      packages:
        - Another
        - City*
        - "Wrapper nested package":
            skip_tables:
              - classes
        - "Another Wrapper nested package":
            render_entities:
              - "NE_RE_Null_Register"
              - "RE_Register_enum"
        - skip: Dynamizer
      render_style: data_dictionary
      ea_extension:
        - "ISO19103MDG v1.0.0-beta.xml"
        - "CityGML_MDG_Technology.xml"
      template_path: spec/fixtures/lutaml/liquid_templates
      section_depth: 2
      guidance: spec/fixtures/lutaml/guidance/guidance_absolute.yaml
    TEXT
  end

  let(:root) { described_class }

  describe "#from_yaml" do
    subject(:subject) { root.from_yaml(yaml) }

    it "correctly renders input" do
      expect(YAML.safe_load(subject.to_yaml))
        .to(be_equivalent_to(YAML.safe_load(yaml)))
    end

    it "contains packages" do
      expect(subject.packages.map(&:name)).to(
        eq(
          [
            "Another", "City*", "Wrapper nested package",
            "Another Wrapper nested package"
          ],
        ),
      )
    end

    it "contains skip package" do
      expect(subject.skip).to(eq(["Dynamizer"]))
    end

    it "contains render_style" do
      expect(subject.render_style).to(eq("data_dictionary"))
    end

    it "contains ea_extension" do
      expect(subject.ea_extension).to(
        eq(
          [
            "ISO19103MDG v1.0.0-beta.xml",
            "CityGML_MDG_Technology.xml",
          ],
        ),
      )
    end

    it "contains template_path" do
      expect(subject.template_path).to(
        eq("spec/fixtures/lutaml/liquid_templates"),
      )
    end

    it "contains section_depth" do
      expect(subject.section_depth).to(eq(2))
    end

    it "contains guidance" do
      expect(subject.guidance).to(
        eq("spec/fixtures/lutaml/guidance/guidance_absolute.yaml"),
      )
    end

    it "contains packages with skip_tables" do
      subject.packages.each do |package|
        if package.name == "Wrapper nested package"
          expect(package.skip_tables).to(eq(["classes"]))
        else
          expect(package.skip_tables).to(be_nil)
        end
      end
    end

    it "contains packages with render_entities" do
      subject.packages.each do |package|
        if package.name == "Another Wrapper nested package"
          expect(package.render_entities).to(
            eq(["NE_RE_Null_Register", "RE_Register_enum"]),
          )
        else
          expect(package.render_entities).to(be_nil)
        end
      end
    end
  end
end
