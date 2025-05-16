require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlockMacro do
  describe "#process" do
    subject(:output) { strip_guid(metanorma_convert(input)) }

    context "with template" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          lutaml_gml_dictionary::spec/fixtures/lutaml/Building_class.xml[template="spec/fixtures/lutaml/liquid_templates/_custom_gml_dictionary.liquid",context=dict]
        TEXT
      end

      it "should render table" do
        expect(subject).to have_tag("table") do
          with_tag "colgroup"
          with_tag "thead"
          with_tag "tbody"
        end
      end

      context "should render table headers" do
        %w(
          ファイル名
          Building_class.xml
          ファイルURL
          コード
          説明
        ).each do |header|
          it { is_expected.to have_tag("th", /#{header}/) }
        end
      end

      context "should render table content" do
        %w(
          3001
          普通建物
          3002
          堅ろう建物
          3003
          普通無壁舎
          3004
          堅ろう無壁舎
          3000
          分類しない建物
        ).each do |content|
          it { is_expected.to have_tag("p", /#{content}/) }
        end
      end

      it "should contain link" do
        expect(subject).to have_tag("link[target='https://www.geospatial.jp/iur/codelists/3.1/Building_class.xml']")
      end
    end
  end
end
