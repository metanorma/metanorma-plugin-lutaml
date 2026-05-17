require "bundler/setup"
require "asciidoctor"
require_relative "../lib/metanorma-plugin-lutaml"
require "rspec-html-matchers"

# Register lutaml blocks as first preprocessors in line in order
# to test properly with metanorma-standoc
Asciidoctor::Extensions.register do
  inline_macro Metanorma::Plugin::Lutaml::LutamlTableInlineMacro, :lutaml_table
  inline_macro Metanorma::Plugin::Lutaml::LutamlFigureInlineMacro,
               :lutaml_figure
  preprocessor Metanorma::Plugin::Lutaml::LutamlUmlDatamodelDescriptionPreprocessor # rubocop:disable Layout/LineLength
  preprocessor Metanorma::Plugin::Lutaml::LutamlEaXmiPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Json2TextPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Yaml2TextPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::Data2TextPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlXmiUmlPreprocessor
  preprocessor Metanorma::Plugin::Lutaml::LutamlXsdPreprocessor

  block_macro Metanorma::Plugin::Lutaml::LutamlDiagramBlockMacro
  block Metanorma::Plugin::Lutaml::LutamlDiagramBlock
  block_macro Metanorma::Plugin::Lutaml::LutamlEaDiagramBlockMacro
  block_macro Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlockMacro
  block Metanorma::Plugin::Lutaml::LutamlGmlDictionaryBlock
  block_macro Metanorma::Plugin::Lutaml::LutamlKlassTableBlockMacro
  block_macro Metanorma::Plugin::Lutaml::LutamlEnumTableBlockMacro
end

require "metanorma-standoc"
require "rspec/matchers"
require "metanorma-core"
require "metanorma/standoc"
require "xml-c14n"
require "canon"

Canon::Config.configure do |config|
  config.profile = :metanorma
end

Dir[File.expand_path("./support/**/**/*.rb", __dir__)].each do |f|
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

  config.before(:suite) do
    require "lutaml/converter/xmi_to_uml_generalization"
    require "lutaml/uml"
    require "lutaml/xmi"

    cache = Metanorma::Plugin::Lutaml::CacheRegistry.xmi_cache
    cache.clear

    fixtures_dir = File.expand_path("./fixtures/lutaml", __dir__)
    large_xmi_files = [
      File.join(
        fixtures_dir,
        "20240822_all_package_export_plus_new_tc211_gml.xmi",
      ),
      File.join(fixtures_dir, "plateau_all_packages_export.xmi"),
    ]

    large_xmi_files.each do |path|
      next unless File.exist?(path)

      cache.fetch(path)
    end
  end
end

BLANK_HDR = <<~"HDR".freeze
  <?xml version="1.0" encoding="UTF-8"?>
  <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="semantic" version="#{Metanorma::Standoc::VERSION}" flavor="standoc">
    <bibdata type="standard">
      <title language="en" type="main">Document title</title>
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
      <semantic-metadata>
          <stage-published>true</stage-published>
      </semantic-metadata>
      <presentation-metadata>
        <toc-heading-levels>2</toc-heading-levels>
        <html-toc-heading-levels>2</html-toc-heading-levels>
        <doc-toc-heading-levels>2</doc-toc-heading-levels>
        <pdf-toc-heading-levels>2</pdf-toc-heading-levels>
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
  xml.gsub("\\n", "").gsub(/>\s*/, ">").gsub(/\s*</, "<")
end

def xml_string_content(xml)
  strip_guid(Nokogiri::XML(xml).to_s)
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
  xml.gsub(/\ssrc="[^"]+"/, ' src="_"').gsub(/\sfilename="[^"]+"/,
                                             ' filename="_"')
end
