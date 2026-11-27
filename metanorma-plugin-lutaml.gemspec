lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require_relative "lib/metanorma/plugin/lutaml/version"

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
  # The `git ls-files -z` loads the files in the RubyGem that have been
  # added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match(%r{^(test|spec|features)/})
    end
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = Gem::Requirement.new(">= 3.3.0")

  spec.add_dependency "asciidoctor"
  # ceradoc-adoc >= 2.0.38 widened its parsanol floor to >= 1.3.123, < 2
  # (ceradoc#365), so the expressir 2.4.x chain co-resolves again.
  # Floors at the published latest lines of the family.
  spec.add_dependency "ceradoc", "~> 3.0.1"
  spec.add_dependency "ceradoc-adoc", "~> 2.0.38"
  spec.add_dependency "ceradoc-html", "~> 1.1.24"
  # >= 0.6.157: first release with the Qea::Rules layer and the shipped
  # ea/qea/rules/generalization.rb (0.6.149-0.6.156 are broken for the
  # diagram/Liquid-drops path — lutaml/ea#234, #246). Ea::Xmi.load/load_graph
  # (lutaml/ea#86): the partial-load API this gem calls.
  spec.add_dependency "ea", "~> 0.6.160"
  spec.add_dependency "expressir", "~> 2.5.0"
  spec.add_dependency "isodoc", ">= 3.5.0"
  spec.add_dependency "liquid", "~> 5"
  spec.add_dependency "lutaml-graphviz"
  spec.add_dependency "lutaml-jsonschema", "~> 0.1", ">= 0.1.29"
  # The LML language core ships inside lutaml-model (>= 0.8.188, the
  # lutaml-lml subsume); the retired lutaml-lml shim dependency drops.
  # `lutaml/lml` resolves from lutaml-model's tree with the same
  # require path.
  spec.add_dependency "lutaml-model", "~> 0.8.188"
  # >= 1.0.4: Lutaml::Uml::Value#initial (enum literal codes) — required by
  # ea >= 0.6.151+ which writes initial values during XMI parsing.
  spec.add_dependency "lutaml-uml", "~> 1.0", ">= 1.0.4"
  spec.add_dependency "ogc-gml", "~> 1.1"
  spec.metadata["rubygems_mfa_required"] = "true"
end
