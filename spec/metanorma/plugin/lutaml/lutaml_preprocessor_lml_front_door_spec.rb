# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"
require "metanorma/plugin/lutaml/lutaml_preprocessor"

# lutaml-lml >= 0.3.8 is a shim over the lutaml monogem, whose front door
# Lutaml::Lml.parse reads the File's CONTENTS (Source.wrap) and returns a
# Lutaml::Lml::Document; the bare Lutaml::Lml::Parser.parse the shim still
# exposes grammar-parses input.to_s, i.e. the File's PATH STRING
# (metanorma-plugin-lutaml#361). The loader hands the preprocessor's
# non-.exp indexes to the front door.
RSpec.describe Metanorma::Plugin::Lutaml::LutamlPreprocessor do
  subject(:preprocessor) do
    described_class.allocate
  end

  let(:document_class) do
    Class.new do
      attr_reader :attributes, :path_resolver

      def initialize(attributes)
        @attributes = attributes
        @path_resolver = Class.new do
          def system_path(path, base) = File.expand_path(path, base)
        end.new
      end
    end
  end

  let(:document) do
    document_class.new("docfile" => File.join(lml_dir, "document.adoc"))
  end

  let(:lml_dir) { File.join(Dir.mktmpdir, "docs") }
  let(:lml_path) do
    FileUtils.mkdir_p(lml_dir)
    path = File.join(lml_dir, "widgets.lml")
    File.write(path, <<~LML)
      models WidgetStore {
        class Widgets {
          attribute widgets {
            type Widget
            cardinality 0..n
          }
        }

        class Widget {
          attribute id {
            type String
            cardinality 1
          }
        }
      }
    LML
    path
  end

  it "parses a LML file's contents into a LML document" do
    lml = preprocessor.send(:load_lutaml_file, document, lml_path, {})
    expect(lml).to be_a(Lutaml::Lml::Document)
  end

  it "carries the parsed classes" do
    lml = preprocessor.send(:load_lutaml_file, document, lml_path, {})
    names = lml.classes.map(&:name)
    expect(names).to include("Widgets", "Widget")
  end
end
