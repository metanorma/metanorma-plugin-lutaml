require "spec_helper"
require "metanorma/plugin/lutaml/json2_text_preprocessor"

RSpec.describe Metanorma::Plugin::Lutaml::Json2TextPreprocessor do
  it_behaves_like "structured data 2 text preprocessor" do
    let(:extension) { "json" }
    def transform_to_type(data)
      data.to_json
    end
  end
end
