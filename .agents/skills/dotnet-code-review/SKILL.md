---
name: dotnet-code-review
description: >-
  Perform rigorous, evidence-based C#/.NET code reviews for pull requests, branch
  diffs, commits, staged or unstaged changes, and selected files. Use this skill
  whenever a human or agent asks to review .NET code, requests a pre-merge quality
  gate, wants review feedback triaged, or needs a review package prepared for
  another reviewer. Covers correctness, regressions, security, reliability,
  performance, APIs, architecture, tests, and maintainability. Discover and
  compose with installed specialized review skills when they match the reviewed
  code.
compatibility: Git and C#/.NET code-reading tools are recommended. May compose with installed specialized review skills.
license: MIT
---

# .NET Code Review

Treat C#/.NET code review as an engineering quality gate, not a style exercise
or a social ritual. Find concrete risks, explain their impact, and help humans
and agents make technically sound decisions.

By default, review and report only. Do not edit code unless the user separately
asks to implement accepted findings.

## Select the workflow

Choose the workflow that matches the request:

1. **Conduct a review** when code, a diff, commit range, branch, or pull request
   needs evaluation.
2. **Prepare a review request** when work should be handed to a human or agent
   reviewer.
3. **Triage received feedback** when review comments need verification,
   prioritization, response, or implementation planning.

If the request combines workflows, conduct them in that order: prepare context,
review, then triage any resulting feedback.

## Conducting a review

### 1. Establish the review contract

Determine:

- **Scope**: selection, files, worktree changes, staged changes, commits, branch
  diff, or pull request.
- **Baseline**: the branch or commit the change should be compared against.
- **Intent**: the behavior being added, removed, fixed, or preserved.
- **Requirements**: user request, issue, specification, acceptance criteria,
  repository guidance, and compatibility constraints.
- **Risk profile**: data loss, security, concurrency, public API, migration,
  deployment, performance, or cross-platform concerns.

Prefer an explicitly supplied scope. If none is supplied in a Git repository,
use the smallest sensible changed-code scope, normally the current worktree or
the current branch against its merge base. State material assumptions in the
report.

Do not silently expand a focused review into an entire-repository audit.

### 2. Build enough context

Read the changed code and the nearby code needed to understand it. Trace
callers, callees, interfaces, configuration, persistence, tests, and lifecycle
boundaries when they affect behavior.

Check repository instructions and established patterns before judging a change.
Existing code is evidence of convention, not proof that the convention is
correct.

When useful and safe, run the smallest existing test, build, lint, type-check,
or static-analysis command that can confirm or refute a suspected issue. Do not
install new tooling just for a review.

### 3. Review behavior before style

Examine the change across the applicable dimensions:

- **Correctness**: wrong results, broken invariants, missing branches, invalid
  state transitions, boundary conditions, and error-path behavior.
- **Regression risk**: changed defaults, compatibility breaks, lost behavior,
  migration hazards, serialization changes, and caller impact.
- **Security and privacy**: trust boundaries, authorization, injection,
  credential handling, sensitive logging, unsafe deserialization, path handling,
  and information disclosure.
- **Reliability**: retries, idempotency, timeouts, cancellation, partial failure,
  cleanup, transactions, exception propagation, and recovery.
- **Concurrency and async behavior**: races, deadlocks, shared mutable state,
  blocking calls, unobserved tasks, cancellation, ordering, and thread safety.
- **Performance and resource use**: algorithmic cost, repeated I/O, unnecessary
  allocation, N+1 access, unbounded work, caching errors, disposal, and connection
  lifetime.
- **API and data contracts**: validation, nullability, versioning, status codes,
  schema changes, backward compatibility, and clear ownership.
- **Architecture and design**: dependency direction, cohesion, coupling,
  appropriate abstractions, SOLID principles, and patterns that reduce rather
  than add complexity.
- **Tests**: coverage of changed behavior, meaningful assertions, failure paths,
  determinism, test isolation, and whether tests would catch the suspected bug.
- **Operations and observability**: configuration validation, structured logs,
  metrics, diagnostics, rollout safety, and actionable failures.
- **Maintainability**: duplication, misleading names, accidental complexity,
  dead code, documentation drift, and deviations from established conventions.

Style-only preferences are not findings unless they violate an enforced
standard, create ambiguity, or materially affect maintenance.

### 4. Apply specialized checks

Identify the languages, frameworks, platforms, and technical domains present in
the review scope. Inspect the available skills for a more specialized review
skill that matches them.

When a relevant specialized skill is installed, invoke or read it and apply its
checklist as an additional review lens. Keep this skill responsible for the
overall scope, evidence standard, prioritization, and final report.

Do not depend on a fixed specialized skill name, duplicate its guidance here, or
assume it is installed. If none is available, infer the applicable ecosystem
checks from repository conventions and authoritative platform behavior.

### 5. Admit only actionable findings

