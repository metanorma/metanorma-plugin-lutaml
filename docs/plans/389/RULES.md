# Issue #389 delivery rules

These rules apply to work for [#389](https://github.com/metanorma/metanorma-plugin-lutaml/issues/389).
They take precedence over general automation defaults for this task.

## Branch and merge boundary

1. The shared integration base is **`grind/389-xml-data-binding`**, starting
   from main at `309a3c770f6ccfb9bb818cf47c2103d61f4e2ae8`.
2. Every implementation PR targets that base. Work branches use
   `work/389-typed-xml-binding` and `work/389-s100-example`.
3. Automation must never push, merge, force-push, or enable auto-merge to
   `main`/`master`. Main merges belong to the repository owners. This remains
   true after all acceptance checks pass. No release/tag/version bump is part
   of automated integration work.
4. Before every PR creation or merge, read the actual head, base and SHA.
   Refuse the operation if the base differs from `grind/389-xml-data-binding`.
   Before merging a card PR, require its actual final head's checks and the
   repository's approvals, and pin the merge to that exact head SHA.
5. The final handoff identifies the tested integration SHA, constituent PRs,
   acceptance coverage and consumer evidence. A final comparison/PR to main
   can be prepared only when requested; its merge remains owner-controlled.

## Remote visibility and PR scope

6. Push the shared base and meaningful work checkpoints. Open/update draft
   implementation PRs as soon as a coherent change is inspectable. A draft
   explicitly lists incomplete acceptance and pending checks. Do not represent
   local commits or a queued command as remote visibility.
   The base's initial setup commit carries the plan/cards/rules; later feature
   changes arrive through the two implementation PRs.
7. Use **two planned implementation PRs**: (1) complete generic typed XML
   binding, macro integration and their tests; (2) real S-100 acceptance,
   worked example and documentation. Cards are ownership units, not one-PR
   requirements. Keep loading, its integration and essential regression tests
   together. No separate PR for each helper, fixture or documentation tweak.
8. Aim for about **250–600 changed handwritten lines per PR**; inspect scope
   before exceeding **800** or about **12 handwritten code/test/doc files**.
   These are reviewability triggers, not reasons to omit tests or arbitrarily
   split a complete behavior. If exceeded, record the reason and propose a
   coherent boundary before adding another feature. Count full corpus XML/XSD
   separately, list their bytes/provenance, and explain them with a manifest
   and minimal regression fixtures. Never hide fixture size in the PR summary.
9. Each PR explains its concrete trigger and behavior, why the chosen boundary
   is coherent, dependencies, exact check evidence, and remaining issue-level
   acceptance. It is ready only when its promised behavior is complete and
   checks pass. An incomplete draft never auto-merges.
10. Combine progress updates at milestones: contract/probe result, coherent
    implementation pushed, integrated tests completed, or a blocker. Batch
    pushes to avoid redundant CI. No status-only PRs, empty commits or review
    comments as a substitute for delivered code. Remote write failures stay
    visible with the precise failed operation and the preserved local state.

## Ownership, speed and validation

11. Follow the [card ownership table](CARDS.md). One writer per file set.
    Workers preserve other edits and do not run shared branch/commit/merge
    operations. The integrator owns shared manifests, dependency changes and
    the combined branch state. Transfer ownership explicitly before overlap.
12. Run independent corpus discovery, compiler probes and macro work in
    parallel against one frozen loader interface. Keep schema/compiler work
    and real-corpus acceptance gated on their actual inputs; do not fake the
    catalogue or treat a stub as compatibility proof.
13. Use scripts for repeatable probes, test batches, diff-size summaries and
    result capture. Run longer jobs in the background with logs and exit-status
    files. Use completion notifications or blocking tool waits; avoid repeated
    status polling and model-driven log summarization. Run memory-heavy suites
    one at a time; independent editing continues during those checks.
14. For changed behavior, establish a failing case, then assert positive
    content after the fix and preserve existing formats. Required coverage:
    root QName/type binding, imports, namespaced attributes/elements,
    nesting/collections, facets, diagnostics, cross-document isolation,
    plain-Liquid clauses and the real catalogue inventory.
15. Run focused tests and changed-file lint during development; run the
    repository default suite, final-head CI and the required downstream suma
    integration test for delivery. Verify WMO against the exact candidate gem.
    Record dependency versions and distinguish any local installed-gem test
    bundle from the canonical CI bundle. A killed, skipped or unavailable
    check is not a pass.
16. Perform one complete final review of the integrated issue change. Resolve
    reachable defects and rerun affected checks. Preserve existing passing
    evidence when its inputs are unchanged; avoid redundant review chains,
    unconditional full-suite reruns and unrelated cleanup.
17. Keep C1–C5 visible in [the plan](README.md). A partial base-branch merge,
    generic synthetic test or generated-AsciiDoc fallback does not complete
    #389. Record evidence, remaining gaps and the next executable action.

## Schedule discipline

18. Report **elapsed execution separately from engineering effort**. Parallel
    work shortens the critical path; it does not remove compiler gaps, real
    input requirements, CI or consumer validation. Reforecast after the first
    compiler and corpus milestones instead of repeatedly quoting person-days.
19. The first execution checkpoint is within two hours of starting the cards:
    input availability, executable compiler contract, bundle status, remote
    branches/PRs, and a revised remaining critical path. If a blocker is found,
    advance independent owned cards and report its concrete completion condition.
