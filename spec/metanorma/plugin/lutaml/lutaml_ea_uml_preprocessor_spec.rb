require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlEaUmlPreprocessor do
  describe "#process" do
    let(:config_file) { fixtures_path("lutaml_ea_uml_config.yml") }
    subject(:output) { metanorma_process(input) }

    context "parseing simple EA XMI file" do
      let(:example_file) { fixtures_path("large_test.xmi") }

      context "when there is no config file" do
        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_ea_uml,#{example_file}]
            --
            Name of the Lutaml UML Document: {{ context.name }}

            Number of packages: {{ context.packages | size }}
            --
          TEXT
        end

        context "correctly renders input" do
          it "shows the name of the context" do
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
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

            [lutaml_ea_uml,index=first-xmi-index]
            --
            Name of the Lutaml UML Document: {{ context.name }}

            Number of packages: {{ context.packages | size }}```````````````````````````````````````````````````````````````````````````````````````````````
            --
          TEXT
        end

        context "correctly renders input" do
          it "shows the name of the context" do
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
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

            [lutaml_ea_uml,#{example_file},#{config_file}]
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
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
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
            expect(output)
              .to include("Number of classes in package Another: 11")

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
          let (:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_uml,#{example_file},#{config_file}]
              --
              Name of the Lutaml UML Document: {{ my_uml_document.name }}

              Number of packages: {{ my_uml_document.packages | size }}

              {% render "package", package: my_uml_document.packages.first %}
              --
              {End of the document}
            TEXT
          end
        end
      end
    end

    context "parseing plateau EA XMI file" do
      let(:example_file) do
        fixtures_path("ea_uml/20251010_current_plateau_v5.1.xmi")
      end

      context "when there is no config file" do
        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_ea_uml,#{example_file}]
            --
            Name of the Lutaml UML Document: {{ context.name }}

            Number of packages: {{ context.packages | size }}
            --
          TEXT
        end

        context "correctly renders input" do
          it "shows the name of the context" do
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
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

            [lutaml_ea_uml,index=first-xmi-index]
            --
            Name of the Lutaml UML Document: {{ context.name }}

            Number of packages: {{ context.packages | size }}```````````````````````````````````````````````````````````````````````````````````````````````
            --
          TEXT
        end

        context "correctly renders input" do
          it "shows the name of the context" do
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
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

            [lutaml_ea_uml,#{example_file},#{config_file}]
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
            expect(output)
              .to include("Name of the Lutaml UML Document: EA_Model")
          end

          it "shows the number of packages in root package" do
            expect(output).to include("Number of packages: 1")
          end

          it "contains packages with names" do
            expect(output).to include("Name of package: Conceptual Models")
            expect(output).to include("Name of package: 3D都市モデル")
            expect(output).to include("Name of package: CityGML2.0")
            expect(output).to include("Name of package: gml")
            expect(output).to include("Name of package: i-UR")
            expect(output).to include("Name of package: xs")
          end

          it "contains classes in packages" do
            expect(output)
              .to include("Number of classes in package bldg: 20")
            expect(output)
              .to include("Number of classes in package gml: 47")
            expect(output)
              .to include("Number of classes in package urf: 161")
            expect(output)
              .to include("Number of classes in package xs: 11")
          end

          it "contains classes in package bldg" do
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
              "BuildingPart",
              "CeilingSurface",
              "_Opening",
              "Door",
              "InteriorWallSurface",
              "WallSurface",
              "Building",
              "OuterFloorSurface",
              "IntBuildingInstallation",
              "_BoundarySurface",
              "OuterCeilingSurface",
              "_AbstractBuilding",
              "BuildingFurniture",
              "GroundSurface",
              "RoofSurface",
              "ClosureSurface",
              "BuildingInstallation",
              "FloorSurface",
              "Window",
              "Room",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "renders attributes in class BuildingFurniture" do
            [
              "室内の移動できる備品（家具）。",
              "bldg:IntBuildingInstallationが、建築物内部に設置された恒久的かつ固定" \
              "的な設備であることと対照的に、bldg:BuildingFurnitureは椅子やテーブル" \
              "のような、動かすことができる備品である。",
              "LOD4.2の場合にのみ取得する。",
              "ただし、ユースケースの要求に応じて、取得対象とする家具を限定してよい。",
              "class",
              "function",
              "lod4Geometry",
              "ifcBuildingFurnitureAttribute",
              "0..*",
              "0..1",
              "gml:CodeType",
              "_Geometry",
              "IfcAttribute",
              "家具の形態による区分。コードリスト",
              "家具の主たる働き。コードリスト",
              "家具の主な使い道。標準製品仕様書では使用しない。",
              "IDM・MVDで定義されるIFCに含まれる情報。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "renders associations in class BuildingFurniture (xmi only)" do
            [
              "EAID_852FF005_A86B_4c4e_B0FB_C08CBDA4CC5A",
              "aggregation",
              "EAID_1FFA9854_10E5_47a7_BE3E_4447F57FE997",
              "EAID_445424B4_89D6_44b1_AD5D_CDE5110FA344",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end

        context "renders a specific class (e.g. DataQualityAttribute)" do
          let (:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_uml,#{example_file},#{config_file}]
              --
              Name of the Lutaml UML Document: {{ my_uml_document.name }}

              {% assign root_package = my_uml_document.packages.first %}

              Root package name: {{ root_package.name }}

              {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

              Package name: {{ i_ur_package.name }}

              {% assign urban_planning_ade_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.2" | first %}

              Package name: {{ urban_planning_ade_package.name }}

              {% assign urf_package = urban_planning_ade_package.packages | where: "name", "uro" | first %}

              Package name: {{ urf_package.name }}

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
              "uro:geometrySrcDescLod0",
              "uro:geometrySrcDescLod1",
              "uro:geometrySrcDescLod2",
              "uro:geometrySrcDescLod3",
              "uro:geometrySrcDescLod4",
              "uro:thematicSrcDesc",
              "uro:appearanceSrcDescLod0",
              "uro:appearanceSrcDescLod1",
              "uro:appearanceSrcDescLod2",
              "uro:appearanceSrcDescLod3",
              "uro:appearanceSrcDescLod4",
              "uro:lodType",
              "uro:lod1HeightType",
              "uro:tranDataAcquisition",
              "\[DataQualityAttribute\]",
              "gml:CodeType",
              "\[0\.\.\*\]",
              "LOD0の幾何オブジェクトの作成に使用した原典資料の種類。",
              "uro:appearanceSrcDescLod1",
              "LOD1の幾何オブジェクトの作成に使用した原典資料の種類。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "shows assoc_props" do
            [
              "uro:publicSurveyDataQualityAttribute",
              "\[DataQualityAttribute\]",
              "uro:PublicSurveyDataQualityAttribute",
              "使用した公共測量成果又は基本測量成果の地図情報レベルと種類。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end

        context "renders a specific class with generalization " \
                "(e.g. ConstructionInstallation)" do
          let (:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_uml,#{example_file},#{config_file}]
              --
              Name of the Lutaml UML Document: {{ my_uml_document.name }}

              {% assign root_package = my_uml_document.packages.first %}

              {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

              {% assign urban_planning_ade_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.2" | first %}

              {% assign uro_package = urban_planning_ade_package.packages | where: "name", "uro" | first %}

              {% assign klass = uro_package.classes | where: "name", "ConstructionInstallation" | first %}

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
              "自身に定義された属性 3",
              "継承する属性 7",
              "自身に定義された関連役割 2",
              "継承する関連役割 9",
            ].each do |td|
              expect(output).to have_tag("th", text: /#{td}/)
            end
          end

          it "shows owned_props" do
            [
              "uro:class",
              "uro:function",
              "uro:usage",
              "\[ConstructionInstallation\]",
              "gml:CodeType",
              "付属物の分類。標準製品仕様書では使用しない。",
              "付属物の機能。",
              "付属物の用途。標準製品仕様書では使用しない。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "shows inherited_props" do
            [
              "gml:description",
              "gml:name",
              "gml:boundedBy",
              "core:creationDate",
              "core:terminationDate",
              "core:creationDate",
              "core:relativeToTerrain",
              "core:relativeToWater",
              "\[_Feature\]",
              "\[_CityObject\]",
              "gml:Envelope",
              "gml:StringOrRefTyp",
              "xs:date",
              "RelativeToTerrainType",
              "RelativeToWaterType",
              "都市オブジェクトの概要。",
              "都市オブジェクトを識別する名称。文字列とする。",
              "都市オブジェクトの範囲及び適用される空間参照系。",
              "データが作成された日。",
              "地表面との相対的な位置関係。標準製品仕様書では使用しない。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "shows inherited_props" do
            [
              "uro:lod2Geometry",
              "uro:lod3Geometry",
              "\[ConstructionInstallation\]",
              "gml:_Geometry",
              "LOD2において付属物の外形（外側から見える形）を構成する面を取得する。",
              "LOD3において付属物の外形（外側から見える形）を構成する面を取得する。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "shows inherited_assoc_props" do
            [
              "core:externalReference",
              "gen:stringAttribute",
              "gen:measureAttribute",
              "gen:dateAttribute",
              "uro:pointCloud",
              "\[_CityObject\]",
              "core:ExternalReference",
              "uro:AbstractPointCloud",
              "外部への参照。標準製品仕様書では使用しない。",
              "文字列型属性。属性を追加したい場合に使用する。",
              "日付型属性。属性を追加したい場合に使用する。",
              "ポイントクラウドへの参照。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end
      end
    end

    context "parseing plateau EA QEA file" do
      let(:example_file) do
        fixtures_path("ea_uml/20251010_current_plateau_v5.1.qea")
      end

      context "when there is no config file" do
        let (:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            [lutaml_ea_uml,#{example_file}]
            --
            Name of the Lutaml UML Document: {{ context.name }}

            Number of packages: {{ context.packages | size }}
            --
          TEXT
        end

        context "correctly renders input" do
          it "shows the name of the context" do
            expect(output)
              .to include("Name of the Lutaml UML Document: EA Model")
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

            [lutaml_ea_uml,#{example_file},#{config_file}]
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
            expect(output)
              .to include("Name of the Lutaml UML Document: EA Model")
          end

          it "shows the number of packages in root package" do
            expect(output).to include("Number of packages: 1")
          end

          it "contains packages with names" do
            expect(output).to include("Name of package: Conceptual Models")
            expect(output).to include("Name of package: 3D都市モデル")
            expect(output).to include("Name of package: CityGML2.0")
            expect(output).to include("Name of package: gml")
            expect(output).to include("Name of package: i-UR")
            expect(output).to include("Name of package: xs")
          end

          it "contains classes in packages" do
            expect(output)
              .to include("Number of classes in package bldg: 20")
            expect(output)
              .to include("Number of classes in package gml: 47")
            expect(output)
              .to include("Number of classes in package urf: 161")
            expect(output)
              .to include("Number of classes in package xs: 11")
          end

          it "contains classes in package bldg" do
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
              "BuildingPart",
              "CeilingSurface",
              "_Opening",
              "Door",
              "InteriorWallSurface",
              "WallSurface",
              "Building",
              "OuterFloorSurface",
              "IntBuildingInstallation",
              "_BoundarySurface",
              "OuterCeilingSurface",
              "_AbstractBuilding",
              "BuildingFurniture",
              "GroundSurface",
              "RoofSurface",
              "ClosureSurface",
              "BuildingInstallation",
              "FloorSurface",
              "Window",
              "Room",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          it "renders attributes in class BuildingFurniture" do
            [
              "class",
              "function",
              "usage",
              "lod4Geometry",
              "ifcBuildingFurnitureAttribute",
              "indoorFurnitureAttribute",
              "0..*",
              "0..1",
              "gml:CodeType",
              "_Geometry",
              "IfcAttribute",
              "IndoorAttribute",
              "室内の移動できる備品（家具）。",
              "家具の形態による区分。コードリスト",
              "家具の主たる働き。コードリスト",
              "家具の主な使い道。標準製品仕様書では使用しない。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end

        context "renders a specific class (e.g. DataQualityAttribute)" do
          let (:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_uml,#{example_file},#{config_file}]
              --
              Name of the Lutaml UML Document: {{ my_uml_document.name }}

              {% assign root_package = my_uml_document.packages.first %}

              Root package name: {{ root_package.name }}

              {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

              Package name: {{ i_ur_package.name }}

              {% assign urban_planning_ade_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.2" | first %}

              Package name: {{ urban_planning_ade_package.name }}

              {% assign uro_package = urban_planning_ade_package.packages | where: "name", "uro" | first %}

              Package name: {{ uro_package.name }}

              {% assign klass = uro_package.classes | where: "name", "DataQualityAttribute" | first %}

              {{ klass.name }}

              {% render "klass", klass: klass %}
              --

              {End of the document}
            TEXT
          end

          it "shows size of properties" do
            [
              "Attributes 15",
              "Associations 0",
            ].each do |td|
              expect(output).to have_tag("th", text: /#{td}/)
            end
          end

          it "shows owned_props" do
            [
              "geometrySrcDescLod0",
              "geometrySrcDescLod1",
              "geometrySrcDescLod2",
              "geometrySrcDescLod3",
              "geometrySrcDescLod4",
              "thematicSrcDesc",
              "appearanceSrcDescLod0",
              "appearanceSrcDescLod1",
              "appearanceSrcDescLod2",
              "appearanceSrcDescLod3",
              "appearanceSrcDescLod4",
              "lodType",
              "lod1HeightType",
              "tranDataAcquisition",
              "publicSurveyDataQualityAttribute",
              "LOD0の幾何オブジェクトの作成に使用した原典資料の種類。",
              "appearanceSrcDescLod1",
              "LOD1の幾何オブジェクトの作成に使用した原典資料の種類。",
              "LOD1の立体図形を作成する際に使用した高さの算出方法。",
              "幾何オブジェクトに適用されたLODの詳細な区分。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end

        context "renders a specific class with inherited attributes and " \
                "inherited associations" \
                "(e.g. ConstructionInstallation)" do
          let (:input) do
            <<~TEXT
              = Document title
              Author
              :nodoc:
              :novalid:
              :no-isobib:
              :imagesdir: spec/assets

              [lutaml_ea_uml,#{example_file},#{config_file}]
              --
              Name of the Lutaml UML Document: {{ my_uml_document.name }}

              {% assign root_package = my_uml_document.packages.first %}

              {% assign i_ur_package = root_package.packages | where: "name", "i-UR" | first %}

              {% assign urban_planning_ade_package = i_ur_package.packages | where: "name", "Urban Planning ADE 3.2" | first %}

              {% assign uro_package = urban_planning_ade_package.packages | where: "name", "uro" | first %}

              {% assign klass = uro_package.classes | where: "name", "ConstructionInstallation" | first %}

              {{ klass.name }}

              {% render "klass", klass: klass %}
              --

              {End of the document}
            TEXT
          end

          xit "shows size of properties" do
            [
              "自身に定義された属性 3",
              "継承する属性 7",
              "自身に定義された関連役割 2",
              "継承する関連役割 9",
            ].each do |td|
              expect(output).to have_tag("th", text: /#{td}/)
            end
          end

          xit "shows owned_props" do
            [
              "uro:class",
              "uro:function",
              "uro:usage",
              "\[ConstructionInstallation\]",
              "gml:CodeType",
              "付属物の分類。標準製品仕様書では使用しない。",
              "付属物の機能。",
              "付属物の用途。標準製品仕様書では使用しない。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          xit "shows inherited_props" do
            [
              "gml:description",
              "gml:name",
              "gml:boundedBy",
              "core:creationDate",
              "core:terminationDate",
              "core:creationDate",
              "core:relativeToTerrain",
              "core:relativeToWater",
              "\[_Feature\]",
              "\[_CityObject\]",
              "gml:Envelope",
              "gml:StringOrRefTyp",
              "xs:date",
              "RelativeToTerrainType",
              "RelativeToWaterType",
              "都市オブジェクトの概要。",
              "都市オブジェクトを識別する名称。文字列とする。",
              "都市オブジェクトの範囲及び適用される空間参照系。",
              "データが作成された日。",
              "地表面との相対的な位置関係。標準製品仕様書では使用しない。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          xit "shows inherited_props" do
            [
              "uro:lod2Geometry",
              "uro:lod3Geometry",
              "\[ConstructionInstallation\]",
              "gml:_Geometry",
              "LOD2において付属物の外形（外側から見える形）を構成する面を取得する。",
              "LOD3において付属物の外形（外側から見える形）を構成する面を取得する。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end

          xit "shows inherited_assoc_props" do
            [
              "core:externalReference",
              "gen:stringAttribute",
              "gen:measureAttribute",
              "gen:dateAttribute",
              "uro:pointCloud",
              "\[_CityObject\]",
              "core:ExternalReference",
              "uro:AbstractPointCloud",
              "外部への参照。標準製品仕様書では使用しない。",
              "文字列型属性。属性を追加したい場合に使用する。",
              "日付型属性。属性を追加したい場合に使用する。",
              "ポイントクラウドへの参照。",
            ].each do |td|
              expect(output).to have_tag("td", text: /#{td}/)
            end
          end
        end
      end
    end
  end
end
