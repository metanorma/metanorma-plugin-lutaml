require "bundler/setup"
require "asciidoctor"
require "metanorma-plugin-lutaml"

# Register lutaml blocks as first preprocessors in line in order
# to test properly with metanorma-standoc
Asciidoctor::Extensions.register do
  inline_macro Metanorma::Plugin::Lutaml::LutamlTableInlineMacro, :lutaml_table
  inline_macro Metanorma::Plugin::Lutaml::LutamlFigureInlineMacro,
               :lutaml_figure
  preprocessor Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor
end

Asciidoctor::Extensions.register do
  preprocessor Metanorma::Plugin::Lutaml::LutamlPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlUmlAttributesTablePreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlUmlClassPreprocessor
  block_macro Metanorma::Plugin::Lutaml::LutamlDiagramBlockMacro
  block Metanorma::Plugin::Lutaml::LutamlDiagramBlock
end

require "metanorma-standoc"
require "rspec/matchers"
require "equivalent-xml"
require "xml-c14n"

Dir[File.expand_path("./support/**/**/*.rb", __dir__)].sort.each do |f|
  require f
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

BLANK_HDR = <<~"HDR".freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <standard-document xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}">
    <bibdata type="standard">
      <title language="en" format="text/plain">Document title</title>
      <language>en</language>
      <script>Latn</script>
      <status>
        <stage>published</stage>
      </status>
      <copyright>
        <from>#{Date.today.year}</from>
      </copyright>
      <ext>
        <doctype>standard</doctype>
      </ext>
    </bibdata>
    <metanorma-extension>
      <presentation-metadata>
        <name>TOC Heading Levels</name>
        <value>2</value>
      </presentation-metadata>
      <presentation-metadata>
        <name>HTML TOC Heading Levels</name>
        <value>2</value>
      </presentation-metadata>
      <presentation-metadata>
        <name>DOC TOC Heading Levels</name>
        <value>2</value>
      </presentation-metadata>
      <presentation-metadata>
        <name>PDF TOC Heading Levels</name>
        <value>2</value>
      </presentation-metadata>
    </metanorma-extension>
HDR

def strip_guid(xml)
  xml
    .gsub(%r{ id="_[^"]+"}, ' id="_"')
    .gsub(%r{ target="_[^"]+"}, ' target="_"')
    .gsub(%r{<fetched>[^<]+</fetched>}, "<fetched/>")
    .gsub(%r{ schema-version="[^"]+"}, "")
end

def xml_string_content(xml)
  strip_guid(Xml::C14n.format(Nokogiri::XML(xml).to_s))
end

def metanorma_process(input)
  Asciidoctor.convert(input, backend: :standoc, header_footer: true,
                             agree_to_terms: true, to_file: false, safe: :safe,
                             attributes: ["nodoc", "stem", "xrefstyle=short",
                                          "docfile=test.adoc",
                                          "output_dir="])
end

def fixtures_path(path)
  File.join(File.expand_path("./fixtures/lutaml", __dir__), path)
end

def strip_src(xml)
  xml.gsub(/\ssrc="[^"]+"/, ' src="_"')
end

