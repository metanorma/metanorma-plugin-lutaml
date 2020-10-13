require "spec_helper"
require "metanorma/plugin/lutaml/lutaml2_text_preprocessor"

RSpec.describe Metanorma::Plugin::Lutaml::Lutaml2TextPreprocessor do
  describe "#process" do
    let(:example_file) { "example.lutaml" }

    before do
      File.open(example_file, "w") do |n|
        n.puts(example_content)
      end
    end

    after do
      FileUtils.rm_rf(example_file)
    end

    context "Array of hashes" do
      let(:example_content) do
        <<~TEXT
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
          }
        TEXT
      end
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml2text,#{example_file},my_context]
          ----

          = {{ my_context.title }}

          {% for klass in my_context.classes %}
            == {{klass.name}}
          {% endfor %}

          {% for association in my_context.associations %}
            == {{association.name}}
            {{association.owner_end}} -> {{association.member_end}}
          {% endfor %}
          ----
        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
            <clause id="_" inline-header="false" obligation="normative">
              <title>my diagram</title>
              <figure id="_">
                <pre id="_">== AddressClassProfile</pre>
              </figure>
              <figure id="_">
                <pre id="_">== AttributeProfile</pre>
              </figure>
              <figure id="_">
                <pre id="_">== BidirectionalAsscoiation
          AddressClassProfile -&gt; AttributeProfile</pre>
              </figure>
            </clause>
          </sections>
          </standard-document>
          </body>
          </html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end
  end
end
