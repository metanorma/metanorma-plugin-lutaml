# XML/XSD instance binding — implementation plan for #389

Status: implemented and verified locally against a candidate dependency;
remote qualification pending. Assessed 2026-11-23.

[Execution cards](CARDS.md) · [Mandatory branch, PR and testing rules](RULES.md)

The shared base is `grind/389-xml-data-binding`. All implementation PRs
target that branch. Automation must never merge or push to main; main merges
remain with the repository owners.
All project paths below are relative to `metanorma/metanorma-plugin-lutaml`
unless another repository is named. Proposed paths are labelled explicitly.

## Outcome and controlling requirements

[Issue #389](https://github.com/metanorma/metanorma-plugin-lutaml/issues/389)
requires a document build to read an XSD, use its typing to read XML instance
data, and expose that instance through Liquid. The driving case is JCOMM
S-411 edition 1.1.0: `S100FC.xsd` plus `S411FC.xml`, root `S100FC:Catalog`.
The document must generate one clause per FeatureType with nested attribute
and enumerant content by ordinary Liquid iteration at render time.

The five completion criteria are:

1. **C1 — Schema binding:** read the XSD and its namespace dependencies;
   preserve element/type mappings, XML attributes, sequences, cardinality,
   and enumeration restrictions needed by the corpus.
2. **C2 — Instance loading:** parse the XML against those generated mappings;
   preserve qualified names, values, collection multiplicity, and nesting.
3. **C3 — Document rendering:** accept both files in a macro, expose typed
   instances through `to_liquid`, and emit actual Metanorma clauses with
   complete nested data.
4. **C4 — Reuse and compatibility:** reuse existing XSD/model/Liquid machinery;
   preserve schema documentation, existing data formats, providers, and GML.
5. **C5 — Delivery example:** document the contract and demonstrate it with the
   exact 2014-edition S-100 feature catalogue and its schema closure.

Related requirements:

- [metanorma#444](https://github.com/metanorma/metanorma/issues/444): the
  model/instance/Liquid foundation is delivered; XML/XSD is the additional slice.
  CSV/Excel and broader LML work remain outside this issue.
- [plugin#353](https://github.com/metanorma/metanorma-plugin-lutaml/issues/353):
  generic semantic-XML embedding and presentation-XML rendering are broader
  work. Share the typed-model boundary; do not make that whole contract a
  prerequisite for this render-time data feature.
- [mn-samples-wmo#3](https://github.com/metanorma/mn-samples-wmo/issues/3):
  consumes this feature for catalogue population. It specifies the November 30
  prerelease cut and December 4 alpha. Its generated-AsciiDoc fallback is a
  downstream release contingency; using it does not complete C1–C5.

Issue #389 has no comments at assessment. No conflicting replacement
requirement was found in the linked issue discussions.

## Evidence and current behavior

Source baseline: plugin main
[`309a3c7`](https://github.com/metanorma/metanorma-plugin-lutaml/tree/309a3c770f6ccfb9bb818cf47c2103d61f4e2ae8),
version 0.7.81, dated 2026-11-20. Rebase the implementation onto current main
and inspect any intervening changes before editing.

| Component | Observed contract | Consequence |
| --- | --- | --- |
| `lib/metanorma/plugin/lutaml/lutaml_xsd_preprocessor.rb`, `LutamlXsdPreprocessor#parse_xsd_file` | Calls `Lutaml::Xml::Schema::Xsd.parse(content, location:)`, renders the schema's drop; supports block/direct forms and default templates | Useful schema-reading precedent; does not load catalogue instances |
| `lib/metanorma/plugin/lutaml/lutaml_data_preprocessor.rb`, `LutamlDataPreprocessor` | Compiles LML definitions; accepts `.lml`, YAML, JSON instances; supports providers, default context, inline/JSON options and includes | Best existing entry point for an additive XSD/XML pair |
| `lib/metanorma/plugin/lutaml/content.rb`, `Content#load_content_from_file` | `data2text` selects JSON or YAML | Adding XML here alone would lose the required schema binding |
| `lib/metanorma/plugin/lutaml/lutaml_gml_dictionary_base.rb`, `#get_gml_dictionary` | Uses the fixed `Ogc::Gml::Dictionary.from_xml` model and specialized drops | XML/Liquid precedent, not a generic XSD instance binder |
| `metanorma-plugin-lutaml.gemspec` | Requires Ruby >= 3.0 and `lutaml-model ~> 0.8.156` | Start with supported dependency APIs; avoid an unnecessary dependency upgrade |
| `Rakefile`, `.github/workflows/rake.yml` | Default `rake` runs `fast`; XMI sets have separate tasks; CI calls the reusable rake workflow | Default rake is not the entire spec collection |

At the admitted dependency floor,
[`XmlCompiler.to_models`](https://github.com/lutaml/lutaml-model/blob/v0.8.156/lib/lutaml/model/schema/xml_compiler.rb)
parses XSD internally using `Lutaml::Xml::Schema::Xsd.parse`, accepts
`location`, `module_namespace`, `register_id`, and `load_classes` options,
and returns generated source entries when not creating files. Loading classes
is a side effect; the return value must not be treated as a class registry.
The compiler has mutable module-level builder state.
At this version, a named type such as `CatalogType` produces that type's
class; a global `Catalog` element referencing it is separate metadata, not
a guaranteed `Catalog` class alias. An anonymous root complex type follows
a different generated naming path. A Ruby `module_namespace` and a distinct
model `register_id` address different parts of isolation.
Its [compiler specs](https://github.com/lutaml/lutaml-model/blob/v0.8.156/spec/lutaml/xml/schema/compiler_spec.rb)
exercise generated models with `from_xml` and imported-schema references.
Serializable models include
[`Liquefiable`](https://github.com/lutaml/lutaml-model/blob/v0.8.156/lib/lutaml/model/liquefiable.rb),
which exposes attributes and nested values to Liquid.

An executable synthetic probe now confirms imported-schema compilation, named
and anonymous root hydration, isolated modules and plain-Liquid iteration.
The compiler requires explicit namespace mapping to avoid empty collections.
Model validation catches minOccurs violations but misses a required XSD
attribute in the probe; the implementation therefore uses strict Nokogiri
XSD validation before typed hydration, with an explicit dependency floor.
Duplicate generated-model validation is omitted because recursive validation
drops private registry context; the source schema remains fully validated. This establishes
an existing route, not S-100 compatibility. The real catalogue now passes typed binding, rendering and rebuild/isolation
checks against the candidate dependency identified in the card board.
The separate `lutaml-xsd` gem's `Lutaml::Xsd.parse` schema AST API is not a
replacement for the compiler used by the admitted `lutaml-model` version.

The published `mn-samples-wmo` main at
[`cf72c63`](https://github.com/metanorma/mn-samples-wmo/tree/cf72c63fad87cefd4af714b329ddc20563cd72df)
contains only its README. The issue describes verified XML/schema inputs,
but those files were unavailable in that revision. PR #2 is open and adds
the reference PDF; its file list does not contain the catalogue/schema set.
The original schema and XML have since been acquired from the 2014 distribution
at `https://www.bsis-ice.de/S411/Schemas/`. Recursive dependency acquisition and an independent catalogue inventory are complete. The card board records
the verified real-corpus candidate and outstanding delivery checks.

## Implemented candidate contract

Extend the existing macro rather than registering another preprocessor:

```asciidoc
[lutaml_data,schemas/S100FC.xsd,data/S411FC.xml,fc]
----
...plain Liquid over the typed catalogue...
----
```

The candidate implements this syntax. Keep `lutaml_xsd` focused on
schema documentation. For the XML branch:

- The definition is an explicit `.xsd` path and the instance is an explicit
  `.xml` path. Require the pair; fail clearly on a missing instance or an
  unsupported cross-format pairing before invoking an unrelated parser.
- Resolve input paths with `Utils.relative_file_path`, relative to the
  document's `docfile`. Resolve XSD imports/includes relative to the schema
  directory by default, with the existing-style `location` option when needed.
  Confirm the compiler's base-path behavior with nested relative imports.
- Preserve the current `context_name` default (`lutaml_data`), JSON/inline
  options, and `include_path` search behavior.
- XML context shape: `fc.Catalog`, where `Catalog` is the XML root
  local name and its value is a generated model/drop. Bind by the root's
  expanded QName (namespace URI plus local name), not its prefix spelling or
  an assumed Ruby class name. Reject a root absent from the schema. Map the
  root to its declared type, including anonymous-type roots.
- Publish actual generated attribute names and the verified Liquid traversal
  in the worked example. The conceptual traversal in #389 is not proof of
  literal property names or that all catalogue relationships are inline.
  If the real catalogue uses references, resolve them through typed data in
  the example or binding layer as appropriate; do not silently omit them.
- Pass XML instances to Liquid through the existing model `to_liquid`
  behavior. Preserve the current LML/YAML/JSON and provider branches, including
  their existing wrapper keys and values.
- Use dependency-supported validation for the required facets; establish which
  restrictions are checked during coercion versus explicit validation. Invalid
  enum values/cardinality in the supported binding must produce a diagnostic,
  not missing rendered content. Do not claim complete XSD validation unless
  verified; report unsupported schema constructs explicitly.
- Errors identify the definition/instance path and relevant root or construct,
  retain the underlying cause, and use `log_block_failure` before raising.
  A rendering error must not produce an apparently successful empty catalogue.
- Runtime compilation must not write generated model files into the corpus.
  Isolate generated constants and registries between independent schemas and
  document renders. Do not reset the process-wide default registry or XML
  adapter. Serialize compilation around the dependency's shared builder if
  concurrent calls can reach it; verify the selected dependency version's
  behavior. Give each binding an isolated module/register and a tested lifetime
  that keeps live instances usable without accumulating abandoned registrations.
  Avoid a global instance-data cache. Start with no cross-document
  compiled-model cache; add one only for a demonstrated need with correct
  schema/import identity and invalidation.

Exclude universal XML import, new schema-authoring syntax, generic #353
semantic embedding, manually maintained S-411 model classes, corpus prose
transcription, and unrelated preprocessor refactoring.

## Ordered work and effort

Effort is focused engineering time, including tests and diagnosis. One primary
engineer owns integration. Entries are estimates, not time already spent.

| ID / status | Work, exact targets, and expected result | Dependency | Effort |
| --- | --- | --- | --- |
| T0 — inputs acquired; probes executed | Obtain and pin the exact 1.1.0 `S411FC.xml`, `S100FC.xsd`, and transitive imports/includes. Record source revision, provenance, namespace map and independently extracted feature/attribute/enumerant counts. Use proposed `spec/fixtures/lutaml/xml_data/s100/` for redistributable fixtures. Compile/load the schema, select the real root class, parse the instance and render a minimal plain-Liquid loop. Determine root mapping, references, generated names, validation coverage and registry lifecycle. Add a meaningful small reproducer for any gap. | Exact corpus distribution | 3–5 h |
| T1 — generic binding implemented | Add proposed `lib/metanorma/plugin/lutaml/xml_data_loader.rb`, `XmlDataLoader#load` returning a string-keyed root wrapper containing typed instance data. Call the supported compiler, resolve the root QName/type, hydrate and validate the instance. Own generated module/register lifecycle; handle imports and actionable errors. Add proposed `spec/metanorma/plugin/lutaml/xml_data_loader_spec.rb` and small fixtures under proposed `spec/fixtures/lutaml/xml_data/`. | T0 proves a usable compiler route | 5–9 h |
| T2 — implemented | Update `LutamlDataPreprocessor#data_file?`, `#parse_header`, and `#render_data_template` to dispatch the XSD/XML pair into the loader. Preserve `#render_block` provider handling and existing format loading. Add an autoload in `lib/metanorma-plugin-lutaml.rb`. Extend `spec/metanorma/plugin/lutaml/lutaml_data_preprocessor_spec.rb` for pair parsing, default/custom contexts, options/includes, paths and positive clause assertions. No standoc registration change should be necessary. | T1 loader return contract | 4–6 h |
| T3 — local acceptance verified | In proposed `spec/metanorma/plugin/lutaml/xml_data_s100_spec.rb`, render the real S-411 catalogue through the normal Metanorma test pipeline. Assert every expected FeatureType clause and required nested attribute/enumerant content against the independent T0 inventory; test a deliberate value change and repeated documents. Add the executable example under proposed `spec/fixtures/lutaml/xml_data/s100/catalogue.adoc` with a Liquid template as needed. Identify any corpus reference-resolution work here explicitly. | T0 inventory, T1 and T2 | 5–8 h |
| T4 — implemented | Extend `docs/usages/lutaml-data.adoc` with syntax, context shape, imports, validation/error behavior, tested S-100 traversal and a self-contained worked example. Add a cross-link in `docs/usages/lutaml-xsd.adoc` explaining schema versus instance views; update `README.adoc`. Introduce a gemspec floor only if a concrete upstream fix requires it. | Public contract settled by T0–T3 | 3–4 h |
| T5 — active; CI/publication pending | Run affected regression specs and changed-file lint; perform one final review of the whole change and fix findings. Obtain required CI for the final revision. Run the downstream suma integration suite against the branch gem, and demonstrate WMO consumer rendering with that exact dependency. Record revisions, commands, results and remaining acceptance. | T1–T4; available consumer bundle | 4–6 h |

Base effort: **24–38 hours**. Separate bounded contingency: **6–10 hours**
for schema/import/registry fixes and integration diagnosis. Planning allowance:
**30–48 hours**, or **5–8 working days at six focused hours/day**. This includes
the T0 investigation and validation work, excludes the already completed
assessment, and does not include waiting for files, dependency releases,
maintainer responses or CI queues. It does not fund a new compiler subsystem.

Confidence is moderate for the additive plugin work and low for the exact
S-100 binding until T0 passes. If T0 finds a required unsupported construct,
create a minimal upstream reproducer and revised estimate before committing
to the remaining date; do not conceal it inside contingency.

The effort estimate is not an elapsed schedule. Execution now follows the
parallel [cards](CARDS.md): corpus and compiler work overlap macro integration;
loader implementation follows a usable compiler result; the worked example,
documentation and scripted verification overlap as their inputs become ready.
The completed execution checkpoint and remaining critical path are recorded
in the card board. Calendar-day forecasts from the serial planning assumption
are superseded by the observed local results and external delivery blockers.

## Acceptance and runnable verification

Full implementation checks below remain planned unless the card board records
a specific completed command. Proposed spec paths
become runnable when their work items land. Use a matching supported Ruby and
Bundler; Ruby 3.4 is a practical local choice, while preserving the declared
Ruby floor and the repository CI matrix.

| Criteria / work | Observable assertions |
| --- | --- |
| C1 / T0–T1 | Imports and nested includes resolve from schema locations with a different working directory; namespace-colliding names remain distinct; XML attribute versus child-element mappings, repeated items, ordering, optional absence, zero/false values and restriction facets are exercised in small fixtures |
| C2 / T1 | Real and synthetic roots select their declared types; named and anonymous root types work; changing namespace prefixes does not change data; unknown root, malformed XML/XSD, missing input/import and invalid supported restrictions fail with useful paths |
| C2, C4 / T1, T3 | Two schemas with overlapping Ruby/local names and multiple documents in one process retain independent model data; repeated blocks do not retain previous instances or mutate another caller's registry/adapter |
| C3 / T2–T3 | A plain `{% for %}` emits a real clause for each expected feature in Metanorma XML; required names/IDs/descriptions/attribute values/enumerants are present in the correct clauses; all expected source inventory entries are accounted for, not just total counts |
| C3 / T3 | Modifying one XML fixture value changes its rendered clause on rebuild; source XML and XSD remain unmodified; the example invokes no external AsciiDoc generator; includes and relative paths work through the actual consumer pipeline |
| C4 / T2, T5 | Existing LML single/two-file, YAML, JSON, provider, context/options and include tests stay green; XSD block/direct/default-template and GML output assertions remain green |
| C5 / T3–T5 | Example uses the exact 2014/1.1.0 inputs; pin/hashes and expected inventory are recorded; docs reproduce the proven field names; branch gem renders the WMO consumer successfully and passes suma's required integration suite |

Run from the plugin checkout:

```sh
# Binding, rendering, and compatibility checks after implementation:
bundle exec rspec \
  spec/metanorma/plugin/lutaml/xml_data_loader_spec.rb \
  spec/metanorma/plugin/lutaml/xml_data_s100_spec.rb \
  spec/metanorma/plugin/lutaml/lutaml_data_preprocessor_spec.rb \
  spec/metanorma/plugin/lutaml/data_providers_spec.rb \
  spec/metanorma/plugin/lutaml/macros_data2text_spec.rb \
  spec/metanorma/plugin/lutaml/macros_yaml2text_spec.rb \
  spec/metanorma/plugin/lutaml/macros_json2text_spec.rb \
  spec/metanorma/plugin/lutaml/lutaml_xsd_preprocessor_spec.rb \
  spec/metanorma/plugin/lutaml/lutaml_gml_dictionary_block_spec.rb \
  spec/metanorma/plugin/lutaml/lutaml_gml_dictionary_block_macro_spec.rb

# Scope to actual changed Ruby paths, including new specs:
git diff --check
bundle exec rubocop lib/metanorma/plugin/lutaml/xml_data_loader.rb \
  lib/metanorma/plugin/lutaml/lutaml_data_preprocessor.rb \
  lib/metanorma-plugin-lutaml.rb \
  spec/metanorma/plugin/lutaml/xml_data_loader_spec.rb \
  spec/metanorma/plugin/lutaml/xml_data_s100_spec.rb \
  spec/metanorma/plugin/lutaml/lutaml_data_preprocessor_spec.rb

# Repository default gate (fast set), when ready for final integration:
bundle exec rake
```

Expected outcomes: all selected specs pass, lint has no new offenses, and no
whitespace errors. Establish the new behavior's failing case before its fix;
rerun affected checks after corrections. CI must finish green at the final
head. Do not describe the default fast set as the complete suite. Run separate
XMI tasks only if shared changes create a concrete cross-component risk or
the final CI contract requires them.

`CLAUDE.md` requires a consumer check before publishing a gem: install the
branch gem into a suma bundle and run, from the suma checkout:

```sh
bundle exec rspec spec/suma/cli/build_integration_spec.rb
```

Expected exit status: zero, using the candidate gem. For WMO,
`mn-samples-wmo#3` proposes `make render` and `make validate`, but those targets
do not exist in the published baseline. Before executing them, locate the
populated corpus branch's `Makefile`, confirm its dependency selection and
actual WMO document entry point, and record the exact commands. Completion
means render success plus feature-content assertions in the built output;
prose parity work in #3 is outside the plugin's scope.

## Execution and finalization workflow

1. **Start with T0 and an explicit decision.** Pin the inputs and dependency
   revisions, run the schema-to-instance-to-Liquid probe, and record exact
   observations. If the route works, freeze the public syntax, QName/root
   wrapper and lifecycle contract. If it fails, isolate the required upstream
   correction and its completion condition: released/admitted dependency plus
   a passing real-catalogue probe. The present gemspec admits patch releases
   from 0.8.156; verify the actual selected version as well as the floor.
2. **Implement the complete binding.** T1 owns loading and model isolation;
   T2 owns macro integration. These share a narrow return contract. Once T0
   fixes that interface, T2 tests/scaffolding and T3's independent expected
   inventory/template can proceed alongside T1. Do not duplicate ownership of
   `lutaml_data_preprocessor.rb` or make several competing macro designs.
3. **Integrate early against the real catalogue.** Complete T3 before treating
   generic fixtures as evidence of S-100 support. A demonstrated compiler gap
   is repaired upstream with its reproducer; plugin code stays responsible for
   dispatch, root binding, instance exposure, rendering and diagnostics.
4. **Complete docs and one final whole-change review.** Check issue criteria,
   imports/QNames, model isolation, output completeness, old formats and the
   final dependency combination. Fix reachable defects and rerun affected
   checks; avoid additional routine review cycles.
5. **Prepare the two bounded implementation PRs.** PR 1 carries the complete
   typed XML binding and macro integration; PR 2 carries real-corpus acceptance,
   the worked example and usage documentation. Both target
   `grind/389-xml-data-binding`. Follow the size, visibility and check rules in
   [RULES.md](RULES.md). Keep a required upstream fix separately reviewable and
   order the dependency before consuming it. Confirm final-head checks before
   base-branch integration. Main merges remain owner-controlled.
6. **Verify delivery in the consumer.** Test the candidate branch gem before
   release; after normal release, confirm the WMO bundle selects the containing
   version, renders the same inventory, and records the exact revisions. Update
   downstream dependency status only when that is demonstrated. Plugin merge,
   gem publication and downstream adoption are separate milestones.
7. **Close acceptance with evidence.** C1–C5, focused checks, final CI and
   consumer proof must all be accounted for. Keep the issue open/partial if the
   alpha ships the generated-source contingency. No acceptance criterion is
   waived to meet the prerelease date.

## Progress and handoff

The [card board](CARDS.md#current-board-and-forecast) is the execution progress
record; it replaces the original serial milestone table. Update completed
checks with exact revisions, bundle identity, logs and remaining gaps there.

An isolated local installed-gem bundle resolves using Ruby 3.4.8. It is
separate from the canonical Gemfile's git dependencies, so required CI and
consumer evidence remain outstanding. Generic loader, macro and preservation
tests pass. A separate candidate dependency corrects the reproduced ID/IDREF
compiler defect; the real catalogue is being checked against that revision. Remote publication is blocked by the execution profile: network access is
restricted and sandbox-exempt commands are disabled. No remote branch or PR
is claimed until a successful server response is verified.

Next actions: restore remote visibility and obtain canonical final-head CI;
coordinate the ten pre-existing default-suite failures that block the gate.
The local candidate passes the real-catalogue example and WMO-taste XML smoke
check. See the ownership table before editing any file.
