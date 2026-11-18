# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "expressir"
require "expressir/express/parser"
require "liquid"
require "metanorma/plugin/lutaml/express_remark_adapter"
require "metanorma/plugin/lutaml/express_remark_figures"
require "metanorma/plugin/lutaml/express_schema_listing"

# End-to-end guard for the drop surfaces the remark decoration touches:
# these specs render REAL Liquid templates against a decorated
# repository, the path no other spec in the family exercises. The
# RemarkItemDrop's liquid surface once regressed so that "{{ remark }}"
# printed the drop's class name (metanorma-plugin-lutaml#369) while
# every model-level accessor spec stayed green.
RSpec.describe Metanorma::Plugin::Lutaml::ExpressRemarkAdapter do
  # Applied before the first liquefaction, the way lutaml_preprocessor's
  # update_repo applies them before the first template render: Liquid
  # memoizes a drop class's invokable methods on first render.
  before do
    Metanorma::Plugin::Lutaml::ExpressSchemaListing.apply
    Metanorma::Plugin::Lutaml::ExpressRemarkFigures.apply
  end

  # The schema's imagesdir is its source directory resolved the way the
  # document resolves referenced paths.
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

  let(:diagram_name) { "gizmo_armexpg1.svg" }

  let(:document) do
    document_class.new(
      {
        "docfile" => File.join(docfile_directory, "test.adoc"),
        "imagesdir" => "images",
      },
      path_resolver,
    )
  end

  let(:docfile_directory) { File.join(corpus_root, "documents", "part") }
  let(:corpus_root) { Dir.mktmpdir }
  let(:schema_directory) { File.join(corpus_root, "schemas", "gizmo") }

  let(:schema_file) do
    FileUtils.mkdir_p(schema_directory)
    file = File.join(schema_directory, "gizmo_arm.exp")
    File.write(file, <<~EXP)
      SCHEMA gizmo_arm;
      ENTITY thing;
        name : STRING;
      END_ENTITY;
      (*"gizmo_arm"
      The EXPRESS-G diagram of this schema:
      image::#{diagram_name}[]
      *)
      END_SCHEMA;
    EXP
    FileUtils.touch(File.join(schema_directory, diagram_name))
    file
  end

  let(:repository) { Expressir::Express::Parser.from_file(schema_file) }

  def decorated_drop
    Metanorma::Plugin::Lutaml::ExpressRemarkAdapter.for(repository)
      .decorate_remarks({ "document" => document })

    repository.to_liquid
  end

  def render(template)
    parsed = Liquid::Template.parse(template)
    parsed.assigns["my_context"] = decorated_drop
    parsed.render
  end

  def remark_items_loop
    <<~LIQ
      {% for schema in my_context.schemas %}
      {% for remark in schema.remark_items %}{{ remark }}{% endfor %}
      {% endfor %}
    LIQ
  end

  it "renders the remark text for a bare remark_items loop" do
    output = render(remark_items_loop)

    expect(output).to include("The EXPRESS-G diagram of this schema:")
    expect(output).not_to include("RemarkItemDrop")
  end

  it "renders the staged figure target through the bare loop" do
    output = render(remark_items_loop)

    expect(output).to include("image::#{diagram_name}[]")
    expect(File.file?(File.join(docfile_directory, "images", diagram_name)))
      .to be(true)
  end

  it "renders the remark.remarks drop accessor" do
    output = render(<<~LIQ)
      {% for schema in my_context.schemas %}
      {% for remark in schema.remark_items %}{{ remark.remarks }}{% endfor %}
      {% endfor %}
    LIQ

    expect(output).to include("The EXPRESS-G diagram of this schema:")
    expect(output).to include("image::#{diagram_name}[]")
    expect(output).not_to include("RemarkItemDrop")
  end

  it "renders the schema drop surfaces (id and remarks)" do
    output = render(<<~LIQ)
      {% for schema in my_context.schemas %}{{ schema.id }}{{ schema.remarks }}{% endfor %}
    LIQ

    expect(output).to include("gizmo_arm")
    expect(output).to include("The EXPRESS-G diagram of this schema:")
    expect(output).not_to include("SchemaDrop")
  end
end
