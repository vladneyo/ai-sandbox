# Google Rust Review Reference

[Source: Google Rust guide](https://google.github.io/styleguide/rustguide.html).
Reviewed: 2026-11-05; consult upstream for details and exceptions.

Review lenses:

- Library commitments versus application simplicity.
- Copying/shared-ownership costs and flexible borrowed inputs.
- Purposeful newtypes, options, traits, dispatch, defaults, and public evolution
  (`non_exhaustive`, `must_use`).
- Recoverable errors and pattern-based proofs before invariant panics.
- Clear naming/types, readable loops/pipelines, and justified macros.
- Useful public documentation and explicit safety obligations.

Chromium/Fuchsia layout, build, import, async, thread, mutex, and testing rules
are scoped; do not transplant them into unrelated Cargo projects. Follow project
policy for shared pointers, poisoning, panic containment, and allocation budgets.
Cite the relevant section and consequence; separate binding requirements from
optional style suggestions.
