#!/usr/bin/env bash
# mpl#329 regression harness: build the trimmed p41min action_schema
# collection and fail on any svgmap image-resolution error. The released
# plugin builds this green since 0.7.57; the 0.7.55-0.7.56 lines fatal on
# action_schemaexpg1/2.svg with working-directory-relative probes.
set -euo pipefail
cd "$(dirname "$0")"
export BUNDLE_GEMFILE="$PWD/Gemfile"

bundle install --quiet

rm -f documents/p41min/document.xml
rm -rf site
log=$(mktemp)
trap 'rm -f "$log"' EXIT

bundle exec metanorma collection collection-p41min.yml > "$log" 2>&1 || {
  tail -40 "$log"
  echo "FAIL: the collection build did not complete"
  exit 1
}

if grep -qE "Image not found|Image specified" "$log"; then
  echo "FAIL: image errors in the build log:"
  grep -E "Image not found|Image specified" "$log" | sort -u | head
  exit 1
fi

echo "PASS: collection built with zero image errors"
