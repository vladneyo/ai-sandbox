---
name: rust-code-review
description: Review Rust changes, pull requests, and refactors for correctness, ownership, error handling, memory safety, performance, architecture, API compatibility, and meaningful tests. Use for a requested Rust review or pre-merge assessment; apply project extensions and contextual style references.
license: MIT
metadata:
  author: "Vladyslav Neichev (@vladneyo)"
  origin: compiled
---

# Rust Code Review

Review Rust changes for correctness and merge risk. Lead with actionable findings.
Review and report by default; implement corrections only when the task also
authorizes edits. Keep a focused review within its requested scope.

When invoked through a project extension, retain its architecture, validation,
severity calibration, and stricter score caps. Resolve this skill's references
relative to this shared directory. Read [Rust guidance](references/rust.md) and
[the Google reference](references/google-rust-style.md) before the review.
Read [realtime/boundary guidance](references/realtime.md) when realtime, DSP,
SIMD, or shared-memory/IPC behavior is touched.

## Scope and source policy

Focus on Rust and its relevant Cargo, feature, build, API, and integration
contracts. Trace other-language or platform boundaries as needed to judge Rust
behavior; do not expand a focused review into an unrelated language audit.

User requirements and the target repository's explicit policy govern the
review. External references supply contextual review questions; they do not
silently adopt another organization's style policy. Distinguish enforceable
project rules, evidence-backed defects, and optional unadopted preferences.
Do not assign a correctness severity or score cap solely for disagreeing with
an unadopted style preference. Cite the exact source section when relying on
it and explain its applicability or a justified departure.

## Review contract

For each finding provide file/line, severity (`P0`–`P3`), concrete impact,
evidence (code, test, measurement, documented rule, or reasoned invariant), and
the smallest useful correction. Trace the trigger and affected behavior rather
than presenting an unsupported possibility as a defect. State assumptions.

After findings, report dimension scores, applied caps, validation status,
performance/memory impact, and open questions. If no actionable defect is
established, say so and identify remaining validation gaps.

## Severity calibration

Calibrate priority by impact, exposure, and triggering conditions:

- `P0`: an immediate stop-ship defect such as critical memory unsafety or severe
  data corruption in the supported execution path.
- `P1`: a serious correctness, error-propagation, security, or API-contract bug.
- `P2`: a contained correctness/performance regression, flaky test, or missing
  contract documentation that obstructs correct use.
- `P3`: a contained readability/style issue, unnecessary complexity, or small
  avoidable resource cost with a concrete consequence.

Project extensions may define tighter severity rules. Scores do not override
an actionable correctness blocker.

## Workflow

1. Establish the requested diff/files and baseline, intended behavior, affected
   callers, and compatibility constraints. State material scope assumptions.
2. Classify changed surfaces: computational/hot paths, UI, callbacks/workers,
   external/process boundaries, persistence/configuration, tests/docs/tooling.
3. Read relevant project architecture and trace ownership, state, and fallible
   behavior across boundaries before judging the change. Existing patterns are
   context, not proof of correctness.
4. Check correctness first, including success, propagated/recovered failures,
   and agreement between runtime behavior, callers, and API documentation.
5. Verify meaningful testing breakpoints and run suitable existing checks when
   feasible. State a credible justification for omitted validation.
6. Score all six dimensions from 0 to 5, then apply every relevant cap. Return
   findings before scores, evidence, and remaining uncertainty.

## Scoring scale

Use this scale for every dimension:

| Score | Meaning |
| --- | --- |
| 5 | Strong: clear, measured where needed, tested at meaningful breakpoints, idiomatic, and low-risk. |
| 4 | Good: minor local issues or narrow missing validation, but the design is sound. |
| 3 | Adequate: plausibly works, but evidence, tests, structure, or clarity is incomplete. |
| 2 | Risky: likely maintenance, performance, safety, or correctness problems. |
| 1 | Fragile: serious flaw, unclear invariant, or likely regression. |
| 0 | Blocking: known incorrect behavior, unsoundness, critical validation failure, or severe security risk. |

## Hard caps

Apply these maximum final scores after averaging:

| Condition | Maximum score |
| --- | --- |
| Relevant tests fail | 2 |
| Relevant tests are not run without a credible justification | 3 |
| Public behavior, indexing, scheduling, serialization, or boundary contracts change without breakpoint tests or strong existing coverage | 3 |
| A performance claim/optimization lacks measurement | 3 |
| New SIMD, parallelism, or scheduling lacks deterministic equivalence validation | 3 |
| Security-sensitive behavior changes without data-flow and failure-mode review | 2 |

Apply additional caps from relevant specialist references and the project
extension. Record each applicable condition; use the strictest cap.

## Dimension 1: Performance and measurement

Check latency, throughput, complexity, allocation/resource pressure, cache
behavior, scheduling, and observability. Require a profile, benchmark, trace,
or clear complexity argument for an optimization. Separate startup from steady
state and claims of speed from actual measurements.

Watch repeated formatting/cloning/collection, container growth, and recreated
images/meshes/textures in relevant hot paths. Prefer contiguous data access,
hoisted invariants, shallow branches, and batching where evidence supports it.
For concurrency, identify CPU/I/O/GPU work, bound queues and fan-out, and state
backpressure and overload behavior. Use the target ecosystem's appropriate
mechanisms; do not require one threading library for every project.

