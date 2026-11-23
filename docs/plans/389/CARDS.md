# Issue #389 execution cards

[Scope and acceptance](README.md) · [Mandatory delivery rules](RULES.md)

Cards partition ownership. Two implementation PRs assemble their outputs into
`grind/389-xml-data-binding`; cards do not each create a PR. Main is owner-controlled.

## Frozen integration contract

```ruby
XmlDataLoader.new.load(definition_path, instances_path, location: location)
# => { "Catalog" => typed_instance }
```

The loader owns XSD compilation, root QName/type binding, XML hydration,
validation and registry lifecycle. Paths are already resolved by the macro.
It returns a string-keyed root wrapper and leaves model objects intact for
Liquid. The macro owns header parsing, pair dispatch, path checks, options,
includes, template rendering and block-level logging. Existing format/provider
branches retain their current behavior. Record any required interface change
here before dependent edits, and notify both owners.

## Ownership and dependencies

| Card | Outcome / acceptance | Exclusive ownership | Depends on | PR |
| --- | --- | --- | --- | --- |
| A — exact corpus | Pin the 2014/1.1.0 distribution, XML and complete XSD closure; independently inventory feature/attribute/enumerant identities and references | Acquisition scratch only initially; promotion of fixtures/provenance to `spec/fixtures/lutaml/xml_data/s100/` belongs to D | External inputs | 2, through D |
| B — compiler contract | Executable synthetic named/anonymous root, validation, Liquid and isolation probes; precise upstream reproducer for any failure | Probe scratch and logs only; no plugin source edits | Installed admitted model runtime | 1, through C |
| C — typed XML loader | Correct typed instance wrapper, imports, QName/type resolution, validation/errors and isolated lifecycle; positive regression tests | New `lib/metanorma/plugin/lutaml/xml_data_loader.rb`; additional binding helper files only after naming them here; new `spec/metanorma/plugin/lutaml/xml_data_loader_spec.rb`; `spec/fixtures/lutaml/xml_data/unit/` | B's viable compiler route; A for later real-corpus compatibility | 1 |
| D — catalogue acceptance and docs | Every real feature clause and nested value accounted for; working example and reproducible docs | New `spec/metanorma/plugin/lutaml/xml_data_s100_spec.rb`; `spec/fixtures/lutaml/xml_data/s100/`; `docs/usages/lutaml-data.adoc`; `docs/usages/lutaml-xsd.adoc`; root `README.adoc` | A inventory; C and E for execution; docs outline can start independently | 2 |
| E — macro integration | Add XSD/XML pair support; preserve all old format/provider paths; contexts, includes, errors and real clause assertions | `lib/metanorma/plugin/lutaml/lutaml_data_preprocessor.rb`; `lib/metanorma-plugin-lutaml.rb`; `spec/metanorma/plugin/lutaml/lutaml_data_preprocessor_spec.rb`; `spec/fixtures/lutaml/xml_data/macro/` | Frozen interface above; C for final execution | 1 |
| F — integrated verification and remote delivery | Combined checks, final review, correct PR bases, final-head CI, suma/WMO proof, precise partial/completed status | Git branches/commits/PR operations; `docs/plans/389/`; any gemspec/dependency manifest change; shared runner scripts and test logs | A–E outputs as applicable | Both |
| G — required upstream compiler correction | Generate usable models for XSD `xs:ID` and `xs:IDREF`, with a minimal reproducer and preservation tests | Separate `lutaml/lutaml-model` checkout: `lib/lutaml/model/schema/xml_compiler/supported_data_types.rb`, `lib/lutaml/model/schema/xml_compiler/spec_builder/simple_types.rb`, and a focused compiler regression spec | B's reproduced real-catalogue failure | Separate dependency PR, required for PR 2 |
| H — compatibility prerequisite | Restore the nine existing renderer failures reproduced by canonical #390 CI, preserving positive content assertions | `express_remark_adapter.rb` and EXPRESS specs: focused worker; `lutaml_diagram_base.rb`, gemspec and diagram spec: integrator; Git/PR operations: integrator | Concrete failed CI on #390; independent of XML implementation | One consolidated prerequisite PR to grind |
| I — native source-byte integrity | Preserve CRLF/UTF-8 source bytes paired with native parser offsets on Windows | Separate expressir checkout: parser.rb and generated-input regression; CI candidate/native setup belongs to integrator F | Reproduced #391 Windows source-slice failure | One upstream Expressir #740 companion to grind |

No overlapping fixture directories: C uses `unit/`, E uses `macro/`, D uses
`s100/`. Changes to shared `spec/spec_helper.rb` are integrator-owned and need a
demonstrated requirement. A required upstream compiler fix is its own repository
task with a minimal reproducer, not a second implementation of the compiler.

## Executable cards

### A — acquire and inventory

- Locate the exact distribution named in #389/#3, using its original edition.
- Save provenance and checksums, identify redistribution constraints, and
  recursively list imports/includes. Do not substitute a newer schema set.
- Extract root QName, namespace map, feature identities and relationships with
  a deterministic script independent of the binder. D consumes this oracle.
