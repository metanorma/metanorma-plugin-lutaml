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

gem "byebug"
gem "debug"
gem "equivalent-xml"
gem "html2doc", github: "metanorma/html2doc", branch: "fix/lutaml-model-0-8-dependencies"
gem "lutaml", github: "lutaml/lutaml", branch: "update/xsd_support_metanorma_plugin"
gem "lutaml-model", github: "lutaml/lutaml-model", branch: "fix/xsd-target-namespace-prefix"
gem "metanorma", github: "metanorma/metanorma", branch: "fix/lutaml-model-0-8-xml-adapter"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "fix/lutaml-model-0-8-dependencies"
gem "rake", "~> 13"
gem "rspec", "~> 3.6"
gem "rspec-html-matchers"
gem "rubocop", "~> 1.58"
gem "rubocop-performance", "~> 1.19"
gem "simplecov", "~> 0.15"
gem "timecop", "~> 0.9"
gem "vcr", "~> 6.1.0"
gem "webmock"
gem "xml-c14n"
