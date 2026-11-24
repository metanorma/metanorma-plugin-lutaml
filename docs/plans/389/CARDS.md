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
  PR 1 locally if needed, and remove prerequisite commits from its diff after
  PR 1 integrates. Keep the PR body explicit about its dependency meanwhile.
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
| C | Implemented; focused checks pass | 14 loader examples pass, including explicit location and isolation; changed-file lint clean |
| D | Active; real rendering depends on G | Fixtures/provenance/oracle and worked-example acceptance |
| E | Implemented; focused integration passes | Macro tests pass against the real generic loader in the combined focused run |
| F | Active; publication blocked | Combined local focused run: 169 examples, 150 pass, 19 fail in existing XSD documentation cases due restricted bibliographic-cache writes/network access. No failure is waived; canonical CI remains required. Local grind/work branches exist; remote push failed DNS resolution; no remote branch/PR claimed |
| G | Active | Minimal upstream ID/IDREF correction and no-shim real-catalogue re-probe |

The original 30–48 hours is total engineering effort, not a mandatory elapsed
schedule. A/B/E begin concurrently; C follows the first viable B result; D
begins after A and can overlap C/E; F integrates and runs scripted checks as
outputs become ready. The first two-hour checkpoint replaces speculation with
measured compiler, corpus, test and remote-readiness evidence. Until then,
elapsed completion time remains conditional on the real inputs and any compiler
gap. No day-based delivery date is asserted as a substitute for those results.
