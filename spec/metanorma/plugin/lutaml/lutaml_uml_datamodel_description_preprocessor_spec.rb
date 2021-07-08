require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("test.xmi") }

    let(:input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_uml_datamodel_description,#{example_file}]
        --
        [.preface]
        ---
        mine text
        ---

        [.footer]
        ---
        footer text
        ---
        --
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        <sections><clause id="_" inline-header="false" obligation="normative"><title>preface</title>
        <p id="_">mine text</p>
        <clause id="_" inline-header="false" obligation="normative"><title>ISO 19135 Procedures for item registration XML</title>
        <clause id="rc_iso_19135_procedures_for_item_registration_xml-model_section" inline-header="false" obligation="normative">
        <title>ISO 19135 Procedures for item registration XML</title>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Requirements</title>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Class Definitions</title>
        <table id="_">
        <colgroup>
        <col width="25%">
        <col width="75%">
        </colgroup>
        <name>Classes used in ISO 19135 Procedures for item registration XML</name>
        <thead>
        <tr>
        <th valign="top" align="left">Class</th>
        <th valign="top" align="left">Description</th>
        </tr>
        </thead>
        <tbody>
        <tr>
        <td valign="top" align="left">
        <p id="_"><xref target="RE_Register-section">RE_Register</xref>
        &#171;interface&#187;</p>
        </td>
        <td valign="top" align="left">
        <p id="_">The class &#8220;RE_Register&#8221; specifies information about the register itself. It is a subtype of the Register class in the core profile.</p>
        </td>
        </tr>
        </tbody>
        </table>
        </clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>Additional Information</title>
        <p id="_">Additional information about the ISO 19135 Procedures for item registration XML can be found in the <link target="http://docs.opengeospatial.org/DRAFTS/20-066.html#ug-model-iso_19135_procedures_for_item_registration_xml-section">OGC CityGML 3.0 Users Guide</p>
        </clause></clause></clause>
        <clause id="_" inline-header="false" obligation="normative">
        <title>footer</title>
        <p id="_">footer text</p>
        </clause></sections>
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
