# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "expressir"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  describe "compiled-set artifact index (.exscs)" do
    let(:schemas) do
      {
        "alpha" => <<~EXP,
          SCHEMA alpha;
          ENTITY thing;
            name : STRING;
          END_ENTITY;
          END_SCHEMA;
        EXP
        "beta" => <<~EXP,
          SCHEMA beta;
          USE FROM alpha (thing);
          ENTITY widget;
            part : thing;
          END_ENTITY;
          END_SCHEMA;
        EXP
      }
    end

    let(:artifact_path) { File.join(dir, "set.exscs") }
    let(:index_yaml_path) { File.join(dir, "index.yaml") }

    let(:render_template) do
      <<~LIQUID
        {% for schema in context.schemas %}
        == {{ schema.id }}
        {{ schema.formatted }}
        {% endfor %}
      LIQUID
    end

    let(:artifact_input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :lutaml-express-index: express; #{artifact_path}

        [lutaml_express_liquid,express,context]
        ----
        #{render_template}
        ----
      TEXT
    end

    let(:folder_input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :lutaml-express-index: express; #{index_yaml_path}

        [lutaml_express_liquid,express,context]
        ----
        #{render_template}
        ----
      TEXT
    end

    around do |example|
      @kept_dir = Dir.mktmpdir("mpl-exscs")
      example.run
    end

    let(:dir) { @kept_dir }

    before do
      schemas.each_with_index do |(name, body), i|
        File.write(File.join(dir, "s#{i}.exp"), body)
      end
      paths = schemas.keys.each_with_index.map do |_, i|
        File.join(dir, "s#{i}.exp")
      end
      Expressir::Express::Parser.from_files(paths, compiled_set: artifact_path)
      File.write(index_yaml_path, <<~YAML)
        schemas:
          alpha:
            path: s0.exp
          beta:
            path: s1.exp
      YAML
    end

    def rendered_sections(input)
      body = metanorma_convert(input)
      body.scan(/<title[^>]*>([^<]+)<\/title>|<body>(.*?)<\/body>/m)
        .map { |title, code| title || code }.compact
    end

    it "renders the same schemas as the folder path" do
      expect(rendered_sections(artifact_input))
        .to eq(rendered_sections(folder_input))
    end

    it "renders every schema of the set" do
      body = metanorma_convert(artifact_input)
      aggregate_failures do
        expect(body).to include("alpha")
        expect(body).to include("beta")
        expect(body).to include("ENTITY widget;")
      end
    end
  end
end
