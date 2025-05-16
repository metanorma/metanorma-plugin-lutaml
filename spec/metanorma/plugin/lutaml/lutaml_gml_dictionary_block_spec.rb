require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlock do
  describe "#process" do
    subject(:output) { strip_guid(metanorma_convert(input)) }

    context "with block template" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_gml_dictionary,"spec/fixtures/lutaml/Building_class.xml",context=dict]
          --
          {% capture link %}https://www.geospatial.jp/iur/codelists/3.1/{{ dict.file_name }}{% endcapture %}

          [cols="3a,22a"]
          |===
          | ファイル名 | {{ dict.file_name }}

          h| ファイルURL | {{ link }}
          h| コード h| 説明
          {% for entry in dict.dictionary_entry %}
          | {{ entry.name }} | {{ entry.description }}
          {% endfor %}
          |===

          [.source]
          <<gsi_map_level_dps>>
          --

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

      it "should contain source" do
        expect(subject).to have_tag("origin[bibitemid='gsi_map_level_dps']")
      end
    end

    context "with block template and grouped by first letter" do
      let(:input) do
        <<~TEXT
          = Document title
          Author
          :nodoc:
          :novalid:
          :no-isobib:
          :imagesdir: spec/assets

          [lutaml_gml_dictionary,"spec/fixtures/lutaml/TrafficArea_function.xml",context=dict]
          --
          {% capture link %}https://www.geospatial.jp/iur/codelists/3.1/{{ dict.file_name }}{% endcapture %}

          {% assign count = 0 %}
          {% assign col_count = "" %}
          {% assign first_letter = dict.dictionary_entry.first.name | slice: 0 %}

          {% for entry in dict.dictionary_entry %}
            {% assign entry_first_letter = entry.name | slice: 0 %}
            {% if first_letter == entry_first_letter %}
              {% assign count = count | plus: 1 %}
            {% else %}
              {% assign first_letter = entry_first_letter %}
              {% if col_count == "" %}
                {% assign col_count = col_count | append: count %}
              {% else %}
                {% assign col_count = col_count | append: "," | append: count %}
              {% endif %}
              {% assign count = 1 %}
            {% endif %}
          {% endfor %}

          {% if col_count == "" %}
            {% assign col_count = col_count | append: count %}
          {% else %}
            {% assign col_count = col_count | append: "," | append: count %}
          {% endif %}

          {% assign col_count = col_count | split: "," %}

          [cols="3a,3a,3a,3a,13a"]
          |===
          | ファイル名 4+| {{ dict.file_name }}

          h| ファイルURL 4+| {{ link }}
          2+^h| 大分類 2+^h| 小分類 .2+^h| 定義
          ^h| コード ^h| 説明 ^h| コード ^h| 説明
          {% assign col_count_index = -1 %}
          {% for entry in dict.dictionary_entry %}
          {% assign entry_name_end = entry.name | slice: 1, 3 %}
          {% if entry_name_end == "000" %}
          {% assign col_count_index = col_count_index | plus: 1 %}
          {% assign row_span = col_count[col_count_index] %}
          .{{ row_span }}+| {{ entry.name }} .{{ row_span }}+| {{ entry.description }} 2+| |
          {% else %}
          | {{ entry.name }} | {{ entry.description }} |
          {% endif %}
          {% endfor %}
          |===

          [.source]
          <<gsi_map_level_dps>>
          --

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
          TrafficArea_function.xml
          ファイルURL
          コード
          説明
          大分類
          小分類
          定義
        ).each do |header|
          it { is_expected.to have_tag("th", /#{header}/) }
        end
      end

      it "should render categories in table" do
        [
          { tag: "td[rowspan='8']", text: "1000" },
          { tag: "td[rowspan='8']", text: "車道部" },
          { tag: "td[rowspan='4']", text: "2000" },
          { tag: "td[rowspan='4']", text: "歩道部" },
          { tag: "td[rowspan='6']", text: "8000" },
          { tag: "td[rowspan='6']", text: "軌道中心線" },
        ].each do |i|
          expect(subject).to have_tag(i[:tag]) do
            with_tag "p", text: i[:text]
          end
        end
      end

      context "should render sub items in table" do
        %w(
          1010
          車線
          1020
          車道交差部
          1130
          副道
          2010
          自転車歩行者道
          2020
          歩道
          6000
          自転車駐車場
          7000
          自動車駐車場
          8100
          軌道
          8110
          軌きょう
          8120
          道床
        ).each do |content|
          it { is_expected.to have_tag("p", /#{content}/) }
        end
      end

      it "should contain link" do
        expect(subject).to have_tag("link[target='https://www.geospatial.jp/iur/codelists/3.1/TrafficArea_function.xml']")
      end

      it "should contain source" do
        expect(subject).to have_tag("origin[bibitemid='gsi_map_level_dps']")
      end
    end
  end
end
