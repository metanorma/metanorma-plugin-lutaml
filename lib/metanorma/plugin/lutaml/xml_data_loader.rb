# frozen_string_literal: true

require "lutaml/model"
require "lutaml/xml"
require "nokogiri"
require "securerandom"

module Metanorma
  module Plugin
    module Lutaml
      # Compiles fresh bindings and retains typed model values.
      class XmlDataLoader
        class Error < StandardError; end

        XSD_NAMESPACE = "http://www.w3.org/2001/XMLSchema"
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
          declaration = root_declaration(schema, instance.root)
          unless declaration
            raise Error,
                  "No XSD declaration for #{instance.root.name}"
          end

          COMPILER_MUTEX.synchronize do
            bind(schema, instance, declaration,
                 location || File.dirname(definition_path))
          end
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
        def root_declaration(schema, root)
          schema_documents(schema).each do |document|
            next unless document.root["targetNamespace"].to_s ==
              root.namespace&.href.to_s

            elements = document.xpath("/xs:schema/xs:element",
                                      "xs" => XSD_NAMESPACE)
            declaration = elements.find do |element|
              element["name"] == root.name
            end
            return declaration if declaration
          end
          nil
        end

        def schema_documents(schema, visited = {})
          return [] if visited[schema.url]

          visited[schema.url] = true
          references = schema.xpath(
            "/xs:schema/xs:import | /xs:schema/xs:include",
            "xs" => XSD_NAMESPACE,
          )
          [schema] + references.flat_map do |reference|
            next [] unless reference["schemaLocation"]

            path = File.expand_path(reference["schemaLocation"],
                                    File.dirname(schema.url))
            schema_documents(read_xml(path), visited)
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
          unless klass.respond_to?(:from_xml)
            raise Error,
                  "Root #{instance.root.name} does not compile to an XML model"
          end

          # The complete XSD was validated before compilation. Generated-model
          # recursive validation does not preserve private register contexts.
          klass.from_xml(instance.to_xml, register: register_id)
        end

        def root_class(compiler, declaration, module_name)
          type = root_type(compiler, declaration)
          name = compiler.builder.all_models.keys.find do |key|
            ::Lutaml::Model::Utils.snake_case(key) == type.to_s
          end
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
