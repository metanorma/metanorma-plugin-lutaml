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

    context "when the document carries a docfile (metanorma#627)" do
      let(:document) do
        doc = Asciidoctor::Document.new
        doc.attributes["docfile"] = "/repo/documents/iso/document.adoc"
        doc
      end

      let(:call) do
        described_class
          .render_liquid_string(template_string: template_string,
                                contexts: contexts,
                                document: document)
      end

      context "when the template reads docfile_directory" do
        let(:template_string) { "{{ docfile_directory }}" }
        let(:contexts) { {} }

        it "exposes the docfile's directory" do
          expect(call.first).to eq("/repo/documents/iso")
        end
      end

      context "when the template overrides docfile_directory" do
        let(:template_string) do
          "{% assign docfile_directory = 'mine' %}{{ docfile_directory }}"
        end
        let(:contexts) { {} }

        it "lets the template's own assignment win" do
          expect(call.first).to eq("mine")
        end
      end
    end
  end
end
