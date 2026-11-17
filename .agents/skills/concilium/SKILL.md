---
name: concilium
description: Run a structured multi-agent technical decision process with independent proposals, project-specific measurements, peer scoring, and verification. Use for complex decisions that need explicit assessment of functional logic, algorithms, performance, memory, UI, IPC or network overhead, security, and architecture where applicable.
license: MIT
metadata:
  author: "Vladyslav Neichev (@vladneyo)"
  origin: original
---

# Concilium

Create a decision brief from [template.md](template.md). Keep observed facts,
proposals, forecasts, peer scores, and decisions separate. Adapt the assessment
to the project's goals, workloads, constraints, and risks; no product domain,
language, framework, or runtime is assumed.

## Workflow

1. Choose the artifact location using the target project's conventions and
   check for related plans or investigations. A project extension supplies
   local paths and lifecycle rules; otherwise use the requested destination
   and state whether the brief is a plan or an investigation.
2. Copy `template.md` and complete its required sections. Establish the decision
   question, observed facts and sources, project goals, hard constraints,
   non-goals, unknowns, and independently selectable decision surfaces.
3. Complete the quality coverage map before requesting proposals. Address all
   eight dimensions below for the relevant surfaces. Record each as scored,
   gated, both, or not applicable with a concrete reason. Add dimensions when
   project needs require them; domain-specific guidance belongs in the project
   extension or brief.
4. Define the smallest metric set that covers the applicable dimensions and
   goals. There is no fixed metric count. For each metric specify the outcome,
   unit or evidence rubric, better direction, baseline, target, representative
   workload/environment, measurement method, evidence status, 1/3/5 anchors,
   and weight. Higher scores must always mean better outcomes even when lower
   raw values are better. Keep hard requirements as gates.
5. Freeze the rubric for each surface before collecting proposals. Every
   candidate on that surface uses the same applicable metrics, conditions,
   anchors, and weights. Weights sum to 1.00. Document later rubric changes and
   rescore every affected candidate; do not change criteria to favor a proposal.
6. Assign complementary independent roles and provide the same evidence pack,
   coverage map, surface IDs, and output contract. Each participant proposes
   one action per surface, including explicit no change or justified N/A.
7. Collect proposals before cross-scoring. Proposer metric forecasts are
   non-voting evidence. Each peer independently scores every other proposed
   action against the surface's metric set and calculates its weighted peer
   composite. Never use proposer forecasts in a composite, mean, veto, tie,
   or rank.
8. Apply the template's hard gates, review-coverage requirements, vetoes, and
   tie rules before selecting per-surface winners. Record missing evidence,
   calculations, disagreement, and human adjudication. An unknown is not a pass.
9. Assemble the winning package and its verification plan: baseline comparison,
   reproducible methods, thresholds, uncertainty, and rejection/fallback rules.
   A decision-only request does not authorize implementation; existing user
   authorization remains valid.

## Quality dimensions and meaningful evidence

Assess these dimensions explicitly. The examples describe measurement choices,
not universal targets or a mandatory technology stack. Translate each relevant
choice into a project outcome and trace it to a metric or gate in the brief.

| Dimension | What to assess | Possible evidence |
| --- | --- | --- |
| Functional logic and correctness | Required outputs, invariants, state transitions, edge cases, error/recovery behavior, and compatibility | Contract/reference tests, boundary cases, state-transition checks, failure-path evidence |
| Algorithms and result quality | Algorithm suitability, accuracy, precision, convergence, and time/space scaling over relevant input sizes | Reference comparisons, justified error bounds, complexity analysis, scaling experiments |
| Runtime performance | Response time, throughput, responsiveness, startup/steady-state behavior, capacity, and execution overhead | Matched benchmarks/traces, latency distributions, throughput at a stated load, CPU/GPU execution or I/O-wait measurements |
| Memory and resource behavior | Peak/retained memory, allocation or collection pressure, copying, buffering, leaks, and resource lifetime | Memory profiles, allocation counts, retained-growth checks, bounded-capacity/ownership evidence |
| UI and interaction quality | User-task success, discoverability, accessibility, feedback, errors, layout, and interaction responsiveness where a UI exists | Task scenarios, semantic interaction tests, accessibility evidence, inspected visual states, interaction timing |
| IPC and network overhead | Boundary calls, serialization, copies, transfer volume, waiting/queueing, retries, backpressure, and failure costs where communication exists | Call/byte counts, boundary traces, serialization/round-trip measurements, load/failure experiments |
| Security, privacy, and trust boundaries | Threat exposure, authorization, validation, isolation, privilege, sensitive data, and misuse/failure behavior | Threat/data-flow review, adversarial tests, permission/isolation checks, evidence-backed findings and remediation |
| Architecture and maintainability | Ownership, cohesion, coupling, dependency direction, contracts, testability, change locality, evolvability, and compatibility | Dependency/ownership analysis, representative change scenarios, interface tests, migration/rollback evidence |

UI or communication may be inapplicable to a particular project or surface.
An applicable dimension with unavailable evidence remains pending; do not label
it N/A or silently omit it. Cross-cutting needs such as reliability,
observability, compatibility, or operating cost can become additional metrics
or gates when they affect the decision.

