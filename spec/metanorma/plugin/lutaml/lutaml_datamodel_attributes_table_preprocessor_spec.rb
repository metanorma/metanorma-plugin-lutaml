require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlUmlAttributesTablePreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("diagram_definitions.lutaml") }

    context "when class passed as entity" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_uml_attributes_table,#{example_file},AttributeProfile]

        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
          <title>AttributeProfile</title>
          <table id="_">
          <name>AttributeProfile attributes</name>
          <thead>
          <tr>
          <th valign="top" align="left">Name</th>
          <th valign="top" align="left">Definition</th>
          <th valign="top" align="left">Mandatory/ Optional/ Conditional</th>
          <th valign="top" align="left">Max Occur</th>
          <th valign="top" align="left">Data Type</th>
          </tr>
          </thead>
          <tbody>
          <tr>
          <td valign="top" align="left">addressClassProfile</td>
          <td valign="top" align="left">TODO: enum ‘s definition</td>
          <td valign="top" align="left">O</td>
          <td valign="top" align="left">1</td>
          <td valign="top" align="left">
          <tt>CharacterString</tt>
          </td>
          </tr>
          <tr>
          <td valign="top" align="left">imlicistAttributeProfile</td>
          <td valign="top" align="left">this is attribute definition
          with multiply lines</td>
          <td valign="top" align="left">O</td>
          <td valign="top" align="left">1</td>
          <td valign="top" align="left">
          <tt>CharacterString</tt>
          </td>
          </tr>
          </tbody>
          </table>
          </clause>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end

    context "when enumeration name passed as entity" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :docfile: test.adoc
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_uml_attributes_table,#{example_file},AddressClassProfile]

        TEXT
      end
      let(:output) do
        <<~TEXT
          #{BLANK_HDR}
          <sections>
          <clause id="_" inline-header="false" obligation="normative">
          <title>AddressClassProfile</title>
          <table id="_">
          <name>AddressClassProfile values</name>
          <thead>
          <tr>
          <th valign="top" align="left">Name</th>
          <th valign="top" align="left">Definition</th>
          </tr>
          </thead>
          <tbody>
          <tr>
          <td valign="top" align="left">imlicistAttributeProfile</td>
          <td valign="top" align="left">this is multiline with <tt>ascidoc</tt>
                  comments
                  and list</td>
          </tr>
          </tbody>
          </table>
          </clause>
          </sections>
          </standard-document>
          </body></html>
        TEXT
      end

      it "correctly renders input" do
        expect(xml_string_conent(metanorma_process(input)))
          .to(be_equivalent_to(output))
      end
    end
  end
end
