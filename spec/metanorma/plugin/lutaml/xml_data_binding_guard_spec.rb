# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "metanorma/plugin/lutaml/xml_data_loader"

RSpec.describe Metanorma::Plugin::Lutaml::XmlDataBindingGuard do
  let(:loader) { Metanorma::Plugin::Lutaml::XmlDataLoader.new }
  let(:xs) { "http://www.w3.org/2001/XMLSchema" }

  def leaf(name, type = "xs:string")
    %(<xs:element name="#{name}" type="#{type}"/>)
  end

  def sequence(*items)
    "<xs:sequence>#{items.join}</xs:sequence>"
  end

  def inline(name, *items, extra: "")
    %(<xs:element name="#{name}"#{extra}><xs:complexType>) +
      "#{sequence(*items)}</xs:complexType></xs:element>"
  end

  def catalog(content, attributes = "")
    %(<xs:element name="Catalog"><xs:complexType>#{content}) +
      "#{attributes}</xs:complexType></xs:element>"
  end

  def named_type(name, *items)
    %(<xs:complexType name="#{name}">#{sequence(*items)}</xs:complexType>)
  end

  def group(name, *items)
    %(<xs:group name="#{name}">#{sequence(*items)}</xs:group>)
  end

  def data(inner = "", attributes = "")
    %(<Catalog xmlns="urn:a"#{attributes}>#{inner}</Catalog>)
  end

  def schema_xml(body)
    <<~XSD.delete("\n")
      <xs:schema xmlns:xs="#{xs}" xmlns:a="urn:a" xmlns:b="urn:b"
        targetNamespace="urn:a" elementFormDefault="qualified">#{body}
      </xs:schema>
    XSD
  end

  def imported_schema(body, namespace: ' targetNamespace="urn:b"')
    %(<xs:schema xmlns:xs="#{xs}"#{namespace} ) +
      %(elementFormDefault="qualified">#{body}</xs:schema>)
  end

  def load_schema(body, xml, imported: nil)
    Dir.mktmpdir("xml-guard") do |dir|
      File.write(File.join(dir, "root.xsd"), schema_xml(body))
      File.write(File.join(dir, "data.xml"), xml)
      File.write(File.join(dir, "other.xsd"), imported) if imported
      loader.load(File.join(dir, "root.xsd"), File.join(dir, "data.xml"))
        .fetch("Catalog")
    end
  end

  def rejection(body, xml, imported: nil)
    load_schema(body, xml, imported: imported)
    nil
  rescue Metanorma::Plugin::Lutaml::XmlDataLoader::Error => e
    e.message
  end

  describe "schema shapes the compiler would bind to the wrong place" do
    it "rejects same-named anonymous types in sibling elements" do
      item = ->(child) { inline("item", leaf(child), extra: ' minOccurs="0"') }
      body = catalog(sequence(inline("orders", item.call("sku")),
                              inline("returns", item.call("reason"))))
      xml = data("<orders><item><sku>S1</sku></item></orders>" \
                 "<returns><item><reason>BROKEN</reason></item></returns>")
      expect(rejection(body, xml))
        .to include("Schema components generate one class: ct_item")
    end

    it "rejects an anonymous type nested under a same-named element" do
      body = catalog(sequence(inline("x", leaf("p")),
                              inline("y", inline("x", leaf("q")))))
      xml = data("<x><p>P</p></x><y><x><q>Q</q></x></y>")
      expect(rejection(body, xml))
        .to include("Schema components generate one class: ctx")
    end

    it "rejects types whose names differ only by case style" do
      body = [named_type("FooBar", leaf("one")),
              named_type("foo_bar", leaf("two")),
              catalog(sequence(leaf("left", "a:FooBar"),
                               leaf("right", "a:foo_bar")))].join
      xml = data("<left><one>ONE</one></left><right><two>TWO</two></right>")
      expect(rejection(body, xml))
        .to include("Schema components generate one class: foo_bar")
    end

    it "rejects a named type that generates the root's class name" do
      body = [named_type("CTCatalog", leaf("n")),
              catalog(sequence(leaf("x", "a:CTCatalog"), leaf("m")))].join
      xml = data("<x><n>N</n></x><m>M</m>")
      expect(rejection(body, xml))
        .to include("Schema components generate one class: ct_catalog")
    end

    it "rejects element names that map to one attribute" do
      body = catalog(sequence(leaf("fooBar"), leaf("foo_bar")))
      xml = data("<fooBar>ONE</fooBar><foo_bar>TWO</foo_bar>")
      expect(rejection(body, xml))
        .to include("Members map to one attribute foo_bar: fooBar, foo_bar")
    end

    it "rejects element names that differ only by punctuation" do
      body = catalog(sequence(leaf("foo-bar"), leaf("foo.bar")))
      xml = data("<foo-bar>ONE</foo-bar><foo.bar>TWO</foo.bar>")
      expect(rejection(body, xml))
        .to include("Members map to one attribute foo_bar: foo-bar, foo.bar")
    end

    it "rejects attribute names that map to one attribute" do
      attributes = '<xs:attribute name="foo-bar" type="xs:string"/>' \
                   '<xs:attribute name="foo_bar" type="xs:string"/>'
      body = catalog("", attributes)
      xml = data("", ' foo-bar="ONE" foo_bar="TWO"')
      expect(rejection(body, xml))
        .to include("Members map to one attribute foo_bar: foo-bar, foo_bar")
    end

    it "rejects an attribute and an element with the same name" do
      body = catalog(sequence(leaf("id")),
                     '<xs:attribute name="id" type="xs:string"/>')
      xml = data("<id>ELEM</id>", ' id="ATTR"')
      expect(rejection(body, xml))
        .to include("Members map to one attribute id: id, id")
    end

    it "rejects an element with no type, which would drop its content" do
      body = catalog(sequence('<xs:element name="entry"/>'))
      xml = data('<entry code="SECRET"><nested>VALUE</nested></entry>')
      expect(rejection(body, xml))
        .to include("Element entry has no type, so its content cannot bind")
    end

    it "rejects one local type name used from two namespaces" do
      body = [%(<xs:import schemaLocation="other.xsd"/>),
              named_type("Detail", leaf("one")),
              catalog(sequence(leaf("left", "a:Detail"),
                               leaf("right", "Detail")))].join
      imported = imported_schema(named_type("Detail", leaf("two")),
                                 namespace: "")
      xml = data("<left><one>ONE</one></left><right><two xmlns=\"\">TWO" \
                 "</two></right>")
      expect(rejection(body, xml, imported: imported))
        .to include("Types in several namespaces: Detail")
    end

    it "rejects an element that declares a namespace, which is dropped" do
      entry = '<xs:element name="entry" type="xs:string" xmlns="urn:a"/>'
      body = catalog(sequence(leaf("first"), entry))
      xml = data("<first>ONE</first><entry>SECRET</entry>")
      expect(rejection(body, xml))
        .to include("element entry declares a namespace")
    end

    it "rejects a group that declares a namespace, which is dropped" do
      declared = '<xs:group name="Pair" xmlns:z="urn:z">' \
                 "#{sequence(leaf('two'))}</xs:group>"
      body = [declared, catalog(sequence('<xs:group ref="a:Pair"/>'))].join
      expect(rejection(body, data("<two>TWO</two>")))
        .to include("group Pair declares a namespace")
    end

    it "rejects a type derived from a complex type that has attributes" do
      base = '<xs:complexType name="Base"><xs:simpleContent>' \
             '<xs:extension base="xs:string"><xs:attribute name="code" ' \
             'type="xs:string"/></xs:extension></xs:simpleContent>' \
             "</xs:complexType>"
      derived = '<xs:complexType name="Derived"><xs:simpleContent>' \
                '<xs:extension base="a:Base"><xs:attribute name="note" ' \
                'type="xs:string"/></xs:extension></xs:simpleContent>' \
                "</xs:complexType>"
      body = [base, derived, catalog(sequence(leaf("entry", "a:Derived")))]
      xml = data('<entry code="SECRET" note="N">TEXT</entry>')
      expect(rejection(body.join, xml))
        .to include("Type derived from complex type Base drops its " \
                    "attributes")
    end
  end

  describe "schemas that must still load" do
    it "binds the used type when an unreached import reuses its name" do
      body = [%(<xs:import namespace="urn:b" schemaLocation="other.xsd"/>),
              named_type("Detail", leaf("one")),
              catalog(sequence(leaf("right", "b:Detail")))].join
      imported = imported_schema(named_type("Detail", leaf("two")))
      xml = data('<right><two xmlns="urn:b">TWO</two></right>')
      model = load_schema(body, xml, imported: imported)
      expect(model.right.two).to eq("TWO")
    end

    it "binds a group whose name matches a renamed built-in type" do
      body = [named_type("Date", leaf("one")),
              group("XmlDataTypeDate", leaf("two")),
              catalog(sequence(leaf("entry", "a:Date"),
                               '<xs:group ref="a:XmlDataTypeDate"/>'))].join
      xml = data("<entry><one>ONE</one></entry><two>TWO</two>")
      model = load_schema(body, xml)
      expect([model.entry.one, model.two]).to eq(%w[ONE TWO])
    end

    it "keeps same-named groups of successive loads apart" do
      first = catalog('<xs:sequence><xs:group ref="a:Shared"/></xs:sequence>')
      schemas = [group("Shared", leaf("one")), group("Shared", leaf("two"))]
      models = [["one", 0], ["two", 1], ["one", 0]].map do |name, index|
        xml = data("<#{name}>VALUE</#{name}>")
        load_schema(schemas[index] + first, xml)
      end
      names = models.map { |model| model.class.attributes.keys }
      expect(names).to eq([[:one], [:two], [:one]])
      expect(Object.const_defined?(:Shared, false)).to be(false)
    end

    it "refuses a group that would reopen an existing class" do
      existing = stub_const("ExistingGroup", Class.new)
      body = group("ExistingGroup", leaf("one")) +
        catalog('<xs:sequence><xs:group ref="a:ExistingGroup"/></xs:sequence>')
      expect { load_schema(body, data("<one>ONE</one>")) }
        .to raise_error(Metanorma::Plugin::Lutaml::XmlDataLoader::Error,
                        /Group ExistingGroup names an existing class/)
      expect(ExistingGroup).to equal(existing)
      expect(existing.instance_methods(false)).to be_empty
    end

    it "binds nested anonymous types with distinct names" do
      body = catalog(sequence(inline("a", leaf("item")),
                              inline("b", inline("item", leaf("deep")))))
      xml = data("<a><item>S</item></a><b><item><deep>D</deep></item></b>")
      expect(load_schema(body, xml).b.item.deep).to eq("D")
    end

    it "binds a namespace declared inside annotation content" do
      note = '<xs:annotation><xs:documentation xmlns:h="urn:h">' \
             "<h:b>note</h:b></xs:documentation></xs:annotation>"
      body = catalog(note + sequence(leaf("entry")))
      expect(load_schema(body, data("<entry>E</entry>")).entry).to eq("E")
    end

    it "binds a type derived from a complex type without attributes" do
      base = '<xs:complexType name="Base"><xs:simpleContent>' \
             '<xs:extension base="xs:string"/></xs:simpleContent>' \
             "</xs:complexType>"
      derived = '<xs:complexType name="Derived"><xs:simpleContent>' \
                '<xs:extension base="a:Base"><xs:attribute name="note" ' \
                'type="xs:string"/></xs:extension></xs:simpleContent>' \
                "</xs:complexType>"
      body = [base, derived, catalog(sequence(leaf("entry", "a:Derived")))]
      entry = load_schema(body.join, data('<entry note="N">TEXT</entry>'))
        .entry
      expect([entry.content, entry.note]).to eq(%w[TEXT N])
    end
  end
end