## Metric and scoring discipline

- Connect each metric to a project goal and dimension. Avoid proxy metrics
  without explaining why they predict the required outcome. If multiple metrics
  capture the same effect, justify their separate weight to avoid double counting.
- Separate observed measurements, reasoned estimates, and missing evidence.
  Cite the artifact, analysis, test, or review behind a score and identify
  uncertainty. Do not manufacture a number when evidence is insufficient.
- For quantitative comparisons, declare inputs and scale, load/concurrency,
  environment/build, warm-up, collection method, repeat/sample strategy, and
  observer overhead as relevant. Compare candidates under matched conditions.
  State the direction, units, baseline, target, and acceptable regression.
- For qualitative dimensions, use inspectable criteria and anchored rubrics;
  explain which findings support the score. A numeric security or architecture
  score is a summary of that evidence, not a substitute for it.
- Use integer metric scores 1–5, with metric-specific anchors at 1, 3, and 5.
  A score of 1 is unacceptable, 3 is acceptable with material reservations,
  and 5 meets the declared strong/target outcome. Do not require a five-point
  scale for raw measurements.
- Treat mandatory correctness, security, resource, compatibility, or other
  project limits as gates. A failed gate disqualifies an action; an unresolved
  required gate prevents selection. A weighted benefit cannot compensate for
  a failed or unknown mandatory requirement.
- Decide applicability before scoring. A justified N/A removes a metric from
  that surface's rubric for every candidate. Missing evidence for an applicable
  metric makes that reviewer/action composite unavailable; do not impute a
  score, remove the metric, or renormalize weights for one candidate.
- Use the long-form peer metric scorecard and named peer-composite matrix in
  the template. Preserve the number of complete independent reviews and their
  denominator. Missing independent review is never an endorsement.

## Delegation, roles, and project extensions

Use independent agents only when delegation is available and authorized. An
automatic selection needs at least three participants so each candidate can
receive two independent non-proposer reviews. If that coverage is unavailable,
report it and leave selection for human adjudication; never invent votes.

Assign roles from the coverage map and material risks. Possible lenses include
functional/algorithmic correctness; performance/memory/communication costs;
user interaction/accessibility; security/trust; and architecture/evolution.
Combine or split lenses according to scope and available qualified reviewers;
do not create a mandatory agent per dimension or duplicate generalists.
Every applicable dimension needs explicit evidence responsibility, and every
participant still proposes and scores the complete applicable surface rubric.

Give each participant this contract:

```text
Role: [decision lens and evidence responsibilities]
Scope: [surface IDs and relevant artifacts; propose an action for every surface]
Goals and constraints: [project outcomes, hard gates, and non-goals]
Coverage and rubric: [dimension applicability, metric IDs, methods, anchors,
weights, and required verification]
Evidence boundary: cite sources and separate observation, estimate, and unknown.
Deliver: complete only your proposal block with a north star, per-surface
selection, non-voting metric forecasts and rationale, staged plan, acceptance
criteria, risks, and missing evidence. After proposals are complete, independently
score each peer action against the frozen applicable rubric and calculate its
peer composite. Never use your own forecast as a vote, edit a peer's proposal,
or declare a final winner. Document low scores, uncertainty, and dissent.
```

When invoked through a project extension, retain its goals, local metric
instantiations, constraints, artifact policy, and evidence requirements.
Resolve the shared template relative to this skill directory, not the caller's
working directory. Project details specialize the coverage framework; they do
not replace it with one domain's preferred metric set.

## Decision and verification

Apply hard gates first, then the requirement for two complete independent peer
reviews and the two-or-more peer low-score veto. Rank remaining candidates by
mean weighted peer composite. Break ties only with predeclared, independently
verifiable evidence; otherwise record unresolved selection and seek human
adjudication. Proposer forecasts never affect ranking. Package votes are
advisory and cannot override a surface gate or winner.

Check that the assembled package preserves the required outcomes across
surfaces; interactions can introduce costs or failures absent from isolated
candidates. Record package-level verification when needed without silently
changing the per-surface ranking rules.

Separate pre-decision feasibility evidence from post-implementation acceptance.
Use production-equivalent paths unless a test-only seam is the evaluated
surface. Trace each applicable dimension through its metric/gate, baseline,
method, threshold, result, and uncertainty. Missing required results leave the
corresponding decision or acceptance gate unresolved with a next evidence action.

## Output checklist

- Goals, sourced facts, decision question, constraints, surfaces, and unknowns
- Explicit coverage of all eight quality dimensions, with metric/gate IDs or
  justified N/A per relevant surface, plus any additional project dimensions
- Operational metrics, baseline/targets, reproducible conditions, evidence
  status, anchored qualitative criteria where needed, and normalized weights
- Independent proposals, non-voting forecasts, peer scorecards, named composite
  matrix, calculations, gates, vetoes, ties, dissent, and adjudication
- Per-surface winners, package interaction checks, and a bounded verification
  plan tracing relevant dimensions to acceptance evidence and fallback criteria
