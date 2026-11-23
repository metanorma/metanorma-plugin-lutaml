require "spec_helper"
require "base64"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlDiagramBlock do
  describe "#process" do
    context "when simple relation diagram" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_diagram]
          ....
          diagram MyView {
            fontname "Arial"
            title "my diagram"
            caption "my diagram"
            class Foo {}
          }
          ....
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <figure id="_">
          <name id="_">my diagram</name>
          <image src="_" id="_" mimetype="image/png" height="auto" width="auto" filename="_"></image>
          </figure>
          </sections>
          </metanorma>
        TEXT
      end

      it "correctly renders input" do
        xml = metanorma_convert(input)
        image = Nokogiri::XML(xml).remove_namespaces!
          .at_xpath("//sections/figure/image")
        expect(image).not_to be_nil
        expect(image["src"]).to start_with("data:image/png;base64,")
        png = Base64.strict_decode64(image["src"].split(",", 2).last)
        expect(png.byteslice(0, 8)).to eq("\x89PNG\r\n\x1A\n".b)
        expect(strip_src(xml_string_content(xml)))
          .to(be_xml_equivalent_to(output))
      end
    end

    context "when inline macro, path supplied as the second arg" do
      let(:example_file) { fixtures_path("diagram_definitions.lutaml") }
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          lutaml_diagram::#{example_file}[]

        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <figure id="_">
          <image src="_" id="_" mimetype="image/png" height="auto" width="auto" filename="_"></image>
          </figure>
          </sections>
          </metanorma>
        TEXT
      end

      it "correctly renders input" do
        expect(strip_src(xml_string_content(metanorma_convert(input))))
          .to(be_xml_equivalent_to(output))
      end
    end
  end
end
