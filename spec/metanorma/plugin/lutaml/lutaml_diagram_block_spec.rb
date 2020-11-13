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
          ----
          diagram MyView {
            title "my diagram"

            class AddressClassProfile {
              addressClassProfile
            }
            class AttributeProfile {
              attributeProfile
            }

            association BidirectionalAsscoiation {
              owner_type aggregation
              member_type direct
              owner AddressClassProfile#addressClassProfile
              member AttributeProfile#attributeProfile [0..*]
            }

            association DirectAsscoiation {
              member_type direct
              owner AddressClassProfile
              member AttributeProfile#attributeProfile
            }

            association ReverseAsscoiation {
              owner_type aggregation
              owner AddressClassProfile#addressClassProfile
              member AttributeProfile
            }
          }
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <figure id="_">
          <image src="_" id="_" mimetype="image/png" height="auto" width="auto"></image>
          </figure>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(strip_src(xml_string_conent(metanorma_process(input))))
          .to(be_equivalent_to(output))
      end
    end
  end
end
