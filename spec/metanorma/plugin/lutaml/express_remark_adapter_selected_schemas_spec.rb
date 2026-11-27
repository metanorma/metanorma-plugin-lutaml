# frozen_string_literal: true

require "spec_helper"
require "expressir"
require "expressir/express/parser"
require "metanorma/plugin/lutaml/express_remark_adapter"
require "metanorma/plugin/lutaml/express_remark_figures"

# A document's lutaml_express block often loads a whole index of schemas
# (`:lutaml-express-index: schemas; ../../schemas-srl.yml;`, 126 schemas)
# and selects the ones it covers with `config_yaml=schemas.yaml`; only the
# selected schemas render (`ordered_schemas`). Decoration stages each
# decorated schema's EXPRESS-G figures into the document's image folder, so
# decorating the whole index copied every figure of every schema there:
# 922 files in documents/<part>/images for a part with one schema.
RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  before { Metanorma::Plugin::Lutaml::ExpressRemarkFigures.apply }

  def path_resolver
    Class.new do
      def system_path(path, base) = File.expand_path(path, base)
    end.new
  end

  def document_class
    Class.new do
      attr_reader :attributes, :path_resolver

      def initialize(attributes, path_resolver)
        @attributes = attributes
        @path_resolver = path_resolver
      end
    end
  end

  let(:corpus_root) { Dir.mktmpdir }
  let(:docfile_directory) { File.join(corpus_root, "documents", "part") }
  let(:document) do
    document_class.new(
      { "docfile" => File.join(docfile_directory, "document.adoc"),
        "imagesdir" => "images" },
      path_resolver,
    )
  end
  let(:images) { File.join(docfile_directory, "images") }
  let(:repository) do
    Expressir::Express::Parser.from_files(
      [schema_file("gizmo_schema"), schema_file("widget_schema", "widget")],
    )
  end

  def schema_file(name, basename = name)
    directory = File.join(corpus_root, "schemas", name)
    FileUtils.mkdir_p(File.join(directory, "images"))
    FileUtils.touch(File.join(directory, "images", "#{name}expg1.svg"))
    file = File.join(directory, "#{basename}.exp")
    File.write(file, <<~EXP)
      SCHEMA #{name};
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      (*"#{name}.__expressg"
      [[#{name}_expg1]]
      [.svgmap]
      ====
      image::images/#{name}expg1.svg[]

      * <<express:#{name}.thing>>; 1
      ====
      *)
      END_SCHEMA;
    EXP
    file
  end

  def decorate(options)
    described_class.for(repository)
      .decorate_remarks({ "document" => document }.merge(options))
  end

  def staged
    Dir.children(images).sort
  end

  it "stages the figures of the selected schemas only" do
    decorate("selected_schemas" => ["gizmo_schema"])

    expect(staged).to eq ["gizmo_schemaexpg1.svg"]
  end

  it "resolves the selected schemas' figures" do
    decorate("selected_schemas" => ["gizmo_schema"])
    gizmo = repository.schemas.find { |s| s.id == "gizmo_schema" }

    expect(gizmo.remark_items.flat_map(&:remarks).join)
      .to include("image::gizmo_schemaexpg1.svg[]")
  end

  it "leaves the schemas outside the selection as written" do
    decorate("selected_schemas" => ["gizmo_schema"])
    widget = repository.schemas.find { |s| s.id == "widget_schema" }

    expect(widget.remark_items.flat_map(&:remarks).join)
      .to include("image::images/widget_schemaexpg1.svg[]")
  end

  it "selects a schema by its file basename too" do
    decorate("selected_schemas" => ["widget"])

    expect(staged).to eq ["widget_schemaexpg1.svg"]
  end

  it "stages every schema's figures when the block selects none" do
    decorate({})

    expect(staged).to eq %w[gizmo_schemaexpg1.svg widget_schemaexpg1.svg]
  end
end
