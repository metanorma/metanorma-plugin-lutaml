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

gem "expressir", github: "lutaml/expressir", branch: "rt-lutaml-model"
gem "lutaml-model", github: "lutaml/lutaml-model", branch: "main"