- Done: D has reproducible inputs and expected inventory, or a precise input
  blocker is recorded. Input failure never marks C5 complete.

### B — prove the compiler route

- Use the admitted model runtime; record the exact selected version.
- Run XSD compilation, root mapping, XML hydration, explicit validation and
  a plain-Liquid loop. Exercise named and anonymous roots, URI-equivalent
  prefixes and two bindings with overlapping names in one process.
- Return the supported APIs and minimal failing examples to C. Keep runtime
  findings distinct from real S-100 compatibility.
- Done: an executable route or a bounded upstream blocker with its reproducer.

### C — implement the complete loader

- Implement the frozen interface using the compiler proven by B.
- Resolve expanded root QName to the actual declared type; retain attributes,
  nested collections and meaningful restriction errors.
- Isolate modules/registers without corrupting callers or leaving unbounded
  registrations; serialize calls around shared dependency state where needed.
- Tests: named/anonymous roots, import resolution from a different cwd,
  invalid enum/cardinality, wrong root, malformed/missing files, two independent
  schemas and repeated loads. Assert values, error context and preservation.
- Done: focused loader tests and lint pass; hand the result directly to F/E.

### D — prove the real catalogue and explain usage

- Promote A's inputs with provenance/manifest; derive the exact property names
  and reference traversal from the successful binder output.
- Emit clauses and nested attributes/enumerants with plain Liquid. Assert
  source identities and values in their correct clauses, plus changed-input
  rebuild behavior and repeated-document preservation.
- Document the verified syntax, context, imports, validation limits and errors.
- Done: real-corpus acceptance and a runnable example pass. Missing data or
  consumer setup remains an explicit acceptance gap.

### E — integrate the macro

- Recognize `.xml` instances and dispatch `.xsd` definitions to the loader.
- Require a valid pair, resolve both paths through the document helper, and
  preserve default/custom contexts, inline/JSON options and includes.
- Pass typed XML objects through Liquid; preserve old wrapper conversions and
  provider dispatch. Add the loader autoload, with no extra registration.
- Tests: positive rendered clauses plus pairing failures and existing-format
  controls. Do not mark end-to-end tests passed while using a loader stub.
- Done: focused macro and preservation tests/lint pass against C's real loader.

### F — integrate, verify and expose remotely

- Push the shared base, then publish PR 1 from `work/389-typed-xml-binding`
  to `grind/389-xml-data-binding` once C+E have a coherent inspectable slice.
  Seed the base with the planning documents as its initial setup commit;
  keep them outside implementation diffs. Do not create a planning-only PR.
- Prepare PR 2 from `work/389-s100-example` against the same base; stack it on
  PR 1 locally and push its branch for visibility if needed. Open PR 2 after
  PR 1 integrates so its diff contains only the catalogue/example slice.
  Do not expose the combined implementation twice as overlapping review work.
- Use the acceptance commands in the plan. Run background checks with captured
  status and logs; report the actual bundle/dependency revision and final SHA.
- Merge ready card PRs only into the grind base after their final-head checks
  and repository approvals. Review the combined issue change once, resolve
  findings, then verify the integration head and downstream candidate.
- Done: a remotely visible tested base with C1–C5 evidence and an owner-ready
  main handoff. Automation never performs the main merge or release.

### G — repair the demonstrated compiler dependency

- Reproduce the generated `ItemIdentifier < ID` failure with a minimal schema.
  The compiler's supported-type lookup recognizes lowercase `id` but the
  schema declares `xs:ID`; `xs:IDREF` also needs an admitted supported mapping.
- Correct that narrow mapping in `lutaml-model`, with tests that compile/load
  model classes and hydrate ID/IDREF values. Preserve neighboring built-ins.
- Keep the dependency patch separate from the plugin. Use an issue-specific
  grind base in that repository too; no main merge or release by automation.
- Re-run the exact catalogue probe against the candidate dependency, then
  qualify the plugin with that revision. Record any additional proven gap
  rather than adding silent plugin compiler workarounds.
- Done: focused dependency checks and real-catalogue probe pass; a reviewed
  dependency revision is available for integration. Normal dependency release
  remains an external delivery milestone.

## Current board and forecast

| Card | Status | Evidence / next step |
| --- | --- | --- |
| A | Complete | Five-file closure acquired; source inventory: 28 features, 51 simple and 6 complex attributes, 406 listed values |
| B | Generic route proven; upstream gap isolated | Authentic model 0.8.176 synthetic probe passes; real catalogue validates against XSD but compiler fails ID/IDREF generation |
| C | Implemented; focused checks pass | 15 loader examples pass, including nested custom types, explicit location and isolation; strict XSD validation remains authoritative |
| D | Implemented; candidate verified | Six real-corpus acceptance examples pass without shims; standalone semantic XML and WMO-taste XML smoke checks emit all 28 feature clauses |
| E | Implemented; focused integration passes | Macro tests pass against the real generic loader in the combined focused run |
| F | Integrating qualified prerequisites | Compatibility #391 and Expressir #740 merged only to their grind bases. Generic #390 dc0f9e6 final CI running; model #1175 final321 CI running. Example branch prepared; its PR follows generic integration. Combined400/0, packaged Suma and original-catalogue WMO smoke pass. |
| G | Published as model #1175; unreleased | Candidate `c21b2f8d4e91efe6937b6c4637a5102249b8a7e5`: all 49 compiler examples pass after network restoration; real-corpus checks pass against it |
| H | Merged to plugin grind | #391 final48e1 passed all six OS/Ruby CI jobs; mergeee658f2. Existing goldens and figure A/B preserved |
| I | Merged to Expressir grind | #740 final113 passed all seven workflows including Windows; merge0e3a104. Raw spans preserved and logical remarks normalize to LF |

