# frozen_string_literal: true

module Metanorma
  module Plugin
    module Lutaml
      module XmiConfig
        def parse_yaml_config_file(document, file_path)
          return Metanorma::Plugin::Lutaml::Config::Root.new if file_path.nil?

          relative_file_path = Utils.relative_file_path(document, file_path)

          Metanorma::Plugin::Lutaml::Config::Root.from_yaml(
            File.read(relative_file_path, encoding: "UTF-8"),
          )
        end

        def get_guidance(document, guidance_config)
          return unless guidance_config

          guidance_yaml = Utils.relative_file_path(document, guidance_config)
          guidance = Metanorma::Plugin::Lutaml::Config::Guidance.from_yaml(
            File.read(guidance_yaml, encoding: "UTF-8"),
          )
          guidance.to_yaml_hash
        end

        def config_entity_regexp(entity)
          additional_sym = ".*" if /\*$/.match?(entity)
          %r{^#{Regexp.escape(entity.delete('*'))}#{additional_sym}$}
        end
      end
    end
  end
end
