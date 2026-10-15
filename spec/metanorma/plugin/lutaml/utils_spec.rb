require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::Utils do
  describe ".load_express_from_folder" do
    it "retains source text when parsing EXPRESS files" do
      allow(Dir).to receive(:[]).and_return(["schema.exp"])

      expect(Expressir::Express::Parser)
        .to receive(:from_files)
        .with(["schema.exp"], include_source: true)

      described_class.load_express_from_folder("schemas")
    end
  end

  describe ".load_express_from_index" do
    it "retains source text when parsing indexed EXPRESS files" do
      allow(YAML).to receive(:safe_load_file)
        .with("index.yaml")
        .and_return("schemas" => { "schema" => { "path" => "schema.exp" } })

      expect(Expressir::Express::Parser)
        .to receive(:from_files)
        .with(["schema.exp"], include_source: true)

      described_class.load_express_from_index(nil, "index.yaml")
    end
  end

  describe ".render_liquid_string" do
    subject(:call) do
      described_class
        .render_liquid_string(template_string: template_string,
                              contexts: contexts,
                              document: Asciidoctor::Document.new)
    end

    context "when `interpolate` filter used" do
      let(:template_string) do
        "{{ context.name }}, {{ context.variable | interpolate }}"
      end
      let(:context_name) { "context" }
      let(:contexts) do
        {
          context_name => {
            "name" => "Test",
            "variable" => "Hi, my name is {{ context.name }}",
          },
        }
      end

      it "renders interpolated string" do
        expect(call).to eq(["Test, Hi, my name is Test", []])
      end
    end
  end
end
