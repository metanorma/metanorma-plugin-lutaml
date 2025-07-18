require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor do
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

      context "with content Elements and ComplexTypes of OMML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},omml, location=https://raw.githubusercontent.com/t-yuki/ooxml-xsd/refs/heads/master]
            ----
            {% for element in omml.element %}

            Name: *{{ element.name }}*
            Type: *{{ element.type }}*
            {% endfor %}
            ----

            = ComplexTypes
            [lutaml_xsd,#{fixtures_path('xsd_schemas/omml.xsd')},omml]
            ----
            {% for complex_type in omml.complex_type %}

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

      context "with content Elements and ComplexTypes of OMML schema" do
        let(:input) do
          <<~TEXT
            = Document title

            [#top]
            = Units Markup language (UnitsML) Schema Documentation unitsml-v1.0

            = Elements
            [lutaml_xsd,#{fixtures_path('xsd_schemas/unitsml-v1.0-csd04.xsd')},unitsml]
            ----
            {% for element in unitsml.element %}

            [#element_{{element.name}}]

            *Element:* {{ element.name }}

            *Type:* <<complex_type_{{element.type}},{{ element.type }}>>

            *Description:* {{ element.annotation.documentation.first.content }}
            {% assign used_by_elements = unitsml | used_by: element %}
            {% if used_by_elements.size > 0 %}*Used By:* {{ used_by_elements | join: ", " }}{% endif %}

            <<#top, &#x2303;>>

            ---
            {% endfor %}

            = Complex Types
            {% for complex_type in unitsml.complex_type %}

            [#complex_type_{{complex_type.name}}]

            *Complex Type:* {{ complex_type.name }}

            *Description:* {{ complex_type.annotation.documentation.first.content }}

            *Used By:* {{ unitsml | used_by: complex_type | join: ", " }}

            <<#top, &#x2303;>>

            ---
            {% endfor %}

            = Attribute Groups
            {% for attribute_group in unitsml.attribute_group %}

            [#attribute_group_{{attribute_group.name}}]

            *Attribute Group:* {{ attribute_group.name }}

            *Description:* {{ attribute_group.annotation.documentation.first.content }}

            *Used By:* {{ unitsml | used_by: attribute_group | join: ", " }}

            <<#top, &#x2303;>>

            ---
            {% endfor %}
            ----
          TEXT
        end

        let(:output) do
          <<~TEXT
            #{BLANK_HDR}
              <sections>
                <clause id="_" anchor="top" inline-header="false" obligation="normative">
                  <title id="_">Units Markup language (UnitsML) Schema Documentation unitsml-v1.0</title>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Elements</title>
                  <p id="_" anchor="element_UnitsML">
                      <strong>Element:</strong>
                      UnitsML
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_UnitsMLType" style="short">
                        <display-text>UnitsMLType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for UnitsML units, quantities, and prefixes.
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitSet">
                      <strong>Element:</strong>
                      UnitSet
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_UnitSetType" style="short">
                        <display-text>UnitSetType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for units. Use in UnitsML container or directly incorporate into a host schema.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsMLType' type definition." href="#complex_type_UnitsMLType">UnitsMLType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Unit">
                      <strong>Element:</strong>
                      Unit
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_UnitType" style="short">
                        <display-text>UnitType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for describing units. Use in containers UnitSet or directly incorporate into a host schema.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitSetType' type definition." href="#complex_type_UnitSetType">UnitSetType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitSystem">
                      <strong>Element:</strong>
                      UnitSystem
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SystemType" style="short">
                        <display-text>SystemType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for describing the system of units.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitName">
                      <strong>Element:</strong>
                      UnitName
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NameType" style="short">
                        <display-text>NameType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the unit name.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitSymbol">
                      <strong>Element:</strong>
                      UnitSymbol
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SymbolType" style="short">
                        <display-text>SymbolType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing various unit symbols. Examples include Aring (ASCII), Ã (HTML).
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitVersionHistory">
                      <strong>Element:</strong>
                      UnitVersionHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for descriptive information, including version changes to the unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_CodeListValue">
                      <strong>Element:</strong>
                      CodeListValue
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_CodeListValueType" style="short">
                        <display-text>CodeListValueType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for listing the unit code value from a specific code list.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_RootUnits">
                      <strong>Element:</strong>
                      RootUnits
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_RootUnitsType" style="short">
                        <display-text>RootUnitsType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for defining derived units in terms of their root units. This allows a precise definition of a wide range of units. The goal is to improve interoperability among applications and databases which use derived units based on commonly encountered root units.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_EnumeratedRootUnit">
                      <strong>Element:</strong>
                      EnumeratedRootUnit
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_EnumeratedRootUnitType" style="short">
                        <display-text>EnumeratedRootUnitType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for a root unit (from an extensive enumerated list) allowing an optional prefix and power. E.g., mm^2
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'RootUnitsType' type definition." href="#complex_type_RootUnitsType">RootUnitsType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ExternalRootUnit">
                      <strong>Element:</strong>
                      ExternalRootUnit
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ExternalRootUnitType" style="short">
                        <display-text>ExternalRootUnitType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for those special cases where the root unit needed is not included in the enumerated list in the above element.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'RootUnitsType' type definition." href="#complex_type_RootUnitsType">RootUnitsType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Conversions">
                      <strong>Element:</strong>
                      Conversions
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ConversionsType" style="short">
                        <display-text>ConversionsType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for providing conversion information to other units.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Float64ConversionFrom">
                      <strong>Element:</strong>
                      Float64ConversionFrom
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_Float64ConversionFromType" style="short">
                        <display-text>Float64ConversionFromType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for providing factors for a conversion equation from another unit; y = d + b / c) (x + a
                      <index>
                        <primary>b / c) (x + a</primary>
                      </index>
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ConversionsType' type definition." href="#complex_type_ConversionsType">ConversionsType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ConversionNote">
                      <strong>Element:</strong>
                      ConversionNote
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for descriptive information.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Float64ConversionFromType' type definition." href="#complex_type_Float64ConversionFromType">Float64ConversionFromType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_SpecialConversionFrom">
                      <strong>Element:</strong>
                      SpecialConversionFrom
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SpecialConversionFromType" style="short">
                        <display-text>SpecialConversionFromType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for providing unit conversion information for conversions that are more complex than the Float64ConversionFrom linear equation.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ConversionsType' type definition." href="#complex_type_ConversionsType">ConversionsType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_WSDLConversionFrom">
                      <strong>Element:</strong>
                      WSDLConversionFrom
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_WSDLConversionFromType" style="short">
                        <display-text>WSDLConversionFromType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for providing conversion based on SOAP/WSDL calls to a remote server.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ConversionsType' type definition." href="#complex_type_ConversionsType">ConversionsType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_WSDLDescription">
                      <strong>Element:</strong>
                      WSDLDescription
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the WSDL service.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'WSDLConversionFromType' type definition." href="#complex_type_WSDLConversionFromType">WSDLConversionFromType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ConversionDescription">
                      <strong>Element:</strong>
                      ConversionDescription
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for a description of the SpecialConversionFrom.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'SpecialConversionFromType' type definition." href="#complex_type_SpecialConversionFromType">SpecialConversionFromType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityReference">
                      <strong>Element:</strong>
                      QuantityReference
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ReferenceType" style="short">
                        <display-text>ReferenceType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for all quantities that can be expressed using this unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitDefinition">
                      <strong>Element:</strong>
                      UnitDefinition
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_DefinitionType" style="short">
                        <display-text>DefinitionType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the definition of the unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitHistory">
                      <strong>Element:</strong>
                      UnitHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_HistoryType" style="short">
                        <display-text>HistoryType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the historical development of the unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitRemark">
                      <strong>Element:</strong>
                      UnitRemark
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_RemarkType" style="short">
                        <display-text>RemarkType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element as a placeholder for additional information.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_CountedItemSet">
                      <strong>Element:</strong>
                      CountedItemSet
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_CountedItemSetType" style="short">
                        <display-text>CountedItemSetType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for items that are counted and are (in practice) combined with scientific units of measure.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsMLType' type definition." href="#complex_type_UnitsMLType">UnitsMLType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_CountedItem">
                      <strong>Element:</strong>
                      CountedItem
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_CountedItemType" style="short">
                        <display-text>CountedItemType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for a single counted item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemSetType' type definition." href="#complex_type_CountedItemSetType">CountedItemSetType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemName">
                      <strong>Element:</strong>
                      ItemName
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NameType" style="short">
                        <display-text>NameType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the item name(s).
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemSymbol">
                      <strong>Element:</strong>
                      ItemSymbol
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SymbolType" style="short">
                        <display-text>SymbolType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing symbols for the item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemVersionHistory">
                      <strong>Element:</strong>
                      ItemVersionHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for descriptive information, including version changes to the item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemDefinition">
                      <strong>Element:</strong>
                      ItemDefinition
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_DefinitionType" style="short">
                        <display-text>DefinitionType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the definition of the item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemHistory">
                      <strong>Element:</strong>
                      ItemHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_HistoryType" style="short">
                        <display-text>HistoryType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the historical development of the item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ItemRemark">
                      <strong>Element:</strong>
                      ItemRemark
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_RemarkType" style="short">
                        <display-text>RemarkType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element as a placeholder for additional information.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemType' type definition." href="#complex_type_CountedItemType">CountedItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantitySet">
                      <strong>Element:</strong>
                      QuantitySet
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_QuantitySetType" style="short">
                        <display-text>QuantitySetType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for quantities.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsMLType' type definition." href="#complex_type_UnitsMLType">UnitsMLType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Quantity">
                      <strong>Element:</strong>
                      Quantity
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_QuantityType" style="short">
                        <display-text>QuantityType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for describing quantities and referencing corresponding units. Use in container or directly incorporate into a host schema.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantitySetType' type definition." href="#complex_type_QuantitySetType">QuantitySetType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityName">
                      <strong>Element:</strong>
                      QuantityName
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NameType" style="short">
                        <display-text>NameType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the quantity name.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantitySymbol">
                      <strong>Element:</strong>
                      QuantitySymbol
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SymbolType" style="short">
                        <display-text>SymbolType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing various quantity symbols.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_UnitReference">
                      <strong>Element:</strong>
                      UnitReference
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ReferenceType" style="short">
                        <display-text>ReferenceType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for referencing a unit of measure from within the Quantity element.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityVersionHistory">
                      <strong>Element:</strong>
                      QuantityVersionHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NoteType" style="short">
                        <display-text>NoteType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element for descriptive information, including version changes to the unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityDefinition">
                      <strong>Element:</strong>
                      QuantityDefinition
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_DefinitionType" style="short">
                        <display-text>DefinitionType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the definition of the quantity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityHistory">
                      <strong>Element:</strong>
                      QuantityHistory
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_HistoryType" style="short">
                        <display-text>HistoryType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to describe the historical development of the quantity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_QuantityRemark">
                      <strong>Element:</strong>
                      QuantityRemark
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_RemarkType" style="short">
                        <display-text>RemarkType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element as a placeholder for additional information.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_DimensionSet">
                      <strong>Element:</strong>
                      DimensionSet
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_DimensionSetType" style="short">
                        <display-text>DimensionSetType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for dimensions.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsMLType' type definition." href="#complex_type_UnitsMLType">UnitsMLType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Dimension">
                      <strong>Element:</strong>
                      Dimension
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_DimensionType" style="short">
                        <display-text>DimensionType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element to express the dimension of a unit or quantity in terms of the SI base quantities length, mass, time, electric current, thermodynamic temperature, amount of substance, and luminous intensity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionSetType' type definition." href="#complex_type_DimensionSetType">DimensionSetType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Length">
                      <strong>Element:</strong>
                      Length
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_LengthType" style="short">
                        <display-text>LengthType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity length.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Mass">
                      <strong>Element:</strong>
                      Mass
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_MassType" style="short">
                        <display-text>MassType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity mass.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Time">
                      <strong>Element:</strong>
                      Time
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_TimeType" style="short">
                        <display-text>TimeType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity time.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ElectricCurrent">
                      <strong>Element:</strong>
                      ElectricCurrent
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ElectricCurrentType" style="short">
                        <display-text>ElectricCurrentType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity electric current.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_ThermodynamicTemperature">
                      <strong>Element:</strong>
                      ThermodynamicTemperature
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ThermodynamicTemperatureType" style="short">
                        <display-text>ThermodynamicTemperatureType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity thermodynamic temerature.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_AmountOfSubstance">
                      <strong>Element:</strong>
                      AmountOfSubstance
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_AmountOfSubstanceType" style="short">
                        <display-text>AmountOfSubstanceType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity amount of substance.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_LuminousIntensity">
                      <strong>Element:</strong>
                      LuminousIntensity
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_LuminousIntensityType" style="short">
                        <display-text>LuminousIntensityType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity luminous intensity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_PlaneAngle">
                      <strong>Element:</strong>
                      PlaneAngle
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_PlaneAngleType" style="short">
                        <display-text>PlaneAngleType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of the quantity plane angle.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Item">
                      <strong>Element:</strong>
                      Item
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_ItemType" style="short">
                        <display-text>ItemType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the dimension of any item. Note: this element is meant to be used to allow counted items to be included in the dimensioning of a derived quantity, e.g., electrons per time; usage of this element does not conform to the SI description of the dimension of a quantity in terms of seven base quantities.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionType' type definition." href="#complex_type_DimensionType">DimensionType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_PrefixSet">
                      <strong>Element:</strong>
                      PrefixSet
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_PrefixSetType" style="short">
                        <display-text>PrefixSetType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Container for prefixes.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsMLType' type definition." href="#complex_type_UnitsMLType">UnitsMLType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_Prefix">
                      <strong>Element:</strong>
                      Prefix
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_PrefixType" style="short">
                        <display-text>PrefixType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing information about a prefix.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'PrefixSetType' type definition." href="#complex_type_PrefixSetType">PrefixSetType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_PrefixName">
                      <strong>Element:</strong>
                      PrefixName
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_NameType" style="short">
                        <display-text>NameType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing the prefix name.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'PrefixType' type definition." href="#complex_type_PrefixType">PrefixType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="element_PrefixSymbol">
                      <strong>Element:</strong>
                      PrefixSymbol
                  </p>
                  <p id="_">
                      <strong>Type:</strong>
                      <xref target="complex_type_SymbolType" style="short">
                        <display-text>SymbolType</display-text>
                      </xref>
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Element containing prefix symbols.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'PrefixType' type definition." href="#complex_type_PrefixType">PrefixType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Complex Types</title>
                  <p id="_" anchor="complex_type_UnitsMLType">
                      <strong>Complex Type:</strong>
                      UnitsMLType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      ComplexType for the root element of an UnitsML document.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitsML' element declaration." href="#element_UnitsML">UnitsML</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_UnitSetType">
                      <strong>Complex Type:</strong>
                      UnitSetType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the unit container.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitSet' element declaration." href="#element_UnitSet">UnitSet</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_UnitType">
                      <strong>Complex Type:</strong>
                      UnitType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the unit.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Unit' element declaration." href="#element_Unit">Unit</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_CodeListValueType">
                      <strong>Complex Type:</strong>
                      CodeListValueType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for listing the unit code value from a specific code list.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CodeListValue' element declaration." href="#element_CodeListValue">CodeListValue</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_RootUnitsType">
                      <strong>Complex Type:</strong>
                      RootUnitsType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the container for defining derived units in terms of their root units. This allows a precise definition of a wide range of units. The goal is to improve interoperability among applications and databases which use derived units based on commonly encountered base units.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'RootUnits' element declaration." href="#element_RootUnits">RootUnits</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_EnumeratedRootUnitType">
                      <strong>Complex Type:</strong>
                      EnumeratedRootUnitType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for a root unit (from an extensive enumerated list) allowing an optional prefix and power. E.g., mm^2
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'EnumeratedRootUnit' element declaration." href="#element_EnumeratedRootUnit">EnumeratedRootUnit</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ExternalRootUnitType">
                      <strong>Complex Type:</strong>
                      ExternalRootUnitType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for those special cases where the root unit needed is not included in the enumerated list in the above element.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ExternalRootUnit' element declaration." href="#element_ExternalRootUnit">ExternalRootUnit</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ConversionsType">
                      <strong>Complex Type:</strong>
                      ConversionsType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the container for providing conversion information to other units.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Conversions' element declaration." href="#element_Conversions">Conversions</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_Float64ConversionFromType">
                      <strong>Complex Type:</strong>
                      Float64ConversionFromType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for providing factors for a conversion equation from another unit; y = d + b / c) (x + a
                      <index>
                        <primary>b / c) (x + a</primary>
                      </index>
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Float64ConversionFrom' element declaration." href="#element_Float64ConversionFrom">Float64ConversionFrom</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_SpecialConversionFromType">
                      <strong>Complex Type:</strong>
                      SpecialConversionFromType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for providing unit conversion information for conversions that are more complex than the Float64ConversionFrom linear equation.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'SpecialConversionFrom' element declaration." href="#element_SpecialConversionFrom">SpecialConversionFrom</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_WSDLConversionFromType">
                      <strong>Complex Type:</strong>
                      WSDLConversionFromType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the element for providing unit conversion information for conversions that are more complex than the Float64ConversionFrom linear equation.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'WSDLConversionFrom' element declaration." href="#element_WSDLConversionFrom">WSDLConversionFrom</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_CountedItemSetType">
                      <strong>Complex Type:</strong>
                      CountedItemSetType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for a set of counted items.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItemSet' element declaration." href="#element_CountedItemSet">CountedItemSet</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_CountedItemType">
                      <strong>Complex Type:</strong>
                      CountedItemType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for a single counted item.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'CountedItem' element declaration." href="#element_CountedItem">CountedItem</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_QuantitySetType">
                      <strong>Complex Type:</strong>
                      QuantitySetType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for quantity container.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantitySet' element declaration." href="#element_QuantitySet">QuantitySet</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_QuantityType">
                      <strong>Complex Type:</strong>
                      QuantityType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the quantity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Quantity' element declaration." href="#element_Quantity">Quantity</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_DimensionSetType">
                      <strong>Complex Type:</strong>
                      DimensionSetType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for the dimension container.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DimensionSet' element declaration." href="#element_DimensionSet">DimensionSet</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_DimensionType">
                      <strong>Complex Type:</strong>
                      DimensionType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for dimension.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Dimension' element declaration." href="#element_Dimension">Dimension</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_LengthType">
                      <strong>Complex Type:</strong>
                      LengthType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity length.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Length' element declaration." href="#element_Length">Length</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_MassType">
                      <strong>Complex Type:</strong>
                      MassType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity mass.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Mass' element declaration." href="#element_Mass">Mass</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_TimeType">
                      <strong>Complex Type:</strong>
                      TimeType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity time.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Time' element declaration." href="#element_Time">Time</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ElectricCurrentType">
                      <strong>Complex Type:</strong>
                      ElectricCurrentType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity electric current.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ElectricCurrent' element declaration." href="#element_ElectricCurrent">ElectricCurrent</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ThermodynamicTemperatureType">
                      <strong>Complex Type:</strong>
                      ThermodynamicTemperatureType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity thermodynamic temperature.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'ThermodynamicTemperature' element declaration." href="#element_ThermodynamicTemperature">ThermodynamicTemperature</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_AmountOfSubstanceType">
                      <strong>Complex Type:</strong>
                      AmountOfSubstanceType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity amount of substance.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'AmountOfSubstance' element declaration." href="#element_AmountOfSubstance">AmountOfSubstance</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_LuminousIntensityType">
                      <strong>Complex Type:</strong>
                      LuminousIntensityType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity luminous intensity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'LuminousIntensity' element declaration." href="#element_LuminousIntensity">LuminousIntensity</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_PlaneAngleType">
                      <strong>Complex Type:</strong>
                      PlaneAngleType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity plane angle.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'PlaneAngle' element declaration." href="#element_PlaneAngle">PlaneAngle</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ItemType">
                      <strong>Complex Type:</strong>
                      ItemType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type of the quantity represented by a counted item, e.g., electron
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Item' element declaration." href="#element_Item">Item</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_PrefixSetType">
                      <strong>Complex Type:</strong>
                      PrefixSetType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for container for prefixes.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'PrefixSet' element declaration." href="#element_PrefixSet">PrefixSet</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_PrefixType">
                      <strong>Complex Type:</strong>
                      PrefixType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for element for describing prefixes. Use in container PrefixSet.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Prefix' element declaration." href="#element_Prefix">Prefix</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_NameType">
                      <strong>Complex Type:</strong>
                      NameType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for name. Used for names in units, quantities, and prefixes.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitName' element declaration." href="#element_UnitName">UnitName</a>
                      ,
                      <a title="Jump to 'ItemName' element declaration." href="#element_ItemName">ItemName</a>
                      ,
                      <a title="Jump to 'QuantityName' element declaration." href="#element_QuantityName">QuantityName</a>
                      ,
                      <a title="Jump to 'PrefixName' element declaration." href="#element_PrefixName">PrefixName</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_SystemType">
                      <strong>Complex Type:</strong>
                      SystemType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for unit system.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitSystem' element declaration." href="#element_UnitSystem">UnitSystem</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_SymbolType">
                      <strong>Complex Type:</strong>
                      SymbolType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for symbols. Used in units, quantities, and prefixes.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitSymbol' element declaration." href="#element_UnitSymbol">UnitSymbol</a>
                      ,
                      <a title="Jump to 'ItemSymbol' element declaration." href="#element_ItemSymbol">ItemSymbol</a>
                      ,
                      <a title="Jump to 'QuantitySymbol' element declaration." href="#element_QuantitySymbol">QuantitySymbol</a>
                      ,
                      <a title="Jump to 'PrefixSymbol' element declaration." href="#element_PrefixSymbol">PrefixSymbol</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_NoteType">
                      <strong>Complex Type:</strong>
                      NoteType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for notes. Used in units and conversion factors.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitVersionHistory' element declaration." href="#element_UnitVersionHistory">UnitVersionHistory</a>
                      ,
                      <a title="Jump to 'ConversionNote' element declaration." href="#element_ConversionNote">ConversionNote</a>
                      ,
                      <a title="Jump to 'WSDLDescription' element declaration." href="#element_WSDLDescription">WSDLDescription</a>
                      ,
                      <a title="Jump to 'ConversionDescription' element declaration." href="#element_ConversionDescription">ConversionDescription</a>
                      ,
                      <a title="Jump to 'ItemVersionHistory' element declaration." href="#element_ItemVersionHistory">ItemVersionHistory</a>
                      ,
                      <a title="Jump to 'QuantityVersionHistory' element declaration." href="#element_QuantityVersionHistory">QuantityVersionHistory</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_DefinitionType">
                      <strong>Complex Type:</strong>
                      DefinitionType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for definition.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitDefinition' element declaration." href="#element_UnitDefinition">UnitDefinition</a>
                      ,
                      <a title="Jump to 'ItemDefinition' element declaration." href="#element_ItemDefinition">ItemDefinition</a>
                      ,
                      <a title="Jump to 'QuantityDefinition' element declaration." href="#element_QuantityDefinition">QuantityDefinition</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_HistoryType">
                      <strong>Complex Type:</strong>
                      HistoryType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for history.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitHistory' element declaration." href="#element_UnitHistory">UnitHistory</a>
                      ,
                      <a title="Jump to 'ItemHistory' element declaration." href="#element_ItemHistory">ItemHistory</a>
                      ,
                      <a title="Jump to 'QuantityHistory' element declaration." href="#element_QuantityHistory">QuantityHistory</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_RemarkType">
                      <strong>Complex Type:</strong>
                      RemarkType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for remark.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitRemark' element declaration." href="#element_UnitRemark">UnitRemark</a>
                      ,
                      <a title="Jump to 'ItemRemark' element declaration." href="#element_ItemRemark">ItemRemark</a>
                      ,
                      <a title="Jump to 'QuantityRemark' element declaration." href="#element_QuantityRemark">QuantityRemark</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="complex_type_ReferenceType">
                      <strong>Complex Type:</strong>
                      ReferenceType
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Type for reference to a unit or quantity.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'QuantityReference' element declaration." href="#element_QuantityReference">QuantityReference</a>
                      ,
                      <a title="Jump to 'UnitReference' element declaration." href="#element_UnitReference">UnitReference</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                </clause>
                <clause id="_" inline-header="false" obligation="normative">
                  <title id="_">Attribute Groups</title>
                  <p id="_" anchor="attribute_group_initialUnit">
                      <strong>Attribute Group:</strong>
                      initialUnit
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      URI indicating the unitID of the starting unit for the conversion. For units which are defined in the same document, the URI should consist of a pound sign (#) followed by the ID value.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'Float64ConversionFromType' type definition." href="#complex_type_Float64ConversionFromType">Float64ConversionFromType</a>
                      ,
                      <a title="Jump to 'SpecialConversionFromType' type definition." href="#complex_type_SpecialConversionFromType">SpecialConversionFromType</a>
                      ,
                      <a title="Jump to 'WSDLConversionFromType' type definition." href="#complex_type_WSDLConversionFromType">WSDLConversionFromType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="attribute_group_sourceName">
                      <strong>Attribute Group:</strong>
                      sourceName
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Name of relevant publication.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'DefinitionType' type definition." href="#complex_type_DefinitionType">DefinitionType</a>
                      ,
                      <a title="Jump to 'HistoryType' type definition." href="#complex_type_HistoryType">HistoryType</a>
                      ,
                      <a title="Jump to 'RemarkType' type definition." href="#complex_type_RemarkType">RemarkType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="attribute_group_sourceURL">
                      <strong>Attribute Group:</strong>
                      sourceURL
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Relevant URL for available information.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'EnumeratedRootUnitType' type definition." href="#complex_type_EnumeratedRootUnitType">EnumeratedRootUnitType</a>
                      ,
                      <a title="Jump to 'ExternalRootUnitType' type definition." href="#complex_type_ExternalRootUnitType">ExternalRootUnitType</a>
                      ,
                      <a title="Jump to 'DefinitionType' type definition." href="#complex_type_DefinitionType">DefinitionType</a>
                      ,
                      <a title="Jump to 'HistoryType' type definition." href="#complex_type_HistoryType">HistoryType</a>
                      ,
                      <a title="Jump to 'RemarkType' type definition." href="#complex_type_RemarkType">RemarkType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="attribute_group_powerRational">
                      <strong>Attribute Group:</strong>
                      powerRational
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      An exponent of the unit, specified as powerNumerator and powerDenominator.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'EnumeratedRootUnitType' type definition." href="#complex_type_EnumeratedRootUnitType">EnumeratedRootUnitType</a>
                      ,
                      <a title="Jump to 'ExternalRootUnitType' type definition." href="#complex_type_ExternalRootUnitType">ExternalRootUnitType</a>
                      ,
                      <a title="Jump to 'LengthType' type definition." href="#complex_type_LengthType">LengthType</a>
                      ,
                      <a title="Jump to 'MassType' type definition." href="#complex_type_MassType">MassType</a>
                      ,
                      <a title="Jump to 'TimeType' type definition." href="#complex_type_TimeType">TimeType</a>
                      ,
                      <a title="Jump to 'ElectricCurrentType' type definition." href="#complex_type_ElectricCurrentType">ElectricCurrentType</a>
                      ,
                      <a title="Jump to 'ThermodynamicTemperatureType' type definition." href="#complex_type_ThermodynamicTemperatureType">ThermodynamicTemperatureType</a>
                      ,
                      <a title="Jump to 'AmountOfSubstanceType' type definition." href="#complex_type_AmountOfSubstanceType">AmountOfSubstanceType</a>
                      ,
                      <a title="Jump to 'LuminousIntensityType' type definition." href="#complex_type_LuminousIntensityType">LuminousIntensityType</a>
                      ,
                      <a title="Jump to 'PlaneAngleType' type definition." href="#complex_type_PlaneAngleType">PlaneAngleType</a>
                      ,
                      <a title="Jump to 'ItemType' type definition." href="#complex_type_ItemType">ItemType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="attribute_group_prefix">
                      <strong>Attribute Group:</strong>
                      prefix
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      Prefix identifier; e.g., m, k, M, G. [Enumeration order is by prefix magnitude (Y to y) followed by binary prefixes.]
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'EnumeratedRootUnitType' type definition." href="#complex_type_EnumeratedRootUnitType">EnumeratedRootUnitType</a>
                      ,
                      <a title="Jump to 'ExternalRootUnitType' type definition." href="#complex_type_ExternalRootUnitType">ExternalRootUnitType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
                  <p id="_" anchor="attribute_group_dimensionURL">
                      <strong>Attribute Group:</strong>
                      dimensionURL
                  </p>
                  <p id="_">
                      <strong>Description:</strong>
                      URL to a representation of the unit or quantity in terms of the 7 SI base dimensions.
                  </p>
                  <p id="_">
                      <strong>Used By:</strong>
                      <a title="Jump to 'UnitType' type definition." href="#complex_type_UnitType">UnitType</a>
                      ,
                      <a title="Jump to 'QuantityType' type definition." href="#complex_type_QuantityType">QuantityType</a>
                  </p>
                  <p id="_">
                      <xref target="top" style="short">
                        <display-text>⌃</display-text>
                      </xref>
                  </p>
                  <hr/>
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
