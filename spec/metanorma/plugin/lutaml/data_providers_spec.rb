require "spec_helper"

RSpec.describe Metanorma::Plugin::Lutaml::DataProviders do
  let(:provider_class) do
    Class.new do
      def lutaml_data_queries
        %i[greeting]
      end

      def greeting(name:)
        "hello #{name}"
      end

      def hidden
        "secret"
      end
    end
  end

  before { described_class.register("inline_test") { provider_class.new } }
  after { described_class.unregister("inline_test") }

  it "calls a declared query with keyword arguments from JSON keys" do
    expect(described_class.query("inline_test", "greeting", "name" => "OB"))
      .to eq("hello OB")
  end

  it "refuses a public method the provider does not declare" do
    expect { described_class.query("inline_test", "hidden") }
      .to raise_error(described_class::Error, /has no query `hidden`/)
  end

  it "refuses a name that could escape the discovery directory" do
    expect { described_class.fetch("../inline_test") }
      .to raise_error(described_class::Error, /invalid/)
  end

  it "reports a provider that is neither registered nor discoverable" do
    expect { described_class.fetch("no_such_provider") }
      .to raise_error(described_class::Error, /no LutaML data provider/)
  end

  it "discovers a provider shipped under data_providers/ on the load path" do
    with_fixture_provider_load_path do
      edition = described_class.query("sample_registers", "edition",
                                      "register" => "demo", "as_of" => 7)
      expect([edition.as_of_issue, edition.rows.map(&:key)])
        .to eq([7, %w[02 01]])
    end
  end
end
