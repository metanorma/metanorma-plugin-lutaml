Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

gemspec

begin
  eval_gemfile("Gemfile.devel")
rescue StandardError
  nil
end

gem "canon"
gem "html2doc", github: "metanorma/html2doc", branch: "main"
gem "metanorma", github: "metanorma/metanorma", branch: "main"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "rake"
gem "rspec"
gem "rspec-html-matchers"
gem "rubocop"
gem "rubocop-performance"
gem "rubocop-rake"
gem "rubocop-rspec"
gem "simplecov"
gem "timecop"
gem "vcr"
gem "webmock"
# standoc main's block_attributes reference
# Metanorma::Document::Components::AncillaryBlocks::SvgmapElement, which
# the released metanorma-document 0.5.1 predates; pin document main
gem "metanorma-document", github: "metanorma/metanorma-document", ref: "ca4eb4b26f7ab0d2994a4710d0cf158607a832b4"
