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

# pre-release line pins (see metanorma release wave)
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "suma", github: "metanorma/suma", branch: "main"
