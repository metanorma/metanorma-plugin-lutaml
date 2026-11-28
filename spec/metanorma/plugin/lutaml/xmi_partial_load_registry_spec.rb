# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe Metanorma::Plugin::Lutaml::XmiPartialLoadRegistry do
  let(:large_xmi) { fixtures_path("plateau_all_packages_export.xmi") }
  let(:small_xmi) { fixtures_path("parentless_union.xmi") }

  # The partial-load registry is process-global state the preprocessor
  # prepares per document; the examples assert the state left behind by
  # their own conversion.
  after { described_class.reset! }

  # Asciidoctor's logger is swapped for a buffered one around the
  # conversion, so the whole-load fallback warnings are observable.
  def convert_with_logger(input, extra_attributes: [])
    original = Asciidoctor::LoggerManager.logger
    buffer = StringIO.new
    Asciidoctor::LoggerManager.logger = Logger.new(buffer)
    output = Asciidoctor.convert(
      input,
      backend: :standoc, header_footer: true, agree_to_terms: true,
      to_file: false, safe: :safe,
      attributes: ["nodoc", "stem", "xrefstyle=short",
                   "docfile=test.adoc", "output_dir="] + extra_attributes
    )
    [output, buffer.string]
  ensure
    Asciidoctor::LoggerManager.logger = original
  end

  context "with no lutaml-ea-xmi-load attribute" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        lutaml_klass_table::#{large_xmi}[name="Building"]
      TEXT
    end

    it "engages the partial registry by default and renders the table" do
      output, log = convert_with_logger(input)

      expect(output).to have_tag("table")
      expect(described_class.slice?(large_xmi)).to be(true)

      path, name, slice = described_class.rewrite(large_xmi, "Building")
      expect([path, name]).to eq([large_xmi, "Building"])
      expect(slice).to eq([large_xmi, "_"])
      expect(described_class.slice_string(slice)).to be_a(String)
      expect(log).not_to include("whole-load")
    end
  end

  context "with :lutaml-ea-xmi-load: whole in the source" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :lutaml-ea-xmi-load: whole
        :imagesdir: spec/assets

        lutaml_klass_table::#{large_xmi}[name="Building"]
      TEXT
    end

    it "opts out of the partial registry and renders the table" do
      output, log = convert_with_logger(input)

      expect(output).to have_tag("table")
      expect(described_class.slice?(large_xmi)).to be(false)
      expect(described_class.rewrite(large_xmi, "Building"))
        .to eq([large_xmi, "Building", nil])
      expect(log).not_to include("whole-load")
    end
  end

  context "with the lutaml-ea-xmi-load attribute whole through the API" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        lutaml_klass_table::#{large_xmi}[name="Building"]
      TEXT
    end

    it "opts out of the partial registry" do
      _output, log = convert_with_logger(
        input, extra_attributes: ["lutaml-ea-xmi-load=whole"]
      )

      expect(described_class.slice?(large_xmi)).to be(false)
      expect(described_class.rewrite(large_xmi, "Building"))
        .to eq([large_xmi, "Building", nil])
      expect(log).not_to include("whole-load")
    end
  end

  context "with no table macros in the document" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:

        This document has no lutaml table macros at all.
      TEXT
    end

    it "leaves the registry disengaged" do
      convert_with_logger(input)

      expect(described_class.slice?(large_xmi)).to be(false)
      expect(described_class.rewrite(large_xmi, "Building"))
        .to eq([large_xmi, "Building", nil])
    end
  end

  context "with a source below MIN_SOURCE_BYTES" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        lutaml_klass_table::#{small_xmi}[name="NilReason"]
      TEXT
    end

    it "whole-loads the small source without engaging the registry" do
      output, log = convert_with_logger(input)

      expect(output).to include("nilReasonEnumeration")
      expect(described_class.slice?(small_xmi)).to be(false)
      expect(described_class.rewrite(small_xmi, "NilReason"))
        .to eq([small_xmi, "NilReason", nil])
      expect(log).not_to include("whole-load")
    end
  end

  context "with a small source in a document engaged on a large one" do
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        lutaml_klass_table::#{large_xmi}[name="Building"]

        lutaml_klass_table::#{small_xmi}[name="NilReason"]
      TEXT
    end

    it "whole-loads the small source silently" do
      output, log = convert_with_logger(input)

      expect(output).to include("nilReasonEnumeration")
      expect(described_class.slice?(large_xmi)).to be(true)
      expect(described_class.slice?(small_xmi)).to be(false)
      expect(log).not_to include("whole-load")
    end
  end

  context "with an unresolvable class in an engaged document" do
    # The ghost class sits in its own package, so its group seeds no
    # slice at all; the package-less macro of the same document still
    # engages the registry on the real class.
    let(:input) do
      <<~TEXT
        = Document title
        Author
        :nodoc:
        :novalid:
        :no-isobib:
        :imagesdir: spec/assets

        lutaml_klass_table::#{large_xmi}[package="NoSuchPackageAnywhere",name="Ghost"]

        lutaml_klass_table::#{large_xmi}[name="Building"]
      TEXT
    end

    it "warns once for the unresolvable class and renders the real one" do
      output, log = convert_with_logger(input)

      expect(output).to have_tag("table")
      expect(described_class.slice?(large_xmi)).to be(true)
      expect(log).to include("Ghost")
      expect(log).to include(large_xmi)
      expect(log).to include("test.adoc")
      expect(log.scan("whole-load").size).to eq(1)
    end
  end
end