### Current verification evidence

- Candidate plugin and compiler: 154 affected feature/preservation examples,
  zero failures; compiler regression/runtime specs: four examples, zero failures.
- The real-corpus six-example set checks unchanged source bytes/schema closure,
  all identities/references, correctly owned feature/attribute/enumerant content,
  exact feature-clause multiplicity and changed-input isolation.
- Standalone standoc XML and WMO-taste XML compile successfully. WMO smoke proof
  includes all 28 feature clauses, IHO base configuration/registered processor and the WMO publisher override; serialized root_flavor remains generic.
  HTML/PDF and the populated downstream corpus are not claimed as tested.
- Changed Ruby files pass lint. One complete final implementation review covered
  plugin/dependency interactions; missing-marker and duplicate-clause assertion
  gaps were fixed, and the affected checks rerun.
- Original canonical default:397examples/10failures, all reproduced on the
  unchanged baseline. Canonical generic PR CI confirms nine semantic failures;
  the HTTP-only failure disappears with restored networking. Compatibility
  #391 fixes all nine while retaining original goldens. Its local default suite
  passes368/0; the combined candidate passes400/0. No CI failure is waived.
- The suma build/reuse/reproducibility integration passes with the built
  candidate gems after selecting its declared Expressir minimum (2.4.80) and
  supported local-only bibliographic caching. It also passes in the consumer
  development bundle with its declared Git sources. No assertions or production
  code were changed to obtain this result.
- The extended compiler suite now passes all 49 examples after network access
  was restored; this includes the seven previously blocked HTTP cases.
- Generic plugin #390 and compiler #1175 are published drafts targeting grind
  bases; canonical final-head CI is running. Prerequisite grind merges are recorded above; no main merge, release,
  issue closure or released minimum containing the compiler fix is claimed.
- The downstream WMO master still has no populated corpus or Makefile; only the
  original-catalogue WMO-taste smoke is verified. No downstream corpus build is
  claimed.

The parallel implementation batch and local real-corpus qualification are
complete. The remaining critical path is F: obtain canonical final-head CI for the published
bounded drafts,
integrate the compatibility prerequisite after its canonical checks pass.
Owner-controlled dependency release/floor selection follows those checks.
External access and CI waiting prevent an unconditional delivery ETA. The
original 30–48 hours is total engineering effort, not a required elapsed delay.

### H — clear the reproduced baseline CI gate

Canonical plugin #390 Ubuntu/Ruby 3.4 runs 391 examples with nine failures:
three schema-prose formatter positions, three EXPRESS index outputs, one
multiple-file prose output, and two missing diagram renders. These reproduce
the previously recorded baseline failures; they cannot be waived for integration.
One coherent compatibility PR restores the declared dependency combination,
including the extracted `lutaml-graphviz` renderer, without changing goldens or
releasing packages. Require focused old-red/new-green checks, figure-bearing
consumer preservation, default-suite and exact-head CI before grind integration.
The generic XML PR follows that prerequisite; main remains owner-controlled.

### I — correct the demonstrated Windows parser boundary

Compatibility #391 resolves the nine original renderer failures, but Windows
CI reveals one earlier parser failure (367examples/1failure): text-mode source
reads shrink CRLF input after the native batch parser counted physical bytes.
Expressir #740 changes only its three source reads to binary UTF-8 and preserves
BOM handling. A real-native generated two-file regression reproduces the exact
old exception, then verifies all100entities/file, Unicode and source ranges.
Ten focused native/BOM/batch/span examples pass; no fixture/golden changes or
nil guards hide the failure. Plugin CI pins the exact candidate and reuses the
unchanged published2.4.82 native ABI, with source/native hashes and mandatory
native BatchStream availability. No release/version bump is automated.

The combined candidate with this dependency again passes400default examples
and Suma build/reuse/reproducibility. Model #1175 also restores the Ghostscript
setup its Windows tools-dependent jobs already requested; the shared tool action
had retired it. Exact-head CI and all grind merge gates remain required.

Final Windows qualification also normalizes logical remarks/header and retained formatter-wire comment fields to LF while preserving physical source bytes and spans. Final113 passes49affected parser/formatter examples,7final regression/parity examples and lint. A disposable physical-CRLF plugin checkout fails six cases before that semantic correction and passes all36after it. Actual final Windows CI now passes in both repositories. Final model321 changes CI setup only after tested compilerc21; its macOS runner-capacity retry and downstream jobs remain required gates.
