# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      # Registry of Ruby data providers that `lutaml_data` blocks can query.
      #
      # A provider gem registers a factory under a name:
      #
      #   Metanorma::Plugin::Lutaml::DataProviders.register("ituob") do
      #     Ituob::Provider.new
      #   end
      #
      # and ships that call in
      # `lib/metanorma/plugin/lutaml/data_providers/<name>.rb`, which is
      # required on first use of an unregistered name.
      #
      # The provider object lists the queries a document may call in
      # `lutaml_data_queries`; each query takes keyword arguments and
      # returns lutaml-model objects, which reach Liquid unconverted.
      module DataProviders
        class Error < StandardError; end

        NAME_PATTERN = /\A[a-z0-9_]+\z/
        DISCOVERY_PATH = "metanorma/plugin/lutaml/data_providers"

        @factories = {}
        @providers = {}

        class << self
          def register(name, &factory)
            name = validate_name(name)
            unless factory
              raise ArgumentError, "provider `#{name}` needs a factory"
            end

            @factories[name] = factory
            @providers.delete(name)
          end

          def unregister(name)
            @factories.delete(name.to_s)
            @providers.delete(name.to_s)
          end

          def query(name, query_name, arguments = {})
            provider = fetch(name)
            query_name = query_name.to_s
            unless allowed_queries(provider).include?(query_name)
              raise Error, "provider `#{name}` has no query `#{query_name}`"
            end

            provider.public_send(query_name,
                                 **arguments.transform_keys(&:to_sym))
          end

          def fetch(name)
            name = validate_name(name)
            discover(name) unless @factories.key?(name)
            factory = @factories.fetch(name) do
              raise Error, "no LutaML data provider named `#{name}`"
            end
            @providers[name] ||= factory.call
          end

          private

          def validate_name(name)
            name = name.to_s
            return name if NAME_PATTERN.match?(name)

            raise Error, "invalid LutaML data provider name `#{name}`"
          end

          def discover(name)
            Gem.find_files("#{DISCOVERY_PATH}/#{name}.rb").each do |path|
              require path
            end
          end

          def allowed_queries(provider)
            unless provider.respond_to?(:lutaml_data_queries)
              raise Error, "provider #{provider.class} does not declare " \
                           "`lutaml_data_queries`"
            end

            provider.lutaml_data_queries.map(&:to_s)
          end
        end
      end
    end
  end
end
