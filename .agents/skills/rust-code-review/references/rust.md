# Rust Review Reference

Check repository naming, ownership, fallibility, mutation, readability,
formatting, and lint conventions.

- Use `snake_case` for modules, files, functions, and variables;
  `PascalCase` for types, traits, and enums; and `SCREAMING_SNAKE_CASE` for
  constants.
- Borrow `&T`, `&[T]`, and `&str` by default. Take ownership only when transfer
  or storage requires it. Pass `Copy` and small plain-data values by value when
  that best expresses the contract. Avoid hot-path clones; flag `clone()` on
  `Copy` values unless a concrete API constraint requires it.
- Use enums for closed state machines, focused traits for polymorphism, minimal
  `pub` surface, and `Result` for recoverable errors.
- Avoid `unwrap()` and `expect()` in production paths. Use actionable,
  domain-specific errors; reserve panics for impossible states and tests.
- Keep functions focused, prefer guard clauses over deep nesting, and extract
  helpers when branching or state mutation obscures intent.
- Do not globally silence useful lints. Require a narrow, justified
  `#[expect(clippy::...)]` where supported; accept `#[allow(...)]` only with a
  documented reason and the smallest possible scope.
- Require `cargo fmt --all -- --check` and
  `cargo clippy --workspace --all-targets -- -D warnings` for relevant Rust
  changes.

Use rustdoc (`///` / `//!`) for public behavior and constraints. Check runtime
and documented `Result`/error contracts, including success and meaningful
propagated/recovered failures across crate and binary boundaries.

Keep iterator pipelines lazy where useful; prefer a direct loop when it makes
control flow clearer. Use `_else` variants such as `ok_or_else` when fallbacks
allocate. Flag intermediate `collect()` results that can be streamed
into their consumer. Keep CPU work off async executor threads: Rayon is an
option for CPU data parallelism and Tokio for I/O orchestration when already
appropriate to the project. Use dedicated named pools for latency-sensitive
fan-out when needed; keep `spawn_blocking` bounded. These are choices to assess,
not authorization to add dependencies.

## Unsafe and trust boundaries

Follow the target project's unsafe policy. At permitted unsafe boundaries,
require documented pointer validity, lifetime, alignment, aliasing, bounds,
ownership, and thread-safety invariants. Explicitly inspect atomic ordering and
producer/consumer ownership when those boundaries cross threads or processes.

Additional cap: boundary unsafe without documented invariants scores at most 2.
A project's stronger unsafe prohibition or approval rule still applies.
