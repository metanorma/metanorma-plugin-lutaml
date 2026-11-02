# p41min collection harness

End-to-end regression harness for metanorma-plugin-lutaml#329: svgmap
`image::` paths must resolve when a collection build compiles its members
(working-directory asset resolution), not only in single-document
compiles.

## Provenance

`documents/p41min` is a trimmed part-41 ISO 10303 collection; the schema
assets under `schemas/resources/` and `plain_schemas/resources/` come
from metanorma/iso-10303 (main at `22bf8b3729`). The `schema_docs/*/`
HTML files are attachment stubs; the harness exercises build mechanics,
not schema documentation content.

## Usage

```sh
./run.sh
```

The script resolves its own bundle (`Gemfile`, released pins), builds
`collection-p41min.yml` with the metanorma CLI, and fails on any
`Image not found` / `Image specified` entry or incomplete build.

## Signatures

- PASS (0.7.57+): build completes; zero image errors; figures embed as
  data URIs.
- FAIL (0.7.55-0.7.56): parse-stage STANDOC_44 fatal
  `Image not found: <cwd>/../../schemas/resources/action_schema/action_schemaexpg{1,2}.svg`,
  exit 1.

To test an unreleased plugin revision, temporarily point the Gemfile's
`metanorma-plugin-lutaml` at it and remove the override before
committing — no path gems in committed Gemfiles.
