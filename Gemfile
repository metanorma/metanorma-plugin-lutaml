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

# moxml requires leptris >= 1.9.386 (older bindings are rejected at
# load: Moxml::AdapterError). 1.9.39x ships every platform again,
# including x64-mingw-ucrt, so the old Windows-gap pin is gone.
gem "leptris", ">= 1.9.386"

# pre-release line pins (see metanorma release wave)
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "suma", github: "metanorma/suma", branch: "main"
# standoc main (>= 3.5.1.pre.alpha.2) floors metanorma-document at
# 0.5.2.pre.alpha.1 (SvgmapElement, metanorma-standoc#1303); main carries it
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"

# svg_conform 0.2.5's rubygems object is stale on some CDN edges (the
# re-pushed build carries a lens_core dependency that is not published);
# 0.2.4 is the last clean release and rides moxml ~> 0.5 (= satisfied by
# the 0.6 line). Lift when a clean 0.2.6 ships.
gem "svg_conform", "0.2.4"
