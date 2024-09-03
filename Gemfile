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

gem "lutaml", github: "lutaml/lutaml", branch: "render-klass-table"
# gem "lutaml", path: "../../lutaml/lutaml"

gem "ogc-gml", github: "lutaml/ogc-gml"
