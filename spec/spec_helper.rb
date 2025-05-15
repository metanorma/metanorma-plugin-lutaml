require "bundler/setup"
require "asciidoctor"
require "metanorma-plugin-lutaml"
require "rspec-html-matchers"

# Register lutaml blocks as first preprocessors in line in order
# to test properly with metanorma-standoc
Asciidoctor::Extensions.register do
  inline_macro Metanorma::Plugin::Lutaml::LutamlTableInlineMacro, :lutaml_table
  inline_macro Metanorma::Plugin::Lutaml::LutamlFigureInlineMacro,
               :lutaml_figure
  preprocessor Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlEaXmiPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Json2TextPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Yaml2TextPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Data2TextPreprocessor
end

Asciidoctor::Extensions.register do
  preprocessor Metanorma::Plugin::Lutaml::LutamlPreprocessor
  block_macro Metanorma::Plugin::Lutaml::LutamlDiagramBlockMacro
  block Metanorma::Plugin::Lutaml::LutamlDiagramBlock
  block_macro Metanorma::Plugin::Lutaml::LutamlEaDiagramBlockMacro
  block_macro Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlockMacro
  block Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlock
  block_macro Metanorma::Plugin::Lutaml::LutamlKlassTableBlockMacro
end

require "metanorma-standoc"
require "rspec/matchers"
require "equivalent-xml"
require "metanorma"
require "metanorma/standoc"
require "byebug"
require "xml-c14n"

Dir[File.expand_path("./support/**/**/*.rb", __dir__)].sort.each do |f|
  require f
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include RSpecHtmlMatchers

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

BLANK_HDR = <<~"HDR".freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor="standoc">
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
        <flavor>standoc</flavor>
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

def remove_xml_whitespaces(xml)
  xml.gsub(/\\n/, '').gsub(/>\s*/, ">").gsub(/\s*</, "<")
end

def xml_string_content(xml)
  strip_guid(Xml::C14n.format(Nokogiri::XML(xml).to_s))
end

def metanorma_convert(input)
  Asciidoctor.convert(input, backend: :standoc, header_footer: true,
                             agree_to_terms: true, to_file: false, safe: :safe,
                             attributes: ["nodoc", "stem", "xrefstyle=short",
                                          "docfile=test.adoc",
                                          "output_dir="])
end

def metanorma_process(input)
  Metanorma::Input::Asciidoc
    .new
    .process(input, "test.adoc", :standoc)
end

def fixtures_path(path)
  File.join(File.expand_path("./fixtures/lutaml", __dir__), path)
end

def datastruct_fixtures_path(path)
  File.join(
    File.expand_path("../spec/fixtures/lutaml/datastruct", __dir__), path
  )
end

def strip_src(xml)
  xml.gsub(/\ssrc="[^"]+"/, ' src="_"')
end
