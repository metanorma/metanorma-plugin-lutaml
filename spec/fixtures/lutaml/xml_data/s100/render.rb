# frozen_string_literal: true

require "asciidoctor"
require "metanorma-standoc"
require "metanorma-plugin-lutaml"

Asciidoctor::Extensions.register do
  preprocessor Metanorma::Plugin::Lutaml::LutamlDataPreprocessor
end

# This standalone example intentionally streams the rendered document.
# rubocop:disable-next RSpec/Output
puts Asciidoctor.convert_file(
  File.join(__dir__, "catalogue.adoc"),
  backend: :standoc, header_footer: true, to_file: false, safe: :safe,
  agree_to_terms: true, attributes: ["nodoc"]
)
