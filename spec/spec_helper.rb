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

require "metanorma-standoc"
require "rspec/matchers"
require "equivalent-xml"

Dir[File.expand_path("./support/**/**/*.rb", __dir__)].each { |f| require f }

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
  <language>en</language><script>Latn</script><status><stage>published</stage></status><copyright><from>#{Date.today.year}</from></copyright><ext><doctype>standard</doctype></ext></bibdata><metanorma-extension><presentation-metadata><name>TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>HTML TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>DOC TOC Heading Levels</name><value>2</value></presentation-metadata><presentation-metadata><name>PDF TOC Heading Levels</name><value>2</value></presentation-metadata></metanorma-extension>
HDR

def strip_guid(xml)
  xml
    .gsub(%r{ id="_[^"]+"}, ' id="_"')
    .gsub(%r{ target="_[^"]+"}, ' target="_"')
end

def xml_string_content(xml)
  strip_guid(xmlpp(Nokogiri::XML(xml).to_s))
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

XSL = Nokogiri::XSLT(<<~XSL.freeze)
  <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output method="xml" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>
    <xsl:template match="/">
      <xsl:copy-of select="."/>
    </xsl:template>
  </xsl:stylesheet>
XSL

def xmlpp(xml)
  c = HTMLEntities.new
  xml &&= xml.split(/(&\S+?;)/).map do |n|
    if /^&\S+?;$/.match?(n)
      c.encode(c.decode(n), :hexadecimal)
    else n
    end
  end.join
  XSL.transform(Nokogiri::XML(xml, &:noblanks))
    .to_xml(indent: 2, encoding: "UTF-8")
    .gsub(%r{<fetched>[^<]+</fetched>}, "<fetched/>")
    .gsub(%r{ schema-version="[^"]+"}, "")
end