Score 5 for measured or clearly non-hot work with controlled costs and suitable
validation; 3 for plausible but unmeasured nontrivial changes; 1 for a violated
hot-path contract or unsupported performance assumptions.

## Dimension 2: Maintainability and change locality

Check whether future changes are localized, discoverable, and testable.

- Keep each behavior in one clear owner. Avoid duplicate algorithmic logic and
  scattering one feature across unrelated layers.
- Keep dependencies pointed inward toward stable abstractions. Make ownership
  explicit when several modules can mutate the same concept.
- Use focused traits, typed config, or explicit adapters at replaceable
  boundaries. Keep platform/backend details out of reusable domain logic.
- Use searchable domain names, document important invariants near dependent
  code, and cross-reference required docs.
- Require language-appropriate API documentation on public behavior and
  constraints; use implementation comments for rationale, safety invariants,
  platform constraints, and assumptions. Flag
  comments that restate the code, stale comments, and bare TODOs without an
  owner, issue, or removal condition.
- Prefer small cohesive functions and modules. Remove dead code.
- Capture recurring review rules in documentation or agent instructions.

## Dimension 3: Testing and validation

Protect real breakpoints: behavior contracts, edge cases, bug reproductions,
public APIs, deterministic math helpers, boundaries, serialization,
indexing/windowing, concurrency handoffs, and silent-regression paths.

Expect tests when a change:

- Alters user-visible behavior.
- Changes algorithms, numerical behavior, indexing, transforms, timing, or
  thresholds.
- Changes serialization, config compatibility, public APIs, or trait contracts.
- Adds concurrency, scheduling, buffering, throttling, async, SIMD, parallel,
  GPU, IPC, FFI, shared-memory, or driver handoff behavior.
- Fixes a deterministically reproducible bug.

For changed fallible behavior, cover the intended result and at least the
meaningful propagated or recovered error path. Treat tests as behavior
documentation, with one focused contract per test where practical.

Allow tests to be unnecessary for pure docs/comments, mechanical formatting,
private renames covered by the compiler, trivial UI text/layout changes where
visual inspection is the right validation, or test-only helpers covered by
existing execution. State the justification.

Require AAA structure:

- Arrange deterministic inputs, fixtures, configuration, and expected state.
- Act on the smallest behavior under review.
- Assert precise outputs, invariants, errors, counters, or tolerances.

Prefer deterministic fixtures, helpers, and table-driven cases. Avoid unseeded
randomness and wall-clock-dependent assertions. Use explicit float tolerances
justified by the numerical contract. Test optimized paths against simple references where
possible. Pair correctness tests with benchmarks or profiling artifacts when a
performance claim depends on speed.

## Dimension 4: Style and idiomatic Rust

Check Rust naming, ownership/borrowing, lifetimes, fallibility, mutation,
readability, formatting, and lint conventions. Keep functions
cohesive, prefer guard clauses when they clarify intent, and avoid globally
silencing useful diagnostics. Require narrow, justified suppressions and
project-appropriate rustfmt/clippy checks. Use the Rust and Google references
with their applicability limits; do not request unrelated formatting changes.

## Dimension 5: Design and architecture

Keep domain logic independent of UI/platform/infrastructure adapters. Respect
the project's module ownership and dependency direction. Prefer focused
interfaces, substitution-compatible abstractions, and composition where they
reduce concrete coupling; avoid speculative frameworks or branching explosions.

Make performance-sensitive pipeline stages observable with distinct metrics.
Check that a tuning option affects the bottleneck it claims to control. Prefer
existing narrow helpers over new dependencies for small utilities, and follow
the repository's dependency approval and feature-minimization policy.

## Dimension 6: Security, safety, and trust boundaries

Trace untrusted input, authorization, privileges, sensitive data, process and
resource ownership, and failure paths. Validate serialized values, sizes,
versions, bounds, and compatibility before use. Malformed user-editable data
must fail safely or fall back deliberately.

Inspect privileged integration and install/uninstall behavior carefully. Avoid
custom cryptography/authentication and unnecessary sensitive logging. Define
behavior for disconnects, unavailable backends, dropped channels, poisoned
locks, invalid handles, cancellation, and partial failure. Apply Rust's and the
project's memory-safety constraints; document boundary invariants.

## Final score

1. Average the six dimension scores.
2. Round down to the nearest half point.
3. Apply the strictest applicable hard cap.

Report both the raw average and capped final score:

| Capped score | Interpretation |
| --- | --- |
| 4.5–5.0 | Mergeable after normal review. |
| 3.5–4.0 | Mergeable after local fixes or explicit acceptance of minor risk. |
| 2.5–3.0 | Needs changes before merge. |
| 1.5–2.0 | Significant redesign or validation required. |
| 0–1.0 | Blocker; do not merge. |

## Output template

```markdown
Findings

1. [P1] Title
   File: path:line
   Impact: ...
   Evidence: ...
   Suggested correction: ...

Scores

| Dimension | Score | Notes |
| --- | ---: | --- |
| Performance and measurement | 0-5 | ... |
| Maintainability and change locality | 0-5 | ... |
| Testing and validation | 0-5 | ... |
| Style and idiomatic Rust | 0-5 | ... |
| Design and architecture | 0-5 | ... |
| Security, safety, and trust boundaries | 0-5 | ... |

Raw score: X.X / 5
Capped score: X.X / 5
Caps applied: ...

Validation

- Tests run: ...
- Tests not run: ...
- Performance evidence: ...
- Memory/allocation impact: ...

Open Questions

- ...
```
