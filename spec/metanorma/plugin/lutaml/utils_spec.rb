require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::Utils do
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
