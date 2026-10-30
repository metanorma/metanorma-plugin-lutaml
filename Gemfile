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

# moxml 0.5.174+ refuses leptris older than 1.9.386 and falls back to
# nokogiri, which breaks require "metanorma-standoc". 1.9.394.0 ships
# x64-mingw-ucrt binaries again, so the old Windows pin is no longer needed.
gem "leptris", ">= 1.9.386"

# pre-release line pins (see metanorma release wave)
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "suma", github: "metanorma/suma", branch: "main"
# standoc main (>= 3.5.1.pre.alpha.2) floors metanorma-document at
# 0.5.2.pre.alpha.1 (SvgmapElement, metanorma-standoc#1303); main carries it
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"
