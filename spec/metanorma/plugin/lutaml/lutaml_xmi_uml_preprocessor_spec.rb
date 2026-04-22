require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlXmiUmlPreprocessor do
  describe "#process" do
    let(:example_file) { fixtures_path("large_test.xmi") }
    let(:config_file) { fixtures_path("lutaml_xmi_uml_config.yml") }
    subject(:output) { metanorma_process(input) }

    context "when there is no config file" do
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_xmi_uml,#{example_file}]
          --
          Name of the Lutaml UML Document: {{ context.name }}

          Number of packages: {{ context.packages | size }}
          --
        TEXT
      end

      context "correctly renders input" do
        it "shows the name of the context" do
          expect(output).to include("Name of the Lutaml UML Document: EA_Model")
        end

        it "shows the number of packages in context" do
          expect(output).to include("Number of packages: 1")
        end
      end
    end

    context "when using lutaml-xmi-index" do
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          :lutaml-xmi-index:first-xmi-index;#{example_file}

          [lutaml_xmi_uml,index=first-xmi-index]
          --
          Name of the Lutaml UML Document: {{ context.name }}

          Number of packages: {{ context.packages | size }}
          --
        TEXT
      end

      context "correctly renders input" do
        it "shows the name of the context" do
          expect(output).to include("Name of the Lutaml UML Document: EA_Model")
        end

        it "shows the number of packages in context" do
          expect(output).to include("Number of packages: 1")
        end
      end
    end

    context "when there is config file with context_name and template_path" do
      let (:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_xmi_uml,#{example_file},#{config_file}]
          --
          Name of the Lutaml UML Document: {{ my_uml_document.name }}

          Number of packages: {{ my_uml_document.packages | size }}

          {% render "package", package: my_uml_document.packages.first %}
          --
          {End of the document}
        TEXT
      end

      context "renders packages and classes" do
        it "shows the name of the context" do
          expect(output).to include("Name of the Lutaml UML Document: EA_Model")
        end

        it "shows the number of packages in root package" do
          expect(output).to include("Number of packages: 1")
        end

        it "contains packages with names" do
          expect(output).to include("Name of package: Wrapper root package")
          expect(output).to include("Name of package: Wrapper nested package")
          expect(output).to include("Name of package: CityGML")
          expect(output).to include("Name of package: Another")
          expect(output).to include("Name of package: CityTML")
          expect(output).to include("Name of package: Dynamizer")
        end

        it "contains classes in package Another" do
          expect(output).to include("Number of classes in package Another: 11")

          [
            "Name",
            "Definition",
            "Attributes",
            "Type",
            "Multiplicity",
            "Definition",
          ].each do |th|
            expect(output).to have_tag("th", text: /#{th}/)
          end

          [
            "AbstractAtomicTimeseries",
            "AbstractTimeseries",
            "AuthenticationTypeValue",
            "CompositeTimeseries",
            "Dynamizer",
            "GenericTimeseries",
            "SensorConnectionTypeValue",
            "StandardFileTimeseries",
            "StandardFileTypeValue",
            "TabulatedFileTimeseries",
            "TabulatedFileTypeValue",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end

        it "renders class table AbstractAtomicTimeseries" do
          expect(output).to include("Number of classes in package Another: 11")

          [
            "Name",
            "Definition",
            "Attributes",
            "Type",
            "Multiplicity",
            "Definition",
          ].each do |th|
            expect(output).to have_tag("th", text: /#{th}/)
          end

          [
            "adeOfAbstractAtomicTimeseries",
            "observationProperty",
            "uom",
            "ADEOfAbstractAtomicTimeseries",
            "CharacterString",
            "0..*",
            "1..1",
            "0..1",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end
      end

      context "renders associations" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end

        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_xmi_uml,#{example_file},#{config_file}]
            --
            Name of the Lutaml UML Document: {{ my_uml_document.name }}

            Number of packages: {{ my_uml_document.packages | size }}

            {% render "package", package: my_uml_document.packages.first %}
            --
            {End of the document}
          TEXT
        end

        it "shows associations" do
          [
            "xmi_id:",
            "EAID_996ED06F_4039_4b61_9B44_5D489EB4AD1F",
            "member_end:",
            "MultiSurface",
            "member_end_type:",
            "aggregation",
            "member_end_cardinality:",
            "0..1",
            "member_end_attribute_name:",
            "MultiSurface",
            "member_end_xmi_id:",
            "EAID_9CD87EC7_BBC1_4503_B284_14860C27C0BF",
            "owner_end:",
            "_UrbanFunction",
            "owner_end_xmi_id:",
            "EAID_ACABD6DC_E4F2_4a04_BBD4_25CECBBDC6F6",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end
      end

      context "renders a specific class" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end

        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_xmi_uml,#{example_file},#{config_file}]
            --
            Name of the Lutaml UML Document: {{ my_uml_document.name }}

            {% assign root_package = my_uml_document.packages.first %}

            {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

            {% assign urban_planning_ade_31_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.1" | first %}

            {% assign urf_package = urban_planning_ade_31_package.packages | where: "name", "uro" | first %}

            {% assign klass = urf_package.classes | where: "name", "DataQualityAttribute" | first %}

            {{ klass.name }}
            {{ klass.generalization.name }}
            {% assign root = klass.generalization %}
            {{ root.general.general_upper_klass }}:{{ root.general.general_name }}

            {% render "klass_table", klass: klass %}
            --

            {End of the document}
          TEXT
        end

        it "shows size of properties" do
          [
            "自身に定義された属性 14",
            "自身に定義された関連役割 1",
          ].each do |td|
            expect(output).to have_tag("th", text: /#{td}/)
          end
        end

        it "shows owned_props" do
          [
            "uro:appearanceSrcDescLod0",
            "\[DataQualityAttribute\]",
            "gml::CodeType",
            "\[0\.\.\*\]",
            "LOD0の幾何オブジェクトのアピアランスに使用した原典資料の種類。コードリスト",
            "uro:appearanceSrcDescLod1",
            "LOD1の幾何オブジェクトのアピアランスに使用した原典資料の種類。コードリスト",
            "uro:tranDataAcquisition",
            "xs::string",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end

        it "shows assoc_props" do
          [
            "uro:publicSurveyDataQualityAttribute",
            "\[DataQualityAttribute\]",
            "uro:PublicSuveyDataQualityAttribute",
            "\[0\.\.1\]",
            "使用した公共測量成果の地図情報レベルと種類。各LODの幾何オブジェクトの作成",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end
      end

      context "renders a specific class with generalization" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end

        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_xmi_uml,#{example_file},#{config_file}]
            --
            Name of the Lutaml UML Document: {{ my_uml_document.name }}

            {% assign root_package = my_uml_document.packages.first %}

            {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

            {% assign urban_planning_ade_31_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.1" | first %}

            {% assign urf_package = urban_planning_ade_31_package.packages | where: "name", "urf" | first %}

            {% assign klass = urf_package.classes | where: "name", "SedimentDisasterProneArea" | first %}

            {{ klass.name }}
            {{ klass.generalization.name }}
            {% assign root = klass.generalization %}
            {{ root.general.general_upper_klass }}:{{ root.general.general_name }}

            {% render "klass_table", klass: klass %}
            --

            {End of the document}
          TEXT
        end

        it "shows size of properties" do
          [
            "自身に定義された属性 5",
            "継承する関連役割 12",
            "継承する属性 31",
          ].each do |td|
            expect(output).to have_tag("th", text: /#{td}/)
          end
        end

        it "shows owned_props" do
          [
            "urf:areaType",
            "\[SedimentDisasterProneArea\]",
            "gml::CodeType",
            "\[1\.\.1\]",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end

        it "shows inherited_props" do
          [
            "gml:boundedBy",
            "\[_Feature\]",
            "gml::Envelope",
            "\[0\.\.1\]",
            "建築物の範囲及び適用される空間参照系",
            "core:creationDate",
            "\[_CityObject\]",
            "xs::date",
            "データが作成された日。運用上必須とする。",
            "urf:areaClassificationType",
            "\[_UrbanFunction\]",
            "gml::CodeType",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end

        it "shows inherited_assoc_props" do
          [
            "core:core::外部参照",
            "\[_CityObject\]",
            "core:外部参照",
            "\[0\.\.\*\]",
            "gen:_genericAttribute",
            "urf:lod0MultiCurve",
            "\[_UrbanFunction\]",
            "gml:MultiCurve",
          ].each do |td|
            expect(output).to have_tag("td", text: /#{td}/)
          end
        end
      end
    end
  end
end
