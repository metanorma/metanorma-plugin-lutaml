# frozen_string_literal: true

require "lutaml/model"
require "set"

module Metanorma
  module Plugin
    module Lutaml
      # Finds schema shapes the XML compiler would bind to the wrong class or
      # attribute. The compiler keys generated names by local name only, so
      # only components reachable from the root may share a generated name.
      class XmlDataBindingGuard
        XSD = "http://www.w3.org/2001/XMLSchema"
        GLOBALS = "/xs:schema/xs:complexType | /xs:schema/xs:simpleType | " \
                  "/xs:schema/xs:element | /xs:schema/xs:attribute | " \
                  "/xs:schema/xs:group | /xs:schema/xs:attributeGroup"
        TYPE_REFERENCES = %w[type base itemType memberTypes].freeze
        TYPE_KINDS = %w[complexType simpleType].freeze
        CLASS_KINDS = %i[type group].freeze
        LOCAL_KINDS = %i[element attribute attributeGroup].freeze
        INHERITING = %w[group attributeGroup extension restriction].freeze
        ANONYMOUS_PREFIXES = { "complexType" => "CT",
                               "simpleType" => "ST" }.freeze
        # The parser drops these when they declare a namespace prefix.
        # A union of these accepts any text, so the value survives even though
        # the compiler ignores the union's anonymous members.
        TEXT_TYPES = %w[string token].freeze
        REDEFINED = "/xs:schema/xs:redefine/xs:group | " \
                    "/xs:schema/xs:redefine/xs:attributeGroup"
        NAMESPACE_DROPPED = %w[element attribute attributeGroup complexType
                               simpleType complexContent simpleContent
                               extension sequence group].freeze

        def initialize(documents, declaration, namespace)
          @documents = documents
          @declaration = declaration
          @namespace = namespace
          @index = build_index
          @reachable = reachable_keys
        end

        def check
          reject_namespace_clashes
          reject_class_clashes
          reject_untyped_elements
          reject_member_clashes
          reject_declared_namespaces
          reject_derived_simple_content
          reject_all_groups
          reject_anonymous_unions
          reject_redefined_groups
          reject_content_attributes
        end

        # Removes global components the root never uses, so that an unused
        # type cannot replace a used one of the same name. Returns whether
        # anything was removed.
        def prune
          kept = reachable_nodes.to_set { |node, _| location(node) }
          removed = @documents.flat_map do |document, _|
            document.xpath(GLOBALS, "xs" => XSD).reject do |node|
              kept.include?(location(node))
            end
          end
          removed.each(&:unlink)
          removed.any?
        end

        def self.class_key(name)
          utils = ::Lutaml::Model::Utils
          utils.snake_case(utils.camel_case(name))
        end

        private

        def location(node)
          [node.document.url, node.path]
        end

        def build_index
          @documents.each_with_object({}) do |(document, namespace), index|
            document.xpath(GLOBALS, "xs" => XSD).each do |node|
              kind = TYPE_KINDS.include?(node.name) ? :type : node.name.to_sym
              (index[[kind, namespace, node["name"]]] ||= []) <<
                [node, namespace]
            end
          end
        end

        def root_key
          [:element, @namespace, @declaration["name"]]
        end

        def reachable_keys
          seen = { root_key => true }
          pending = [[@declaration, @namespace]]
          until pending.empty?
            node, owner = pending.pop
            fresh = references(node, owner).uniq.reject { |key| seen[key] }
            fresh.each { |key| seen[key] = true }
            pending.concat(fresh.flat_map { |key| @index.fetch(key, []) })
          end
          @referenced = seen
          seen.keys.select { |key| @index.key?(key) }
        end

        def reachable_nodes
          @reachable_nodes ||= @reachable.flat_map { |key| @index.fetch(key) }
        end

        def references(node, owner)
          node.xpath("descendant-or-self::xs:*", "xs" => XSD).flat_map do |item|
            keys = TYPE_REFERENCES.flat_map { |name| item[name].to_s.split }
              .map { |reference| reference_key(item, :type, reference, owner) }
            next keys unless item["ref"]

            keys << reference_key(item, item.name.to_sym, item["ref"], owner)
          end
        end

        # An unprefixed reference with no default namespace names no
        # namespace, except inside a chameleon include, which adopts one.
        def reference_key(node, kind, reference, owner)
          local, prefix = reference.split(":", 2).reverse
          declared = node.namespaces[prefix ? "xmlns:#{prefix}" : "xmlns"]
          [kind, declared || unqualified(node, owner), local]
        end

        def unqualified(node, owner)
          node.document.root["targetNamespace"] ? "" : owner
        end

        def reject_namespace_clashes
          types = @reachable.select { |kind, _, _| kind == :type }
          clashes = names_in_several_namespaces(types)
          unless clashes.empty?
            raise XmlDataLoader::Error,
                  "Types in several namespaces: #{clashes.join(', ')}"
          end

          locals = @reachable.select { |kind, _, _| LOCAL_KINDS.include?(kind) }
          clashes = names_in_several_namespaces(locals)
          return if clashes.empty?

          raise XmlDataLoader::Error,
                "Declarations in several namespaces: #{clashes.join(', ')}"
        end

        def names_in_several_namespaces(keys)
          keys.group_by { |kind, _, name| [kind, name] }
            .select { |_, group| group.size > 1 }
            .map { |(_, name), _| name }
        end

        def reject_class_clashes
          clash = generated_names.group_by(&:first).find do |_, entries|
            entries.map(&:last).uniq.size > 1
          end
          return unless clash

          raise XmlDataLoader::Error,
                "Schema components generate one class: #{clash.first}"
        end

        def generated_names
          global_names + anonymous_names
        end

        def global_names
          @reachable.filter_map do |kind, namespace, name|
            next unless CLASS_KINDS.include?(kind)

            [self.class.class_key(name), [kind, namespace, name]]
          end
        end

        def anonymous_names
          each_reachable("element", "attribute").flat_map do |node, owner|
            node.element_children.filter_map do |child|
              prefix = ANONYMOUS_PREFIXES[child.name]
              next unless prefix

              [self.class.class_key("#{prefix}_#{node['name']}"),
               [owner, child.canonicalize]]
            end
          end
        end

        def each_reachable(*names)
          path = names.map { |name| "descendant-or-self::xs:#{name}" }.join("|")
          roots = [[@declaration, @namespace], *reachable_nodes].uniq
          roots.flat_map do |node, owner|
            node.xpath(path, "xs" => XSD).map { |item| [item, owner] }
          end
        end

        def reject_untyped_elements
          untyped = each_reachable("element").map(&:first).find do |node|
            !node["type"] && !node["ref"] &&
              node.xpath("xs:complexType | xs:simpleType", "xs" => XSD).empty?
          end
          return unless untyped

          raise XmlDataLoader::Error,
                "Element #{untyped['name']} has no type, so its content " \
                "cannot bind"
        end

        def reject_member_clashes
          each_reachable("complexType").each do |type, owner|
            members = collect_members(type, owner, {}).uniq
            clash = members.group_by { |_, _, name, _| snake(name) }
              .find { |_, group| group.size > 1 }
            raise_member_clash(*clash) if clash
          end
        end

        def raise_member_clash(attribute, group)
          names = group.map { |_, _, name, _| name }
          if group.all? { |kind, *| kind == "element" } &&
              names.uniq.one? && group.map { |_, space, *| space }.uniq.size > 1
            raise XmlDataLoader::Error,
                  "Element #{names.first} is in several namespaces"
          end

          raise XmlDataLoader::Error,
                "Members map to one attribute #{attribute}: " \
                "#{names.join(', ')}"
        end

        # The XSD parser discards a component that declares a namespace
        # (xmlns or xmlns:p) on itself, and its content goes unbound.
        def reject_declared_namespaces
          reachable_nodes.map(&:first).uniq.each do |node|
            axis = node == @declaration ? "descendant" : "descendant-or-self"
            dropped = node.xpath("#{axis}::xs:*[not(ancestor-or-self::" \
                                 "xs:annotation)]", "xs" => XSD)
              .find { |item| namespace_dropped?(item) }
            raise_dropped(dropped) if dropped
          end
        end

        def namespace_dropped?(node)
          NAMESPACE_DROPPED.include?(node.name) &&
            node.namespace_definitions.any?
        end

        def raise_dropped(node)
          raise XmlDataLoader::Error,
                "Schema #{node.name} #{node['name'] || node['ref']} " \
                "declares a namespace, so its content cannot bind"
        end

        # The compiler treats a complex base type of simpleContent as a
        # value type, so the attributes the base declares are not bound.
        def reject_derived_simple_content
          each_reachable("extension", "restriction").each do |node, owner|
            next unless node.parent.name == "simpleContent"

            key = reference_key(node, :type, node["base"], owner)
            next unless attributes_below?(key, {})

            raise XmlDataLoader::Error,
                  "Type derived from complex type #{key.last} drops its " \
                  "attributes, so they cannot bind"
          end
        end

        def attributes_below?(key, seen)
          return false if seen[key]

          seen[key] = true
          @index.fetch(key, []).any? do |target, owner|
            target.name == "complexType" &&
              derivation_carries_attributes?(target, owner, seen)
          end
        end

        def derivation_carries_attributes?(type, owner, seen)
          derivation = type.at_xpath("xs:simpleContent/*", "xs" => XSD)
          return false unless derivation

          derivation.xpath("xs:attribute | xs:attributeGroup | " \
                           "xs:anyAttribute", "xs" => XSD).any? ||
            attributes_below?(reference_key(derivation, :type,
                                            derivation["base"], owner), seen)
        end

        # The compiler binds no element of an xs:all, so every child is lost.
        def reject_all_groups
          return if each_reachable("all").empty?

          raise XmlDataLoader::Error,
                "Schema uses xs:all, whose children cannot bind"
        end

        # The compiler skips a union's anonymous member types. The value
        # is kept only when a named member already accepts any text.
        def reject_anonymous_unions
          each_reachable("union").each do |union, owner|
            next if union.xpath("xs:simpleType", "xs" => XSD).empty?
            next if text_member?(union, owner)

            raise XmlDataLoader::Error,
                  "Union with anonymous member types cannot bind its values"
          end
        end

        def text_member?(union, owner)
          union["memberTypes"].to_s.split.any? do |reference|
            _, namespace, local = reference_key(union, :type, reference, owner)
            namespace == XSD && TEXT_TYPES.include?(local)
          end
        end

        # The loader does not follow xs:redefine, so the redefined group's
        # members never reach the model.
        def reject_redefined_groups
          @documents.each do |document, namespace|
            document.xpath(REDEFINED, "xs" => XSD).each do |node|
              key = [node.name.to_sym, namespace, node["name"]]
              next unless @referenced[key]

              raise XmlDataLoader::Error,
                    "Schema redefines #{node.name} #{node['name']}, so its " \
                    "members cannot bind"
            end
          end
        end

        # An attribute named content takes the slot the value is bound to.
        def reject_content_attributes
          each_reachable("complexType").each do |type, owner|
            next unless type.at_xpath("xs:simpleContent", "xs" => XSD)

            clash = collect_members(type, owner, {}).find do |kind, _, name, _|
              kind == "attribute" && snake(name) == "content"
            end
            next unless clash

            raise XmlDataLoader::Error,
                  "Attribute content collides with the value of a type " \
                  "with simple content"
          end
        end

        def snake(name)
          ::Lutaml::Model::Utils.snake_case(name)
        end

        def collect_members(node, owner, seen)
          node.element_children.flat_map do |child|
            next [] unless child.namespace&.href == XSD

            case child.name
            when "element", "attribute" then [member(child, owner)]
            when "simpleType", "annotation" then []
            when "restriction" then inherited_members(child, owner, seen)
            when *INHERITING
              inherited_members(child, owner, seen) +
                collect_members(child, owner, seen)
            else collect_members(child, owner, seen)
            end
          end
        end

        def member(node, owner)
          unless node["ref"]
            return [node.name, owner, node["name"], declared_type(node)]
          end

          _, namespace, local = reference_key(node, node.name.to_sym,
                                              node["ref"], owner)
          [node.name, namespace, local, :ref]
        end

        # Repeats of one declaration share a type, so they stay one member.
        # A local and a global of one name do not, and must not merge.
        def declared_type(node)
          node["type"] || node.xpath("xs:complexType | xs:simpleType",
                                     "xs" => XSD).map(&:canonicalize).join
        end

        def inherited_members(node, owner, seen)
          reference = node["ref"] || node["base"]
          return [] unless reference

          kind = node["ref"] ? node.name.to_sym : :type
          key = reference_key(node, kind, reference, owner)
          return [] if seen[key]

          seen[key] = true
          @index.fetch(key, []).flat_map do |target, target_owner|
            collect_members(target, target_owner, seen)
          end
        end
      end
    end
  end
end
