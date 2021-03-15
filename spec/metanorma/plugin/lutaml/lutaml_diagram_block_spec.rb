require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlDiagramBlock do
  describe "#process" do
    context "when simple relation diagram" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
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
          <name>my diagram</name>
          <image src="_" id="_" mimetype="image/png" height="auto" width="auto"></image>
          </figure>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      # TODO: fix dot install inside GHA
      xit "correctly renders input" do
        expect(strip_src(xml_string_conent(metanorma_process(input))))
          .to(be_equivalent_to(output))
      end
    end
  end
end
