# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "yaml"
require "metanorma/plugin/lutaml/utils"

# Per-schema index yamls carry ../..-escaping schema paths (suma writes
# schema_docs/<schema>/schema_<schema>.yaml pointing at
# ../../schemas/<family>/<schema>.exp) and are loaded as
# CWD-relative paths, the way asciidoctor passes them. cleanpath keeps
# the .. segments of such escaping relative paths, so the loader hands
# the figure decoration a schema directory that resolves from no base:
# the decoration bails and every figure macro FATALs with
# "Image not found" (metanorma-plugin-lutaml#377). The loader resolves
# every path to its real absolute location instead.
RSpec.describe Metanorma::Plugin::Lutaml::Utils do
  let(:corpus_root) { Dir.mktmpdir }
  let(:docfile_directory) { File.join(corpus_root, "schema_docs", "gizmo") }
  let(:schema_directory) do
    File.join(corpus_root, "schemas", "resources", "gizmo_schema")
  end
  let(:schema_file) { File.join(schema_directory, "gizmo_schema.exp") }
  # CWD-relative, as the document render passes it: the compile runs
  # from the corpus root, not from the index's directory.
  let(:relative_index_path) do
    File.join("schema_docs", "gizmo", "schema_gizmo.yaml")
  end
  let(:index_yaml) do
    { "schemas" => {
      "gizmo_schema" => {
        "path" => "../../schemas/resources/gizmo_schema/gizmo_schema.exp",
      },
    } }
  end
  let(:repository) do
    Dir.chdir(corpus_root) do
      described_class.load_express_from_index(nil, relative_index_path)
    end
  end

  before do
    FileUtils.mkdir_p(docfile_directory)
    FileUtils.mkdir_p(File.join(schema_directory, "images"))
    File.write(File.join(schema_directory, "images", "gizmo_schemaexpg1.svg"),
               "<svg/>")
    File.write(schema_file, <<~EXP)
      SCHEMA gizmo_schema;
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      END_SCHEMA;
    EXP
    File.write(File.join(docfile_directory, "schema_gizmo.yaml"),
               index_yaml.to_yaml)
  end

  it "resolves escaping schema paths to their real absolute location" do
    expect(repository.schemas.size).to eq(1)
    expect(File.realpath(repository.schemas.first.file))
      .to eq(File.realpath(schema_file))
    expect(File.exist?(repository.schemas.first.file)).to be(true)
  end
end
