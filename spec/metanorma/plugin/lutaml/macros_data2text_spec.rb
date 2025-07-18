require "spec_helper"
require "metanorma/plugin/lutaml/data2_text_preprocessor"

RSpec.describe Metanorma::Plugin::Lutaml::Data2TextPreprocessor do
  context "Multiple contexts (without any options)" do
    let(:example_json_file) { "example.json" }
    let(:example_yaml_file) { "example2.yaml" }
    let(:example_yaml_file3) { "example3.yaml" }

    before do
      File.open(example_json_file, "w") do |n|
        n.puts(example_content.to_json)
      end
      File.open(example_yaml_file, "w") do |n|
        n.puts(example_content2.to_yaml)
      end
      File.open(example_yaml_file3, "w") do |n|
        n.puts(example_content3.to_yaml)
      end
    end

    after do
      FileUtils.rm_rf(example_json_file)
      FileUtils.rm_rf(example_yaml_file)
      FileUtils.rm_rf(example_yaml_file3)
    end

    let(:example_content) do
      { "name" => "Lorem ipsum", "desc" => "dolor sit amet" }
    end
    let(:example_content2) do
      { "name" => "spaghetti", "desc" => "wheat noodles of 9mm diameter" }
    end
    let(:example_content3) do
      { "color" => "red", "shape" => "circle" }
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

        [data2text,item1=#{example_json_file},item2=#{example_yaml_file},item3=#{example_yaml_file3}]
        ----
        == {{item1.name}}

        {{item1.desc}}

        == {{item2.name}}

        {{item2.desc}}

        == {{item3.color}}

        {{item3.shape}}
        ----
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">Lorem ipsum</title>
            <p id="_">dolor sit amet</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">spaghetti</title>
            <p id="_">wheat noodles of 9mm diameter</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">red</title>
            <p id="_">circle</p>
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

  context "Multiple contexts with include_path option" do
    let(:example_json_file) { "example.json" }
    let(:example_yaml_file) { "example2.yaml" }
    let(:example_yaml_file3) { "example3.yaml" }

    before do
      File.open(example_json_file, "w") do |n|
        n.puts(example_content.to_json)
      end
      File.open(example_yaml_file, "w") do |n|
        n.puts(example_content2.to_yaml)
      end
      File.open(example_yaml_file3, "w") do |n|
        n.puts(example_content3.to_yaml)
      end
    end

    after do
      FileUtils.rm_rf(example_json_file)
      FileUtils.rm_rf(example_yaml_file)
      FileUtils.rm_rf(example_yaml_file3)
    end

    let(:example_content) do
      { "name" => "Lorem ipsum", "desc" => "dolor sit amet" }
    end
    let(:example_content2) do
      { "name" => "spaghetti", "desc" => "wheat noodles of 9mm diameter" }
    end
    let(:example_content3) do
      { "color" => "red", "shape" => "circle" }
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

        [data2text,item1=#{example_json_file},item2=#{example_yaml_file},item3=#{example_yaml_file3},include_path=spec/fixtures/lutaml/datastruct]
        ----
        {% render 'test_include_path' item1: item1, item2: item2 %}

        == {{ item3.color }}

        {{ item3.shape }}
        ----
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">Lorem ipsum</title>
            <p id="_">dolor sit amet</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">spaghetti</title>
            <p id="_">wheat noodles of 9mm diameter</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">red</title>
            <p id="_">circle</p>
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

  context "Multiple contexts with template option" do
    let(:example_json_file) { "example.json" }
    let(:example_yaml_file) { "example2.yaml" }
    let(:example_yaml_file3) { "example3.yaml" }

    before do
      File.open(example_json_file, "w") do |n|
        n.puts(example_content.to_json)
      end
      File.open(example_yaml_file, "w") do |n|
        n.puts(example_content2.to_yaml)
      end
      File.open(example_yaml_file3, "w") do |n|
        n.puts(example_content3.to_yaml)
      end
    end

    after do
      FileUtils.rm_rf(example_json_file)
      FileUtils.rm_rf(example_yaml_file)
      FileUtils.rm_rf(example_yaml_file3)
    end

    let(:example_content) do
      { "name" => "Lorem ipsum", "desc" => "dolor sit amet" }
    end
    let(:example_content2) do
      { "name" => "spaghetti", "desc" => "wheat noodles of 9mm diameter" }
    end
    let(:example_content3) do
      { "color" => "red", "shape" => "circle" }
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

        [data2text,item1=#{example_json_file},item2=#{example_yaml_file},item3=#{example_yaml_file3},template=spec/fixtures/lutaml/datastruct/_multiple_contexts_template.liquid]
        ----
        ----
      TEXT
    end
    let(:output) do
      <<~TEXT
        #{BLANK_HDR}
        <sections>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">Lorem ipsum</title>
            <p id="_">dolor sit amet</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">spaghetti</title>
            <p id="_">wheat noodles of 9mm diameter</p>
          </clause>
          <clause id="_" inline-header="false" obligation="normative">
            <title id="_">red</title>
            <p id="_">circle</p>
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