Report a finding when all of the following are true:

- It is introduced by, exposed by, or directly relevant to the reviewed scope.
- It has a concrete impact on correctness, security, reliability, performance,
  compatibility, operations, or maintainability.
- The triggering inputs, state, environment, or execution path can be explained.
- The location is specific enough for the author to act on.
- The recommendation addresses the cause rather than merely the symptom.

Use evidence from code, tests, documentation, or tool output. Distinguish facts
from assumptions. Do not inflate speculative concerns into defects.

Before reporting a possible issue, actively look for code that disproves it:
validation elsewhere, guarded callers, framework guarantees, tests, generated
code, compatibility constraints, or deliberate design decisions.

### 6. Assign severity consistently

- **P0 - Critical**: causes catastrophic or immediate harm, such as exploitable
  security exposure, irreversible data loss, or a broadly broken production path.
- **P1 - High**: likely to cause serious incorrect behavior, outages, security
  weakness, or a release-blocking regression.
- **P2 - Medium**: a real defect or material design problem with limited impact,
  a narrower trigger, or a practical workaround.
- **P3 - Low**: a concrete maintainability, test, or operational weakness worth
  fixing but not normally release-blocking.

Do not use severity to express personal preference.

## Preparing a review request

Request review at meaningful checkpoints: after a coherent unit of work, after
a risky or complex change, and before merge. Early review prevents mistakes from
being repeated across later work.

Provide the reviewer with:

- what changed and why;
- requirements and acceptance criteria;
- exact scope, including base and head commits when applicable;
- high-risk areas and compatibility constraints;
- tests or checks already run;
- known tradeoffs, intentional deviations, and unresolved questions;
- the desired output format and whether implementation is out of scope.

For an agent reviewer, give a bounded objective and ask for findings supported
by file and line evidence. Avoid vague prompts such as "review everything."

Use this compact request format:

```text
Objective:
Requirements:
Review scope:
Base:
Head:
Risk areas:
Checks already run:
Known tradeoffs:
Requested output:
```

## Triaging received feedback

Review feedback is input to verify, not an instruction to obey blindly.

### 1. Normalize the feedback

Read all comments first. Convert each comment into a concrete technical claim or
requested behavior. Group duplicates and identify dependencies between items.

### 2. Verify each claim

Check each item against the codebase, requirements, tests, platform behavior,
and architectural decisions. Determine whether it:

- identifies a valid defect;
- is directionally correct but proposes the wrong fix;
- lacks required context;
- conflicts with compatibility or product requirements;
- adds unused complexity;
- is already addressed;
- is incorrect.

If related comments are unclear, clarify them before implementing a partial and
potentially incompatible interpretation.

### 3. Record a disposition

Classify each item as:

- **Accept**: verified and should be addressed.
- **Clarify**: intent or scope is insufficiently defined.
- **Alternative fix**: issue is valid, but a different change better fits the
  codebase.
- **Reject**: technically incorrect, harmful, out of scope, or unjustified.
- **Defer**: valid but intentionally scheduled separately, with a clear reason.

Respond with concise technical reasoning and evidence. Avoid performative
agreement, defensiveness, or automatic rejection based on reviewer identity.

### 4. Prioritize accepted work

If implementation is requested, handle blocking security and correctness issues
first, then coherent simple fixes, then larger refactors. Validate each coherent
group before moving on, and re-check the final diff for regressions.

## Report format

Lead with findings, ordered by severity and then by confidence. Use one entry per
independent problem.

```markdown
## Findings

### [P1] Imperative, specific title
`path/to/file.ext:line`

Explain the triggering scenario, observable impact, and why the current code
causes it. Give a focused recommendation when it is not obvious.

## Questions and assumptions

- Include only questions or assumptions that materially affect the review.

## Review summary

State the reviewed scope and a brief risk assessment. If there are no findings,
say "No actionable findings" and mention any material coverage gaps.
```

Keep praise and general summaries secondary to findings. Do not bury important
issues in prose or mix multiple problems into one finding.

For feedback triage, use a compact table:

| Item | Disposition | Severity | Evidence and rationale | Next action |
|---|---|---:|---|---|

## Final quality gate

Before returning the review, verify that:

- the scope and baseline are correct;
- the implementation was compared with its stated requirements;
- cross-file wiring and callers were checked where relevant;
- error, boundary, lifecycle, and compatibility paths were considered;
- tests were inspected for whether they detect the changed behavior;
- each finding has a concrete trigger, impact, location, and recommendation;
- severity reflects impact rather than preference;
- contradictory evidence was considered;
- applicable specialized review skills were considered and used when available;
- the report clearly distinguishes findings, questions, and assumptions.

## Sources

This skill synthesizes and extends the MIT-licensed CommandCodeAI
`requesting-code-review` and `receiving-code-review` skills. See `LICENSE.txt`
for attribution.
