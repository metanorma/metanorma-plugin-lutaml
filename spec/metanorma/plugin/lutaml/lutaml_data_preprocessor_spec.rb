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
  end

  it "renders YAML data instances" do
    yaml_input = input.gsub(
      /#{fixtures_path('lutaml_data/data_widgets.lml')}/,
      fixtures_path("lutaml_data/data_widgets.yaml"),
    ).gsub("store.AllWidgets", "store.Widgets")
    output = convert_to_xml(yaml_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
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
  end

  it "renders JSON data instances" do
    json_input = input.sub(
      fixtures_path("lutaml_data/data_widgets.lml"),
      fixtures_path("lutaml_data/data_widgets.json"),
    ).gsub("store.AllWidgets", "store.Widgets")
    output = convert_to_xml(json_input)
    expect(output).to include("W1: Gear (3.5) [metal heavy ]")
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
end
