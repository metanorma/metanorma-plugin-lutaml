lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "metanorma/plugin/lutaml/version"

Gem::Specification.new do |spec|
  spec.name          = "metanorma-plugin-lutaml"
  spec.version       = Metanorma::Plugin::Lutaml::VERSION
  spec.authors       = ["Ribose Inc."]
  spec.email         = ["open.source@ribose.com"]

  spec.summary       = "Metanorma plugin for LutaML"
  spec.description   = "Metanorma plugin for LutaML"

  spec.homepage      = "https://github.com/metanorma/metanorma-plugin-lutaml"
  spec.license       = "BSD-2-Clause"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7.0" # rubocop:disable Gemspec/RequiredRubyVersion

  spec.add_dependency "asciidoctor"
  spec.add_dependency "coradoc", "~> 1.1.1"
  spec.add_dependency "expressir", "~> 2.1.13"
  spec.add_dependency "isodoc"
  spec.add_dependency "liquid"
  spec.add_dependency "lutaml", "~> 0.9.32"
  spec.add_dependency "ogc-gml", "~>1.0.0"
  spec.add_dependency "relaton-cli"

  spec.add_development_dependency "byebug"
  spec.add_development_dependency "equivalent-xml"
  spec.add_development_dependency "metanorma"
  spec.add_development_dependency "metanorma-standoc"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "rubocop", "~> 1.58"
  spec.add_development_dependency "rubocop-performance", "~> 1.19"
  spec.add_development_dependency "simplecov", "~> 0.15"
  spec.add_development_dependency "timecop", "~> 0.9"
  spec.add_development_dependency "vcr", "~> 6.1.0"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "xml-c14n"
  spec.metadata["rubygems_mfa_required"] = "false"
end
