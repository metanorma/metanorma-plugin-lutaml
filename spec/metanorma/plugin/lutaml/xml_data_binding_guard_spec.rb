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

    {
      "element" => lambda { |t|
        [catalog(sequence(t.call(leaf("entry"))), ""),
         data("<entry>E</entry>")]
      },
      "attribute" => lambda { |t|
        [catalog(sequence(leaf("entry")),
                 t.call('<xs:attribute name="code" type="xs:string"/>')),
         data("<entry>E</entry>", ' code="C"')]
      },
      "attributeGroup" => lambda { |t|
        [t.call('<xs:attributeGroup name="AG"><xs:attribute name="code" ' \
                'type="xs:string"/></xs:attributeGroup>') +
          catalog(sequence(leaf("entry")), '<xs:attributeGroup ref="a:AG"/>'),
         data("<entry>E</entry>", ' code="C"')]
      },
      "complexType" => lambda { |t|
        [t.call(named_type("T", leaf("one"))) +
          catalog(sequence(leaf("entry", "a:T"))),
         data("<entry><one>O</one></entry>")]
      },
      "simpleType" => lambda { |t|
        [t.call('<xs:simpleType name="S"><xs:restriction base="xs:string"/>' \
                "</xs:simpleType>") + catalog(sequence(leaf("entry", "a:S"))),
         data("<entry>E</entry>")]
      },
      "complexContent" => lambda { |t|
        derived = t.call('<xs:complexContent><xs:extension base="a:B">' \
                         "#{sequence(leaf('two'))}</xs:extension>" \
                         "</xs:complexContent>")
        [[named_type("B", leaf("one")),
          %(<xs:complexType name="D">#{derived}</xs:complexType>),
          catalog(sequence(leaf("entry", "a:D")))].join,
         data("<entry><one>O</one><two>T</two></entry>")]
      },
      "simpleContent" => lambda { |t|
        content = t.call('<xs:simpleContent><xs:extension base="xs:string"/>' \
                         "</xs:simpleContent>")
        [[%(<xs:complexType name="D">#{content}</xs:complexType>),
          catalog(sequence(leaf("entry", "a:D")))].join,
         data("<entry>E</entry>")]
      },
      "extension" => lambda { |t|
        extension = t.call('<xs:extension base="xs:string"/>')
        [[%(<xs:complexType name="D"><xs:simpleContent>#{extension}) \
          "</xs:simpleContent></xs:complexType>",
          catalog(sequence(leaf("entry", "a:D")))].join,
         data("<entry>E</entry>")]
      },
      "sequence" => lambda { |t|
        [catalog(t.call(sequence(leaf("entry")))), data("<entry>E</entry>")]
      },
      "group" => lambda { |t|
        [t.call(group("Pair", leaf("two"))) +
          catalog(sequence('<xs:group ref="a:Pair"/>')),
         data("<two>TWO</two>")]
      },
    }.each do |kind, build|
      it "rejects a #{kind} that declares a namespace, which is dropped" do
        declare = lambda do |xml|
          xml.sub(/\A(<xs:#{kind}\b)/, '\1 xmlns:z="urn:z"')
        end
        body, xml = instance_exec(declare, &build)
        expect(rejection(body, xml))
          .to match(/Schema #{kind} .* declares a namespace/)
      end
    end

    it "rejects a declaration name used from two namespaces" do
      body = [%(<xs:import namespace="urn:b" schemaLocation="other.xsd"/>),
              leaf("Detail"),
              catalog(sequence('<xs:element ref="a:Detail"/>',
                               '<xs:element ref="b:Detail"/>'))].join
      xml = data('<Detail>ONE</Detail><Detail xmlns="urn:b">TWO</Detail>')
      imported = imported_schema(leaf("Detail"))
      expect(rejection(body, xml, imported: imported))
        .to include("Declarations in several namespaces: Detail")
    end

    it "rejects xs:all, whose children would all be lost" do
      body = catalog("<xs:all>#{leaf('a')}#{leaf('b')}</xs:all>")
      expect(rejection(body, data("<b>B</b><a>A</a>")))
        .to include("Schema uses xs:all, whose children cannot bind")
    end

    it "rejects a union of anonymous member types" do
      union = '<xs:simpleType name="U"><xs:union><xs:simpleType>' \
              '<xs:restriction base="xs:string">' \
              '<xs:enumeration value="none"/></xs:restriction>' \
              "</xs:simpleType></xs:union></xs:simpleType>"
      body = union + catalog(sequence(leaf("v", "a:U")))
      expect(rejection(body, data("<v>none</v>")))
        .to include("Union with anonymous member types cannot bind")
    end

    it "rejects an anonymous union that a narrower named member joins" do
      union = '<xs:simpleType name="U"><xs:union memberTypes="xs:integer">' \
              '<xs:simpleType><xs:restriction base="xs:string">' \
              '<xs:enumeration value="none"/></xs:restriction>' \
              "</xs:simpleType></xs:union></xs:simpleType>"
      body = union + catalog(sequence(leaf("v", "a:U")))
      expect(rejection(body, data("<v>none</v>")))
        .to include("Union with anonymous member types cannot bind")
    end

    it "rejects a redefined group" do
      redefine = '<xs:redefine schemaLocation="other.xsd"><xs:group ' \
                 'name="G"><xs:sequence><xs:group ref="a:G"/>' \
                 "#{leaf('more')}</xs:sequence></xs:group></xs:redefine>"
      body = redefine + catalog(sequence('<xs:group ref="a:G"/>'))
      imported = imported_schema(group("G", leaf("base")),
                                 namespace: ' targetNamespace="urn:a"')
      expect(rejection(body, data("<base>B</base><more>M</more>"),
                       imported: imported))
        .to include("Schema redefines group G, so its members cannot bind")
    end

    it "rejects a redefined attribute group" do
      redefine = '<xs:redefine schemaLocation="other.xsd"><xs:attributeGroup ' \
                 'name="AG"><xs:attributeGroup ref="a:AG"/><xs:attribute ' \
                 'name="y" type="xs:string"/></xs:attributeGroup>' \
                 "</xs:redefine>"
      body = redefine + catalog(sequence(leaf("p")),
                                '<xs:attributeGroup ref="a:AG"/>')
      imported = imported_schema(
        '<xs:attributeGroup name="AG"><xs:attribute name="x" ' \
        'type="xs:string"/></xs:attributeGroup>',
        namespace: ' targetNamespace="urn:a"',
      )
      expect(rejection(body, data("<p>P</p>", ' x="X" y="Y"'),
                       imported: imported))
        .to include("Schema redefines attributeGroup AG")
    end

    it "rejects an attribute named content on a type with simple content" do
      body = '<xs:element name="Catalog"><xs:complexType><xs:simpleContent>' \
             '<xs:extension base="xs:string"><xs:attribute name="content" ' \
             'type="xs:string"/></xs:extension></xs:simpleContent>' \
             "</xs:complexType></xs:element>"
      expect(rejection(body, data("TEXT", ' content="ATTR"')))
        .to include("Attribute content collides with the value")
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
      values = models.zip(names).map { |model, (name)| model.public_send(name) }
      expect(values).to eq(%w[VALUE VALUE VALUE])
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

    it "binds a same-named element with one anonymous type" do
      body = catalog(sequence(inline("a", leaf("item")),
                              inline("b", inline("item", leaf("deep")))))
      xml = data("<a><item>S</item></a><b><item><deep>D</deep></item></b>")
      model = load_schema(body, xml)
      expect([model.a.item, model.b.item.deep]).to eq(%w[S D])
    end

    it "binds a namespace declared inside annotation content" do
      note = '<xs:annotation><xs:appinfo><xs:element name="x" ' \
             'type="xs:string" xmlns:h="urn:h"/></xs:appinfo></xs:annotation>'
      body = catalog(note + sequence(leaf("entry")))
      expect(load_schema(body, data("<entry>E</entry>")).entry).to eq("E")
    end

    it "binds a named union whose member types are all named" do
      union = '<xs:simpleType name="U"><xs:union memberTypes="xs:integer ' \
              'xs:string"/></xs:simpleType>'
      body = union + catalog(sequence(leaf("v", "a:U")))
      expect(load_schema(body, data("<v>none</v>")).v).to eq("none")
    end

    it "binds a union whose named member accepts any text" do
      union = '<xs:simpleType name="U"><xs:union memberTypes="xs:token">' \
              '<xs:simpleType><xs:restriction base="xs:token">' \
              '<xs:enumeration value="ASCII"/></xs:restriction>' \
              "</xs:simpleType></xs:union></xs:simpleType>"
      body = union + catalog(sequence(leaf("v", "a:U")))
      expect(load_schema(body, data("<v>ASCII</v>")).v).to eq("ASCII")
    end

    it "binds an unused xs:all and an unused anonymous union" do
      unused = %(<xs:complexType name="Unused"><xs:all>#{leaf('a')}) \
               '</xs:all></xs:complexType><xs:simpleType name="Loose">' \
               "<xs:union><xs:simpleType><xs:restriction base=\"xs:string\"/>" \
               "</xs:simpleType></xs:union></xs:simpleType>"
      body = unused + catalog(sequence(leaf("entry")))
      expect(load_schema(body, data("<entry>E</entry>")).entry).to eq("E")
    end

    it "binds an attribute named content beside element content" do
      body = catalog(sequence(leaf("entry")),
                     '<xs:attribute name="content" type="xs:string"/>')
      model = load_schema(body, data("<entry>E</entry>", ' content="ATTR"'))
      expect([model.entry, model.content]).to eq(%w[E ATTR])
    end

    it "binds a simple content attribute with another name" do
      body = '<xs:element name="Catalog"><xs:complexType><xs:simpleContent>' \
             '<xs:extension base="xs:string"><xs:attribute name="code" ' \
             'type="xs:string"/></xs:extension></xs:simpleContent>' \
             "</xs:complexType></xs:element>"
      model = load_schema(body, data("TEXT", ' code="C"'))
      expect([model.content, model.code]).to eq(%w[TEXT C])
    end

    it "binds a group that no redefine touches" do
      body = group("G", leaf("base")) +
        catalog(sequence('<xs:group ref="a:G"/>'))
      expect(load_schema(body, data("<base>B</base>")).base).to eq("B")
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
