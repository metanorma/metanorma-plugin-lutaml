require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlKlassTableBlockMacro do
  describe "#process" do
    building_inherited_properties = [
      {
        name: "bldg:class",
        type: "gml::CodeType [0..1]",
        def: "建築物の形態による区分。コードリスト()より選択する。",
      },
      {
        name: "bldg:function",
        type: "gml::CodeType [0..*]",
        def: "建築物の主たる働き。",
      },
      {
        name: "bldg:measuredHeight",
        type: "gml::LengthType [0..1]",
        def: "計測により取得した建築物の地上の最低点から最高点までの高さ。単位はm (uom=?m?)とする。",
      },
      {
        name: "bldg:roofType",
        type: "gml::CodeType [0..1]",
        def: "建築物の屋根形状の種類。 コ-ドリスト()より選択する。",
      },
      {
        name: "bldg:storeyHeightsAboveGround",
        type: "gml::MeasureOrNullListType [0..1]",
        def: "地上の各階の高さを、地表面に最も近い階から列挙する。",
      },
      {
        name: "bldg:storeyHeightsBelowGround",
        type: "gml::MeasureOrNullListType [0..1]",
        def: "地下の各階の高さを、地表面に最も近い階から列挙する。",
      },
      {
        name: "bldg:storeysAboveGround",
        type: "xs::nonNegativeInteger [0..1]",
        def: "地上階の階数。",
      },
      {
        name: "bldg:storeysBelowGround",
        type: "xs::nonNegativeInteger [0..1]",
        def: "地下階の階数。",
      },
      {
        name: "bldg:usage",
        type: "gml::CodeType [0..*]",
        def: "建築物の主な使い道。 コードリスト()より選択する。 用途の区分は、都市計画基礎調査実施要領(国土交通省都市局)による区分とする。複数の建築物で一体の施設を構成しているものについては、一体としての用途とする。店舗等併用住宅、同共同住宅、作業所併用住宅は、1/3 以上が住宅のものとする。複合用途の建築物(商業系複合施設及び併用住宅を除く)については、主たる用途により分類する。複数の用途を記述する場合は、主たる用途を最初に記載する。",
      },
      {
        name: "bldg:yearOfConstruction",
        type: "xs::gYear [0..1]",
        def: "建築物が建築された年。",
      },
      {
        name: "bldg:yearOfDemolition",
        type: "xs::gYear [0..1]",
        def: "建築物が解体された年。",
      },
    ]

    building_gen = [
      {
        name: "bldg:lod0RoofEdge",
        type: "gml:MultiSurface [0..1]",
      },
      {
        name: "bldg:address",
        type: "core:Address [0..*]",
      },
      {
        name: "bldg:boundedBy",
        type: "bldg:_BoundarySurface [0..*]",
      },
      {
        name: "bldg:lod2Solid",
        type: "gml:_Solid [0..1]",
      },
      {
        name: "bldg:lod4Solid",
        type: "gml:_Solid [0..1]",
      },
      {
        name: "bldg:lod1Solid",
        type: "gml:_Solid [0..1]",
      },
      {
        name: "bldg:lod3Solid",
        type: "gml:_Solid [0..1]",
      },
      {
        name: "bldg:bldg::lod2MultiSurface",
        type: "gml:MultiSurface [0..1]",
      },
      {
        name: "bldg:lod0FootPrint",
        type: "gml:MultiSurface [0..1]",
      },
      {
        name: "bldg:lod4MultiSurface",
        type: "gml:MultiSurface [0..1]",
      },
      {
        name: "bldg:bldg::lod3MultiSurface",
        type: "gml:MultiSurface [0..1]",
      },
      {
        name: "uro:bldgDmAttribute",
        type: "uro:DmAttribute [0..*]",
      },
      {
        name: "uro:bldgDataQualityAttribute",
        type: "uro:DataQualityAttribute [0..1]",
      },
      {
        name: "uro:largeCustomerFacilityAttribute",
        type: "uro:LargeCustomerFacilityAttribute [0..*]",
      },
      {
        name: "bldg:consistsOfBuildingPart",
        type: "bldg:BuildingPart [0..*]",
      },
      {
        name: "uro:bldgDisasterRiskAttribute",
        type: "uro:DisasterRiskAttribute [0..*]",
      },
      {
        name: "uro:ifcBuildingAttribute",
        type: "uro:IfcAttribute [0..*]",
      },
      {
        name: "uro:bldgFacilityAttribute",
        type: "uro:FacilityAttribute [0..*]",
      },
      {
        name: "uro:bldgFacilityIdAttribute",
        type: "uro:FacilityIdAttribute [0..1]",
      },
      {
        name: "uro:bldgRealEstateIDAttribute",
        type: "uro:RealEstateIDAttribute [0..1]",
      },
      {
        name: "bldg:outerBuildingInstallation",
        type: "bldg:BuildingInstallation [0..*]",
      },
      {
        name: "uro:bldgUsecaseAttribute",
        type: "uro:BuildingUsecaseAttribute [0..1]",
      },
      {
        name: "uro:bldgKeyValuePairAttribute",
        type: "uro:KeyValuePairAttribute [0..*]",
      },
      {
        name: "uro:buildingDetailAttribute",
        type: "uro:BuildingDetailAttribute [0..*]",
      },
      {
        name: "bldg:interiorRoom",
        type: "bldg:Room [0..*]",
      },
      {
        name: "uro:indoorBuildingAttribute",
        type: "uro:IndoorAttribute [0..*]",
      },
      {
        name: "uro:buildingIDAttribute",
        type: "uro:BuildingIDAttribute [1..1]",
      },
      {
        name: "uro:bldgFacilityTypeAttribute",
        type: "uro:FacilityTypeAttribute [0..*]",
      },
      {
        name: "bldg:interiorBuildingInstallation",
        type: "bldg:IntBuildingInstallation [0..*]",
      },
    ]

    building_furniture_inherited_properties = [
      {
        name: "gml:boundedBy",
        type: "gml::Envelope [0..1]",
        def: "建築物の範囲及び適用される空間参照系。",
      },
      {
        name: "gml:description",
        type: "gml::StringOrRefType [0..1]",
      },
      {
        name: "gml:name",
        type: "gml::CodeType [0..1]",
      },
      {
        name: "core:creationDate",
        type: "xs::date [0..1]",
        def: "データが作成された日。運用上必須とする。",
      },
      {
        name: "core:relativeToTerrain",
        type: "core::RelativeToTerrainType [0..1]",
        def: "建築物と地表面との相対的な位置関係。",
      },
      {
        name: "core:relativeToWater",
        type: "core::RelativeToWaterType [0..1]",
        def: "建築物と水面との相対的な位置関係。",
      },
      {
        name: "core:terminationDate",
        type: "xs::date [0..1]",
        def: "データが削除された日。",
      },
    ]
    building_installation_inherited_properties =
      building_furniture_inherited_properties

    building_furniture_gen = [
      {
        name: "core:core::外部参照",
        type: "core:外部参照 [0..*]",
      },
      {
        name: "gen:_genericAttribute",
        type: "gen:_genericAttribute [0..*]",
      },
    ]
    building_installation_gen = building_furniture_gen

    door_inherited_properties = [
      {
        name: "gml:description",
        type: "gml::StringOrRefType [0..1]",
        def: "土地利用の概要。",
      },
      {
        name: "gml:name",
        type: "gml::CodeType [0..1]",
        def: "",
      },
      {
        name: "gml:boundedBy",
        type: "gml::Envelope [0..1]",
        def: "建築物の範囲及び適用される空間参照系。",
      },
      {
        name: "core:creationDate",
        type: "xs::date [0..1]",
        def: "データが作成された日。運用上必須とする。",
      },
      {
        name: "core:terminationDate",
        type: "xs::date [0..1]",
        def: "データが削除された日。",
      },
      {
        name: "core:relativeToTerrain",
        type: "core::RelativeToTerrainType [0..1]",
        def: "建築物と地表面との相対的な位置関係。",
      },
      {
        name: "core:relativeToWater",
        type: "core::RelativeToWaterType [0..1]",
        def: "建築物と水面との相対的な位置関係。",
      },
    ]

    building_headers = [
      "Inherited Properties",
      "Self-defined Properties",
      "Properties Inherited from Association",
      "Properties Defined in Association",
      "Property Name",
      "Property Type and Multiplicity",
      "Definition",
    ]

    building_headers_with_guidance = building_headers.dup
    building_headers_with_guidance.append("Used", "Guidance")

    subject(:output) { metanorma_process(input) }

    context "specify xmi file by path" do
      context "with built-in templates" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            Building

            lutaml_klass_table::#{example_file}[name="Building"]

            BuildingFurniture

            lutaml_klass_table::#{example_file}[name="BuildingFurniture"]

            BuildingInstallation

            lutaml_klass_table::#{example_file}[name="BuildingInstallation"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render default table headers" do
          include_examples "should contain properties related headers",
                           building_headers
        end

        context "render Building table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_gen
          end
        end

        context "render BuildingFurniture table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_furniture_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_furniture_gen
          end
        end

        context "render BuildingInstallation table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_installation_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_installation_gen
          end
        end
      end

      context "with user-specific templates" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            lutaml_klass_table::#{example_file}[name="Building",template="spec/fixtures/lutaml/liquid_templates/_klass_table.liquid"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render inherited properties" do
          include_examples "should contain name, type, definition",
                           building_inherited_properties
        end

        context "should render inherited properties from generalization" do
          include_examples "should contain name, type, definition",
                           building_gen
        end

        context "should render table headers" do
          headers = %w[
            継承する属性
            自身に定義された属性
            継承する関連役割
            自身に定義された関連役割
            関連役割名
            関連役割の型及び多重度
            定義
          ]
          include_examples "should contain properties related headers", headers
        end
      end

      context "with user-specific templates and guidance" do
        let(:example_file) do
          fixtures_path("plateau_all_packages_export.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            lutaml_klass_table::#{example_file}[name="Building",template="spec/fixtures/lutaml/liquid_templates_guidance/_klass_table.liquid",guidance="spec/fixtures/lutaml/guidance/guidance.yaml"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render inherited properties" do
          include_examples "should contain name, type, definition",
                           building_inherited_properties
        end

        context "should render inherited properties from generalization" do
          include_examples "should contain name, type, definition",
                           building_gen
        end

        context "should render table headers" do
          include_examples "should contain properties related headers",
                           building_headers_with_guidance
        end

        include_examples "should contain Used and Guidance"
      end

      context "with name and package options" do
        let(:example_file) do
          fixtures_path("plateau_all_packages_export.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            lutaml_klass_table::#{example_file}[package="tun",name="Door"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render inherited properties" do
          include_examples "should contain name, type, definition",
                           door_inherited_properties
        end

        context "should render default table headers" do
          include_examples "should contain properties related headers",
                           building_headers
        end
      end

      context "with relative path option" do
        let(:example_file) do
          fixtures_path("plateau_all_packages_export.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            lutaml_klass_table::#{example_file}[path="tun::Door"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render inherited properties" do
          include_examples "should contain name, type, definition",
                           door_inherited_properties
        end

        context "should render default table headers" do
          include_examples "should contain properties related headers",
                           building_headers
        end
      end

      context "with absolute path option" do
        let(:example_file) do
          fixtures_path("plateau_all_packages_export.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets

            lutaml_klass_table::#{example_file}[path="::EA_Model::Conceptual Models::CityGML2.0::tun::Door"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render inherited properties" do
          include_examples "should contain name, type, definition",
                           door_inherited_properties
        end

        context "should render default table headers" do
          include_examples "should contain properties related headers",
                           building_headers
        end
      end
    end

    context "specify xmi file by index" do
      context "with built-in templates" do
        let(:example_file) do
          fixtures_path("20240822_all_package_export_plus_new_tc211_gml.xmi")
        end
        let(:input) do
          <<~TEXT
            = Document title
            Author
            :nodoc:
            :novalid:
            :no-isobib:
            :imagesdir: spec/assets
            :lutaml-xmi-index:first-xmi-index;#{example_file}

            Building

            lutaml_klass_table::[index="first-xmi-index",name="Building"]

            BuildingFurniture

            lutaml_klass_table::[index="first-xmi-index",name="BuildingFurniture"]

            BuildingInstallation

            lutaml_klass_table::[index="first-xmi-index",name="BuildingInstallation"]
          TEXT
        end

        it "should render table" do
          expect(output).to have_tag("table") do
            with_tag "colgroup"
            with_tag "tbody"
          end
        end

        context "should render default table headers" do
          include_examples "should contain properties related headers",
                           building_headers
        end

        context "render Building table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_gen
          end
        end

        context "render BuildingFurniture table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_furniture_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_furniture_gen
          end
        end

        context "render BuildingInstallation table" do
          context "should render inherited properties" do
            include_examples "should contain name, type, definition",
                             building_installation_inherited_properties
          end

          context "should render inherited properties from generalization" do
            include_examples "should contain name, type, definition",
                             building_installation_gen
          end
        end
      end
    end
  end
end
