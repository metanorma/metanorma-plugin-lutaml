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

# leptris 1.9.367.0 is the highest match for standoc's '~> 1.9.361' but
# publishes only linux prebuilds plus a ruby gem with no vendored
# libleptris; windows-latest falls back to that ruby gem and dies on
# require "metanorma-standoc". 1.9.361.1 is the latest that still ships
# x64-mingw-ucrt (and darwin) binaries. Lift once upstream packs Windows
# again.
gem "leptris", "~> 1.9.361.1"

# pre-release line pins (see metanorma release wave)
gem "isodoc", github: "metanorma/isodoc", branch: "main"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "main"
gem "suma", github: "metanorma/suma", branch: "main"
# standoc main's block_attributes reference
# Metanorma::Document::Components::AncillaryBlocks::SvgmapElement, which
# the released metanorma-document 0.5.1 predates; ref-pinned to the
# document main tree the suite is green against
gem "metanorma-document", github: "metanorma/metanorma-document",
                          ref: "ca4eb4b26f7ab0d2994a4710d0cf158607a832b4"
