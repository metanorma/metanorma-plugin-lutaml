require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::LutamlDataPreprocessor do
  def convert_to_xml(input)
    xml_string_content(metanorma_convert(input))
  end

  let(:template) do
    <<~LIQUID
      {% for widget in store.AllWidgets.widgets %}
      {{ widget.id }}: {{ widget.name }} ({{ widget.mass }}) [{% for tag in widget.tags %}{{ tag }} {% endfor %}]
      {% endfor %}
    LIQUID
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

      [lutaml_data,#{fixtures_path('lutaml_data/widget_models.lml')},#{fixtures_path('lutaml_data/data_widgets.lml')},store]
      ----
      #{template}
      ----
    TEXT
  end

  it "renders LML data instances through the Liquid template" do
    output = convert_to_xml(input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
    expect(output).to include("W2: Spring () []")
  end

  it "renders YAML data instances" do
    yaml_input = input.gsub(
      /#{fixtures_path('lutaml_data/data_widgets.lml')}/,
      fixtures_path("lutaml_data/data_widgets.yaml"),
    ).gsub("store.AllWidgets", "store.Widgets")
    output = convert_to_xml(yaml_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
    expect(output).to include("W2: Spring () []")
  end

  it "renders definitions and instances from the same LML file" do
    same_file_input = input.sub(
      "#{fixtures_path('lutaml_data/widget_models.lml')}," \
      "#{fixtures_path('lutaml_data/data_widgets.lml')}",
      fixtures_path("lutaml_data/widgets.lml"),
    )
    output = convert_to_xml(same_file_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
    expect(output).to include("W2: Spring () []")
  end

  it "renders JSON data instances" do
    json_input = input.sub(
      fixtures_path("lutaml_data/data_widgets.lml"),
      fixtures_path("lutaml_data/data_widgets.json"),
    ).gsub("store.AllWidgets", "store.Widgets")
    output = convert_to_xml(json_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
    expect(output).to include("W2: Spring () []")
  end

  it "uses options include_path for Liquid includes" do
    paths = [fixtures_path("lutaml_data"),
             fixtures_path("lutaml_data/templates")]
    options = { "include_path" => paths.join(",") }
    options_input = input.sub(",store]", ",store,options=#{options.to_json}]")
      .sub(template, "{% include 'heading' %}\n")
    expect(convert_to_xml(options_input))
      .to include("Widgets loaded through the configured include path.")
  end

  it "logs and raises on malformed JSON options" do
    bad_input = input.sub(",store]", ",store,options={bad}]")
    allow(Metanorma::Util).to receive(:log)
    expect { metanorma_convert(bad_input) }
      .to raise_error(JSON::ParserError)
    expect(Metanorma::Util).to have_received(:log)
      .with(/Failed to parse LutaML data block: .*bad/, :error)
  end

  it "accepts a trailing comma after JSON options" do
    path = fixtures_path("lutaml_data/templates")
    options_input = input.sub(",store]",
                              ",store,options={\"include_path\":\"#{path}\"},]")
      .sub(template, "{% include 'heading' %}\n")
    expect(convert_to_xml(options_input))
      .to include("Widgets loaded through the configured include path.")
  end

  it "preserves inline include_path options" do
    path = fixtures_path("lutaml_data/templates")
    options_input = input.sub(",store]", ",store,include_path=#{path}]")
      .sub(template, "{% include 'heading' %}\n")
    expect(convert_to_xml(options_input))
      .to include("Widgets loaded through the configured include path.")
  end

  it "exposes instances under the default context name" do
    default_context_input = input.gsub(",store]", "]").gsub(
      "store.AllWidgets",
      "lutaml_data.AllWidgets",
    )
    output = convert_to_xml(default_context_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
  end

  it "raises an error when the definition file is missing" do
    missing_input = input.gsub(
      /#{fixtures_path('lutaml_data/widget_models.lml')}/,
      fixtures_path("lutaml_data/missing_models.lml"),
    )
    expect { metanorma_convert(missing_input) }
      .to raise_error(StandardError, /missing_models/)
  end

  context "with S-102 style validation checks (issue #178 example)" do
    let(:s102_input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_data,#{fixtures_path('lutaml_data/s102_models.lml')},#{fixtures_path('lutaml_data/s102_checks.lml')},lml]
        ----
        {% for check in lml.S158Checks.checks %}
        S-102 Validation Check `{{ check.dev_id }}`

        classification: {{ check.classification.description }}

        check message: {{ check.check_message }}

        check solution: [{{ check.check_solution }}]

        {% endfor %}
        ----
      TEXT
    end

    it "renders every check with enum descriptions and optional attributes" do
      expect(convert_to_xml(s102_input)).to include(
        "S-102 Validation Check <tt>S102_Dev1001</tt>",
        "classification: Critical Error",
        "check message: No feature information group",
        "check solution: [Add feature information group]",
        "S-102 Validation Check <tt>S102_Dev1002</tt>",
        "classification: Warning",
        "check solution: []",
      )
    end
  end

  describe "XML data sources" do
    let(:schema_path) { fixtures_path("xml_data/macro/catalog.xsd") }
    let(:xml_path) { fixtures_path("xml_data/macro/catalog.xml") }
    let(:xml_template) do
      <<~LIQUID
        {% for feature in fc.Catalog.feature %}
        == Feature {{ feature.code }}: {{ feature.name }}

        Values: {% for value in feature.enumerant %}{{ value }} {% endfor %}

        {% endfor %}
      LIQUID
    end
    let(:xml_input) do
      input.sub(
        "#{fixtures_path('lutaml_data/widget_models.lml')}," \
        "#{fixtures_path('lutaml_data/data_widgets.lml')},store",
        "#{schema_path},#{xml_path},fc",
      ).sub(template, xml_template)
    end

    it "renders clauses and nested values from every typed XML feature" do
      output = convert_to_xml(xml_input)
      expect(output).to include("Feature 1: Depth area", "Values: Shallow Deep",
                                "Feature 2: Coastline", "Values: Natural")
      expect(Nokogiri::XML(output).xpath("//*[local-name()='clause']")
        .map { |clause| clause.at("title")&.text })
        .to include("Feature 1: Depth area", "Feature 2: Coastline")
    end

    it "uses the default context when only the two file paths are supplied" do
      default_input = xml_input.sub(",fc]", "]")
        .gsub("fc.Catalog", "lutaml_data.Catalog")
      expect(convert_to_xml(default_input))
        .to include("Feature 1: Depth area", "Feature 2: Coastline")
    end

    it "passes the explicit schema location to the XML loader" do
      location = fixtures_path("xml_data/macro")
      loader = Metanorma::Plugin::Lutaml::XmlDataLoader.new
      allow(Metanorma::Plugin::Lutaml::XmlDataLoader).to receive(:new)
        .and_return(loader)
      allow(loader).to receive(:load)
        .with(schema_path, xml_path, location: location)
        .and_call_original
      located_input = xml_input.sub(",fc]", ",fc,location=#{location}]")
      expect(convert_to_xml(located_input)).to include("Feature 1: Depth area")
      expect(loader).to have_received(:load)
        .with(schema_path, xml_path, location: location)
    end

    ["inline", "JSON"].each do |style|
      it "preserves #{style} include options for XML templates" do
        path = fixtures_path("xml_data/macro")
        json_options = { "include_path" => path }.to_json
        options = if style == "inline"
                    "include_path=#{path}"
                  else
                    "options=#{json_options}"
                  end
        include_template = <<~LIQUID
          {% for feature in fc.Catalog.feature %}
          {% include 'feature' %}

          {% endfor %}
        LIQUID
        include_input = xml_input.sub(",fc]", ",fc,#{options}]")
          .sub(xml_template, include_template)
        expect(convert_to_xml(include_input))
          .to include("Feature 1: Depth area [Shallow Deep ]",
                      "Feature 2: Coastline [Natural ]")
      end
    end

    it "reports a missing XML instance using the existing path error" do
      missing_input = xml_input.sub(xml_path,
                                    fixtures_path("xml_data/macro/missing.xml"))
      expect { convert_to_xml(missing_input) }
        .to raise_error(StandardError, /missing\.xml/)
    end

    [nil, "data_widgets.yaml", "data_widgets.json",
     "data_widgets.lml"].each do |file|
      it "rejects XSD definitions with #{file || 'no instance file'}" do
        replacement = file ? ",#{fixtures_path("lutaml_data/#{file}")}" : ""
        bad_input = xml_input.sub(",#{xml_path}", replacement)
        allow(Metanorma::Util).to receive(:log)
        allow(Lutaml::Lml::ModelCompiler).to receive(:new).and_call_original
        expect { convert_to_xml(bad_input) }
          .to raise_error(StandardError, /XSD definitions require an XML/)
        expect(Lutaml::Lml::ModelCompiler).not_to have_received(:new)
        expect(Metanorma::Util).to have_received(:log)
          .with(/Failed to parse LutaML data block: XSD definitions require/,
                :error)
      end
    end

    it "rejects XML instances paired with LML definitions before compiling" do
      bad_input = xml_input.sub(schema_path,
                                fixtures_path("lutaml_data/widget_models.lml"))
      allow(Lutaml::Lml::ModelCompiler).to receive(:new).and_call_original
      expect { convert_to_xml(bad_input) }
        .to raise_error(StandardError, /XML instances require an XSD/)
      expect(Lutaml::Lml::ModelCompiler).not_to have_received(:new)
    end
  end

  describe "provider sources" do
    let(:provider_input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_data,provider:sample_registers.edition,edition,options={"arguments":{"register":"demo","as_of":1170}}]
        ----
        Register {{ edition.register }} as of issue {{ edition.as_of_issue }}

        {% for row in edition.rows %}
        Row {{ forloop.index }}: {{ row.key }} {{ row.name }}
        {% endfor %}
        ----
      TEXT
    end

    around { |example| with_fixture_provider_load_path { example.run } }

    it "renders a provider query's lutaml-model objects in provider order" do
      output = convert_to_xml(provider_input)
      expect(output).to include("Register demo as of issue 1170")
      expect(output.index("Row 1: 02 Beta"))
        .to be < output.index("Row 2: 01 Alpha")
    end

    it "fails the block for a query the provider does not declare" do
      input = provider_input.sub("sample_registers.edition",
                                 "sample_registers.unlisted_query")
      expect { convert_to_xml(input) }
        .to raise_error(/has no query `unlisted_query`/)
    end
  end
  describe "XML Schema definitions with XML instance documents" do
    let(:xsd_template) do
      <<~LIQUID
        {% for widget in store.CTWidgets.widget %}
        {{ widget.id }}: {{ widget.name }} ({{ widget.mass }}) [{% for tag in widget.tag %}{{ tag }} {% endfor %}]
        {% endfor %}
      LIQUID
    end

    let(:xsd_input) do
      <<~TEXT
        = Document title
        Author
        :docfile: test.adoc
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        [lutaml_data,#{fixtures_path('lutaml_data/catalogue.xsd')},#{fixtures_path('lutaml_data/catalogue.xml')},store]
        ----
        #{xsd_template}
        ----
      TEXT
    end

    it "parses the instance against the schema and renders it" do
      output = convert_to_xml(xsd_input)
      expect(output).to include("W1: Gear (3.5) [metal heavy ]")
      expect(output).to include("W2: Spring () []")
      expect(output).to include("W2: Spring () []")
    end

    it "fails loudly when the instance file is missing" do
      missing = xsd_input.gsub(
        fixtures_path("lutaml_data/catalogue.xml"),
        fixtures_path("lutaml_data/absent.xml"),
      )
      expect { convert_to_xml(missing) }
        .to raise_error(/absent.xml|Unable to load/)
    end
  end

end
