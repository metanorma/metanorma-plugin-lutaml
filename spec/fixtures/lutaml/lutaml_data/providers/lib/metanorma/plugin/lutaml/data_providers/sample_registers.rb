# frozen_string_literal: true

# Fixture provider gem file, found through Gem.find_files once its lib
# directory is on the load path. Its classes are compiled from LML.
module SampleRegistersFixture
  class Provider
    MODELS = File.expand_path("../../../../../register_models.lml", __dir__)
    ROWS = [%w[02 Beta], %w[01 Alpha]].freeze

    def initialize
      @classes = Lutaml::Lml::ModelCompiler.new
        .compile(File.new(MODELS, encoding: "UTF-8"))
    end

    def lutaml_data_queries
      %i[edition]
    end

    def edition(register:, as_of:)
      rows = ROWS.map do |key, name|
        @classes.fetch("RegisterRow").new(key: key, name: name)
      end
      @classes.fetch("RegisterEdition")
        .new(register: register, as_of_issue: as_of, rows: rows)
    end

    def unlisted_query
      "must not be reachable from a document"
    end
  end
end

Metanorma::Plugin::Lutaml::DataProviders.register("sample_registers") do
  SampleRegistersFixture::Provider.new
end
