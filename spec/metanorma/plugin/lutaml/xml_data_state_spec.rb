# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "metanorma/plugin/lutaml/xml_data_loader"

# Process-wide state the loader touches: constants, the type registry and
# names that the generated models share with Ruby and the XSD model.
# rubocop:disable-next RSpec/SpecFilePathFormat
RSpec.describe Metanorma::Plugin::Lutaml::XmlDataLoader do
  subject(:loader) { described_class.new }

  let(:xs) { "http://www.w3.org/2001/XMLSchema" }

  def schema(body)
    %(<?xml version="1.0"?><xs:schema xmlns:xs="#{xs}">#{body}</xs:schema>)
  end

  def root_with(*members)
    "<xs:element name='R'><xs:complexType><xs:sequence>#{members.join}" \
      "</xs:sequence></xs:complexType></xs:element>"
  end

  def leaf(name)
    %(<xs:element name="#{name}" type="xs:string"/>)
  end

  def load_xsd(body, xml)
    Dir.mktmpdir("xml-state") do |dir|
      File.write(File.join(dir, "a.xsd"), schema(body))
      File.write(File.join(dir, "a.xml"), xml)
      loader.load(File.join(dir, "a.xsd"), File.join(dir, "a.xml")).fetch("R")
    end
  end

  def group_schema(name)
    "<xs:group name='#{name}'><xs:sequence>#{leaf('a')}</xs:sequence>" \
      "</xs:group><xs:element name='R'><xs:complexType>" \
      "<xs:group ref='#{name}'/></xs:complexType></xs:element>"
  end

  def registry
    Lutaml::Model::GlobalContext.default_context.registry
  end

  describe "classes and registry entries of a group" do
    let(:name) { "StateGroupProbe" }

    it "leaves a class another thread defined under the same name" do
      foreign = Class.new
      allow(loader).to receive(:bind).and_wrap_original do |original, *args|
        result = original.call(*args)
        Object.send(:remove_const, name) # rubocop:disable RSpec/RemoveConst
        Object.const_set(name, foreign)
        result
      end
      load_xsd(group_schema(name), "<R><a>x</a></R>")
      expect(Object.const_get(name, false)).to equal(foreign)
    ensure
      if Object.const_defined?(name, false)
        Object.send(:remove_const, name) # rubocop:disable RSpec/RemoveConst
      end
    end

    it "removes the class it created" do
      load_xsd(group_schema(name), "<R><a>x</a></R>")
      expect(Object.const_defined?(name, false)).to be(false)
    end

    it "keeps an entry the caller registered under the group's name" do
      caller_type = Class.new(Lutaml::Model::Serializable)
      registry.register(:state_group_probe, caller_type)
      load_xsd(group_schema(name), "<R><a>x</a></R>")
      expect(registry.types[:state_group_probe]).to equal(caller_type)
    ensure
      registry.types.delete(:state_group_probe)
    end

    it "leaves no entry behind when the caller had none" do
      load_xsd(group_schema(name), "<R><a>x</a></R>")
      expect(registry.types).not_to have_key(:state_group_probe)
    end
  end

  describe "groups named like XSD model types" do
    %w[List Key Field Element Schema Sequence].each do |name|
      it "binds a group named #{name}" do
        model = load_xsd(group_schema(name), "<R><a>x</a></R>")
        expect(model.a).to eq("x")
      end
    end
  end

  describe "type names that are not valid constants in generated code" do
    %w[BEGIN END].each do |name|
      it "reports type #{name} as a loader error" do
        body = "<xs:complexType name='#{name}'><xs:sequence>#{leaf('a')}" \
               "</xs:sequence></xs:complexType><xs:element name='R' " \
               "type='#{name}'/>"
        expect { load_xsd(body, "<R><a>x</a></R>") }
          .to raise_error(described_class::Error)
      end
    end
  end

  describe "members named like methods every object has" do
    %w[hash object_id send freeze dup initialize class].each do |name|
      it "rejects a member named #{name}" do
        expect do
          load_xsd(root_with(leaf(name)), "<R><#{name}>x</#{name}></R>")
        end.to raise_error(described_class::Error, /#{name}/)
      end
    end

    it "keeps an ordinary member" do
      model = load_xsd(root_with(leaf("title")), "<R><title>x</title></R>")
      expect(model.title).to eq("x")
    end
  end
end
