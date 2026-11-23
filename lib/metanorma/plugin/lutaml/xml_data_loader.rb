# frozen_string_literal: true

require "lutaml/model"
require "lutaml/xml"
require "nokogiri"
require "securerandom"
require "tmpdir"
require_relative "xml_data_binding_guard"

module Metanorma
  module Plugin
    module Lutaml
      # Compiles fresh bindings and retains typed model values.
      class XmlDataLoader
        class Error < StandardError; end

        XSD_NAMESPACE = "http://www.w3.org/2001/XMLSchema"
        GLOBAL_TYPES = "/xs:schema/xs:complexType | /xs:schema/xs:simpleType"
        PRESERVED_ATTRIBUTE_NAMESPACES = [
          "http://www.w3.org/2001/XMLSchema-instance",
          "http://www.w3.org/XML/1998/namespace",
        ].freeze
        XSI_NAMESPACE = "http://www.w3.org/2001/XMLSchema-instance"
        GLOBAL_COMPONENTS = "/xs:schema/xs:element | " \
                            "/xs:schema/xs:attribute | /xs:schema/xs:group | " \
                            "/xs:schema/xs:attributeGroup"
        OPEN_CONTENT = "//xs:any | //xs:anyAttribute | " \
                       "//xs:element[@substitutionGroup] | " \
                       "//xs:*[@mixed='true' or @mixed='1']"
        TYPE_REFERENCES = %w[type base itemType memberTypes].freeze
        RENAMED_TYPE_PREFIX = "XmlDataType"
        COMPILER_MUTEX = Mutex.new

        def load(definition_path, instances_path, location: nil)
          definition_path = File.expand_path(definition_path)
          instances_path = File.expand_path(instances_path)
          load_files(definition_path, instances_path, location)
        rescue StandardError => e
          raise Error, "XML data #{instances_path} with XSD " \
                       "#{definition_path}: #{e.message}"
        end

        private

        def load_files(definition_path, instances_path, location)
          schema = read_xml(definition_path, location: location)
          instance = read_xml(instances_path)
          validate_schema(schema, instance)
          documents = schema_documents(schema)
          declaration = root_declaration(documents, instance.root) ||
            raise(Error, "No XSD declaration for #{instance.root.name}")
          guard = XmlDataBindingGuard.new(documents, declaration,
                                          instance.root.namespace&.href.to_s)
          reject_unbindable(documents, guard, instance)

          Dir.mktmpdir("lutaml-xml-data") do |directory|
            renamed = private_schemas(documents, guard, directory)
            source, base = compile_source(schema, instance, declaration)
            base = renamed || base || location || File.dirname(definition_path)
            COMPILER_MUTEX.synchronize do
              with_group_classes(documents) do
                bind(source, instance, declaration, base)
              end
            end
          end
        end

        # The compiler defines each xs:group model as a top-level class and
        # registers it by bare name in the default context. Left behind, the
        # next load's same-named group would reopen it and inherit its
        # attributes; an existing class of that name would be altered.
        def with_group_classes(documents)
          names = group_names(documents).uniq.map do |name|
            ::Lutaml::Model::Utils.camel_case(name)
          end
          taken = names.find { |name| Object.const_defined?(name, false) }
          raise Error, "Group #{taken} names an existing class" if taken

          begin
            yield
          ensure
            forget_group_classes(names)
          end
        end

        def forget_group_classes(names)
          context = ::Lutaml::Model::GlobalContext.default_context
          names.each do |name|
            next unless Object.const_defined?(name, false)

            group = Object.const_get(name, false)
            context.registry.types.delete_if { |_, type| type.equal?(group) }
            Object.send(:remove_const, name)
          end
          ::Lutaml::Model::GlobalContext.resolver.clear_cache(context.id)
        end

        # A root from an imported namespace compiles from its own document,
        # because the compiler resolves equal type names by local name.
        def compile_source(schema, instance, declaration)
          root_namespace = instance.root.namespace&.href.to_s
          target_namespace = schema.root["targetNamespace"].to_s
          return [schema, nil] if root_namespace == target_namespace

          document = declaration.document
          [document, File.dirname(document.url)]
        end

        def read_xml(path, location: nil)
          base = if location
                   File.join(File.expand_path(location),
                             File.basename(path))
                 else
                   path
                 end
          Nokogiri::XML(File.read(path), base) { |config| config.strict.nonet }
        end

        def validate_schema(schema, instance)
          validator = Nokogiri::XML::Schema.from_document(schema)
          errors = validator.validate(instance)
          return if errors.empty?

          raise Error, errors.map(&:message).join("; ")
        end

        # This lookup binds the expanded element name, independently of the
        # instance's choice of namespace prefix. Compilation remains upstream.
        def root_declaration(documents, root)
          documents.each do |document, namespace|
            next unless namespace == root.namespace&.href.to_s

            elements = document.xpath("/xs:schema/xs:element",
                                      "xs" => XSD_NAMESPACE)
            declaration = elements.find do |element|
              element["name"] == root.name
            end
            return declaration if declaration
          end
          nil
        end

        # Pairs each document with its effective namespace: a chameleon
        # include has none of its own and inherits the including schema's.
        def schema_documents(schema, namespace = nil, visited = {})
          namespace ||= schema.root["targetNamespace"].to_s
          return [] if visited[[schema.url, namespace]]

          visited[[schema.url, namespace]] = true
          references = schema.xpath(
            "/xs:schema/xs:import | /xs:schema/xs:include",
            "xs" => XSD_NAMESPACE,
          )
          [[schema, namespace]] + references.flat_map do |reference|
            next [] unless reference["schemaLocation"]

            path = File.expand_path(reference["schemaLocation"],
                                    File.dirname(schema.url))
            document = read_xml(path)
            schema_documents(
              document, effective_namespace(reference, document, namespace),
              visited
            )
          end
        end

        def effective_namespace(reference, document, namespace)
          declared = document.root["targetNamespace"]
          return namespace if declared.nil? && reference.name == "include"

          declared.to_s
        end

        def reject_unbindable(documents, guard, instance)
          guard.check
          reject_open_content(documents)
          reject_dynamic_types(instance)
        end

        # Generated models have no attribute for this content, so hydration
        # would succeed while silently dropping it.
        def reject_open_content(documents)
          document, = documents.find do |parsed, _|
            parsed.at_xpath(OPEN_CONTENT, "xs" => XSD_NAMESPACE)
          end
          return unless document

          raise Error, "Schema #{File.basename(document.url)} uses wildcard " \
                       "or mixed content or substitution groups, which " \
                       "cannot bind"
        end

        # Hydration follows the declared type, so a derived type's content
        # would be dropped.
        def reject_dynamic_types(instance)
          node = instance.at_xpath("//@xsi:type", "xsi" => XSI_NAMESPACE)
          return unless node

          raise Error, "Element #{node.parent.name} uses xsi:type, " \
                       "which cannot bind"
        end

        def global_types(document)
          document.xpath(GLOBAL_TYPES, "xs" => XSD_NAMESPACE)
        end

        # The compiler gives a schema type named like a built-in (Date) the
        # built-in's symbol, so it would replace xs:date. A private copy of
        # the validated schemas carries those types under another name.
        def private_schemas(documents, guard, directory)
          pruned = guard.prune
          shadowing = shadowing_types(documents)
          return if shadowing.empty? && !pruned

          parsed = documents.map(&:first)
          files = parsed.map(&:url).uniq.each_with_index.to_h do |url, index|
            [url, "schema-#{index}.xsd"]
          end
          parsed.each do |document|
            rename_types(document, shadowing)
            relocate_references(document, files)
          end
          write_schemas(parsed, files, directory)
        end

        def write_schemas(parsed, files, directory)
          parsed.uniq(&:url).each do |document|
            File.write(File.join(directory, files[document.url]),
                       document.to_xml)
          end
          directory
        end

        def shadowing_types(documents)
          reserved = built_in_symbols
          names = documents.flat_map do |document, _|
            global_types(document).map { |type| type["name"] }
          end
          taken = (names + group_names(documents)).map do |name|
            XmlDataBindingGuard.class_key(name)
          end
          names.uniq.select do |name|
            reserved.include?(::Lutaml::Model::Utils.snake_case(name))
          end.to_h { |name| [name, unused_type_name(name, taken)] }
        end

        def group_names(documents)
          documents.flat_map do |document, _|
            document.xpath("/xs:schema/xs:group", "xs" => XSD_NAMESPACE)
              .map { |group| group["name"] }
          end
        end

        def unused_type_name(name, taken)
          candidate = "#{RENAMED_TYPE_PREFIX}#{name}"
          while taken.include?(XmlDataBindingGuard.class_key(candidate))
            candidate = "#{RENAMED_TYPE_PREFIX}#{candidate}"
          end
          taken << XmlDataBindingGuard.class_key(candidate)
          candidate
        end

        def built_in_symbols
          table = ::Lutaml::Model::Schema::XmlCompiler::SupportedDataTypes
          table.each.flat_map do |name, info|
            symbol = ::Lutaml::Model::Utils.snake_case(name.to_s)
            info[:skippable] ? [symbol, table.primitive_symbol(name)] : [symbol]
          end
        end

        def rename_types(document, shadowing)
          global_types(document).each do |type|
            next unless shadowing.key?(type["name"])

            type["name"] = shadowing.fetch(type["name"])
          end
          document.xpath("//xs:*", "xs" => XSD_NAMESPACE).each do |node|
            rename_references(node, shadowing)
          end
        end

        def rename_references(node, shadowing)
          TYPE_REFERENCES.each do |attribute|
            next unless node[attribute]

            node[attribute] = node[attribute].split.map do |reference|
              renamed_reference(node, reference, shadowing)
            end.join(" ")
          end
        end

        def renamed_reference(node, reference, shadowing)
          local, prefix = reference.split(":", 2).reverse
          key = prefix ? "xmlns:#{prefix}" : "xmlns"
          return reference if node.namespaces[key] == XSD_NAMESPACE
          return reference unless shadowing.key?(local)

          [prefix, shadowing.fetch(local)].compact.join(":")
        end

        def relocate_references(document, files)
          document.xpath("/xs:schema/xs:import | /xs:schema/xs:include",
                         "xs" => XSD_NAMESPACE).each do |reference|
            next unless reference["schemaLocation"]

            path = File.expand_path(reference["schemaLocation"],
                                    File.dirname(document.url))
            reference["schemaLocation"] = files.fetch(path)
          end
        end

        def bind(schema, instance, declaration, location)
          token = SecureRandom.hex(12)
          module_name = "LutamlXmlData#{token}"
          register_id = :"lutaml_xml_data_#{token}"
          compiler = compile(schema, instance, location, module_name,
                             register_id)
          model = hydrate(compiler, instance, declaration, module_name,
                          register_id)
          { instance.root.name => model }
        ensure
          cleanup(module_name, register_id)
        end

        def compile(schema, instance, location, module_name, register_id)
          compiler = ::Lutaml::Model::Schema::XmlCompiler
          compiler.to_models(
            schema.to_xml, module_namespace: module_name,
                           register_id: register_id, location: location,
                           namespace: instance.root.namespace&.href,
                           prefix: instance.root.namespace&.prefix,
                           load_classes: true
          )
          compiler
        end

        def hydrate(compiler, instance, declaration, module_name, register_id)
          klass = root_class(compiler, declaration, module_name)
          unless klass.is_a?(Class) && klass < ::Lutaml::Model::Serializable
            raise Error,
                  "Root #{instance.root.name} does not compile to an XML model"
          end

          # The complete XSD was validated before compilation. Generated-model
          # recursive validation does not preserve private register contexts.
          klass.from_xml(single_namespace_xml(instance), register: register_id)
        end

        # Compiled mappings carry one namespace, so validated elements from
        # imported namespaces move onto the root's before hydration.
        def single_namespace_xml(instance)
          copy = instance.dup
          namespace = copy.root.namespace
          copy.xpath("//*").each do |node|
            reject_unmappable(node, namespace)
            node.namespace = namespace if node.namespace
          end
          copy.to_xml
        end

        def reject_unmappable(node, namespace)
          reject_mixed_children(node)
          attribute = node.attribute_nodes.find do |item|
            foreign_attribute?(item, namespace)
          end
          return unless attribute

          raise Error, "Attribute #{attribute.name} is in an imported namespace"
        end

        def reject_mixed_children(node)
          clash = node.element_children.group_by(&:name).find do |_, children|
            children.map { |child| child.namespace&.href }.uniq.size > 1
          end
          return unless clash

          raise Error, "Element #{clash.first} is in several namespaces"
        end

        def foreign_attribute?(attribute, namespace)
          href = attribute.namespace&.href
          return false if href.nil? || href == namespace&.href

          !PRESERVED_ATTRIBUTE_NAMESPACES.include?(href)
        end

        def root_class(compiler, declaration, module_name)
          type = root_type(compiler, declaration)
          name = compiler.builder.all_models.keys.find do |key|
            ::Lutaml::Model::Utils.snake_case(key) == type.to_s
          end
          return unless name

          name = ::Lutaml::Model::Utils.camel_case(name)
          Object.const_get(module_name).const_get(name, false)
        end

        def root_type(compiler, declaration)
          if declaration["type"]
            ::Lutaml::Model::Utils.snake_case(declaration["type"].split(":").last)
          else
            compiler.builder.elements.fetch(declaration["name"]).type.value
          end
        end

        def cleanup(module_name, register_id)
          ::Lutaml::Model::GlobalRegister.remove(register_id) if register_id
          if module_name && Object.const_defined?(module_name, false)
            Object.send(:remove_const, module_name)
          end
          clear_generated_paths(module_name) if module_name
        end

        # ClassLoader requires temporary files; models retain their classes.
        def clear_generated_paths(module_name)
          basename = module_name.downcase
          $LOADED_FEATURES.reject! do |path|
            path.include?("/#{basename}/") ||
              path.end_with?("/#{basename}_registry.rb")
          end
        end
      end
    end
  end
end
