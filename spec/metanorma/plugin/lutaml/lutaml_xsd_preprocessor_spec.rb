require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "#process" do
    context "with macro: lutaml_xsd" do
      context "with content Elements and ComplexTypes of UnitsML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for element in unitsml.element %}

            Name: *{{ element.name }}*

            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for complex_type in unitsml.complex_type %}

            Name: *{{ complex_type.name }}*

            Description: {{ complex_type.annotation.documentation.first.content }}
            {% endfor %}
            ----
          TEXT
        end

        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
              <sections>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Elements</title>
                  <p id="_">
                    Name:
                    <strong>UnitsML</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>UnitsMLType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitSet</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>UnitSetType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Unit</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>UnitType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitSystem</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SystemType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitName</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NameType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitSymbol</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SymbolType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitVersionHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>CodeListValue</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>CodeListValueType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>RootUnits</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>RootUnitsType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>EnumeratedRootUnit</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>EnumeratedRootUnitType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ExternalRootUnit</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ExternalRootUnitType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Conversions</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ConversionsType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Float64ConversionFrom</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>Float64ConversionFromType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ConversionNote</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>SpecialConversionFrom</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SpecialConversionFromType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>WSDLConversionFrom</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>WSDLConversionFromType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>WSDLDescription</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ConversionDescription</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityReference</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ReferenceType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitDefinition</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>DefinitionType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>HistoryType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitRemark</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>RemarkType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>CountedItemSet</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>CountedItemSetType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>CountedItem</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>CountedItemType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemName</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NameType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemSymbol</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SymbolType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemVersionHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemDefinition</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>DefinitionType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>HistoryType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ItemRemark</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>RemarkType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantitySet</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>QuantitySetType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Quantity</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>QuantityType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityName</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NameType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantitySymbol</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SymbolType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>UnitReference</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ReferenceType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityVersionHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityDefinition</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>DefinitionType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityHistory</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>HistoryType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>QuantityRemark</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>RemarkType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>DimensionSet</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>DimensionSetType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Dimension</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>DimensionType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Length</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>LengthType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Mass</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>MassType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Time</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>TimeType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ElectricCurrent</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ElectricCurrentType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>ThermodynamicTemperature</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ThermodynamicTemperatureType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>AmountOfSubstance</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>AmountOfSubstanceType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>LuminousIntensity</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>LuminousIntensityType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>PlaneAngle</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>PlaneAngleType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Item</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>ItemType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>PrefixSet</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>PrefixSetType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>Prefix</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>PrefixType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>PrefixName</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>NameType</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>PrefixSymbol</strong>
                  </p>
                  <p id="_">
                    Type:
                    <strong>SymbolType</strong>
                  </p>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">ComplexTypes</title>
                  <p id="_">
                    Name:
                    <strong>UnitsMLType</strong>
                  </p>
                  <p id="_">Description: ComplexType for the root element of an UnitsML document.</p>
                  <p id="_">
                    Name:
                    <strong>UnitSetType</strong>
                  </p>
                  <p id="_">Description: Type for the unit container.</p>
                  <p id="_">
                    Name:
                    <strong>UnitType</strong>
                  </p>
                  <p id="_">Description: Type for the unit.</p>
                  <p id="_">
                    Name:
                    <strong>CodeListValueType</strong>
                  </p>
                  <p id="_">Description: Type for the element for listing the unit code value from a specific code list.</p>
                  <p id="_">
                    Name:
                    <strong>RootUnitsType</strong>
                  </p>
                  <p id="_">Description: Type for the container for defining derived units in terms of their root units. This allows a precise definition of a wide range of units. The goal is to improve interoperability among applications and databases which use derived units based on commonly encountered base units.</p>
                  <p id="_">
                    Name:
                    <strong>EnumeratedRootUnitType</strong>
                  </p>
                  <p id="_">Description: Type for the element for a root unit (from an extensive enumerated list) allowing an optional prefix and power. E.g., mm^2</p>
                  <p id="_">
                    Name:
                    <strong>ExternalRootUnitType</strong>
                  </p>
                  <p id="_">Description: Type for the element for those special cases where the root unit needed is not included in the enumerated list in the above element.</p>
                  <p id="_">
                    Name:
                    <strong>ConversionsType</strong>
                  </p>
                  <p id="_">Description: Type for the container for providing conversion information to other units.</p>
                  <p id="_">
                    Name:
                    <strong>Float64ConversionFromType</strong>
                  </p>
                  <p id="_">
                      Description: Type for the element for providing factors for a conversion equation from another unit; y = d + b / c) (x + a
                      <index>
                        <primary>b / c) (x + a</primary>
                      </index>
                  </p>
                  <p id="_">
                    Name:
                    <strong>SpecialConversionFromType</strong>
                  </p>
                  <p id="_">Description: Type for the element for providing unit conversion information for conversions that are more complex than the Float64ConversionFrom linear equation.</p>
                  <p id="_">
                    Name:
                    <strong>WSDLConversionFromType</strong>
                  </p>
                  <p id="_">Description: Type for the element for providing unit conversion information for conversions that are more complex than the Float64ConversionFrom linear equation.</p>
                  <p id="_">
                    Name:
                    <strong>CountedItemSetType</strong>
                  </p>
                  <p id="_">Description: Type for a set of counted items.</p>
                  <p id="_">
                    Name:
                    <strong>CountedItemType</strong>
                  </p>
                  <p id="_">Description: Type for a single counted item.</p>
                  <p id="_">
                    Name:
                    <strong>QuantitySetType</strong>
                  </p>
                  <p id="_">Description: Type for quantity container.</p>
                  <p id="_">
                    Name:
                    <strong>QuantityType</strong>
                  </p>
                  <p id="_">Description: Type for the quantity.</p>
                  <p id="_">
                    Name:
                    <strong>DimensionSetType</strong>
                  </p>
                  <p id="_">Description: Type for the dimension container.</p>
                  <p id="_">
                    Name:
                    <strong>DimensionType</strong>
                  </p>
                  <p id="_">Description: Type for dimension.</p>
                  <p id="_">
                    Name:
                    <strong>LengthType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity length.</p>
                  <p id="_">
                    Name:
                    <strong>MassType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity mass.</p>
                  <p id="_">
                    Name:
                    <strong>TimeType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity time.</p>
                  <p id="_">
                    Name:
                    <strong>ElectricCurrentType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity electric current.</p>
                  <p id="_">
                    Name:
                    <strong>ThermodynamicTemperatureType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity thermodynamic temperature.</p>
                  <p id="_">
                    Name:
                    <strong>AmountOfSubstanceType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity amount of substance.</p>
                  <p id="_">
                    Name:
                    <strong>LuminousIntensityType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity luminous intensity.</p>
                  <p id="_">
                    Name:
                    <strong>PlaneAngleType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity plane angle.</p>
                  <p id="_">
                    Name:
                    <strong>ItemType</strong>
                  </p>
                  <p id="_">Description: Type of the quantity represented by a counted item, e.g., electron</p>
                  <p id="_">
                    Name:
                    <strong>PrefixSetType</strong>
                  </p>
                  <p id="_">Description: Type for container for prefixes.</p>
                  <p id="_">
                    Name:
                    <strong>PrefixType</strong>
                  </p>
                  <p id="_">Description: Type for element for describing prefixes. Use in container PrefixSet.</p>
                  <p id="_">
                    Name:
                    <strong>NameType</strong>
                  </p>
                  <p id="_">Description: Type for name.  Used for names in units, quantities, and prefixes.</p>
                  <p id="_">
                    Name:
                    <strong>SystemType</strong>
                  </p>
                  <p id="_">Description: Type for unit system.</p>
                  <p id="_">
                    Name:
                    <strong>SymbolType</strong>
                  </p>
                  <p id="_">Description: Type for symbols.  Used in units, quantities, and prefixes.</p>
                  <p id="_">
                    Name:
                    <strong>NoteType</strong>
                  </p>
                  <p id="_">Description: Type for notes.  Used in units and conversion factors.</p>
                  <p id="_">
                    Name:
                    <strong>DefinitionType</strong>
                  </p>
                  <p id="_">Description: Type for definition.</p>
                  <p id="_">
                    Name:
                    <strong>HistoryType</strong>
                  </p>
                  <p id="_">Description: Type for history.</p>
                  <p id="_">
                    Name:
                    <strong>RemarkType</strong>
                  </p>
                  <p id="_">Description: Type for remark.</p>
                  <p id="_">
                    Name:
                    <strong>ReferenceType</strong>
                  </p>
                  <p id="_">Description: Type for reference to a unit or quantity.</p>
                </clause>
              </sections>
            </metanorma>
          TEXT
        end

        it "correctly renders input" do
          expect(xml_string_content(metanorma_convert(input)))
            .to(be_equivalent_to(output))
        end
      end

      context "with content Elements and ComplexTypes of UnitsML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},unitsml, location=https://raw.githubusercontent.com/t-yuki/ooxml-xsd/refs/heads/master]
            ----
            {% for element in unitsml.element %}

            Name: *{{ element.name }}*
            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},unitsml]
            ----
            {% for complex_type in unitsml.complex_type %}

            Name: *{{ complex_type.name }}*
            Description: {{ complex_type.annotation.documentation.first.content }}
            {% endfor %}
            ----
          TEXT
        end

        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
              <sections>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Elements</title>
                  <p id="_">
                    Name:
                    <strong>mathPr</strong>
                    Type:
                    <strong>CT_MathPr</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>oMathPara</strong>
                    Type:
                    <strong>CT_OMathPara</strong>
                  </p>
                  <p id="_">
                    Name:
                    <strong>oMath</strong>
                    Type:
                    <strong>CT_OMath</strong>
                  </p>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">ComplexTypes</title>
                  <p id="_">
                    Name:
                    <strong>CT_Integer255</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Integer2</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SpacingRule</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_UnSignedInteger</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Char</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OnOff</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_String</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_XAlign</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_YAlign</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Shp</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_FType</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_LimLoc</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_TopBot</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Script</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Style</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_ManualBreak</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_RPR</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Text</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_R</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_CtrlPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_AccPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Acc</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BarPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Bar</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BoxPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Box</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BorderBoxPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BorderBox</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_DPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_D</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_EqArrPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_EqArr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_FPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_F</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_FuncPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Func</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_GroupChrPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_GroupChr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_LimLowPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_LimLow</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_LimUppPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_LimUpp</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MCPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MC</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MCS</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MR</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_M</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_NaryPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Nary</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_PhantPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Phant</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_RadPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_Rad</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SPrePr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SPre</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSubPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSub</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSubSupPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSubSup</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSupPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_SSup</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMathArgPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMathArg</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMathJc</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMathParaPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_TwipsMeasure</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BreakBin</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_BreakBinSub</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_MathPr</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMathPara</strong>
                    Description:
                  </p>
                  <p id="_">
                    Name:
                    <strong>CT_OMath</strong>
                    Description:
                  </p>
                </clause>
              </sections>
            </metanorma>
          TEXT
        end

        it "correctly renders input" do
          expect(xml_string_content(metanorma_convert(input)))
            .to(be_equivalent_to(output))
        end
      end
    end
  end
end
