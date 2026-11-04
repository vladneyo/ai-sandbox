# [Topic] Concilium Brief

**Created:** [YYYY-MM-DD]
**Updated:** [YYYY-MM-DD]
**Status:** [discussion / scoring / decision complete / implementation authorized]
**Facilitator:** [name]
**Participants:** [agent / role], [agent / role], [agent / role]
**Artifact type:** [plan / audit]

> Fill every required bracketed field. Preserve the separation between facts,
> proposals, scores, and decisions. This brief recommends work; it does not
> authorize implementation unless the status says so.

## 1. Decision Frame

### 1.1 Observed facts

| ID | Fact | Evidence / source | Confidence | Why it matters |
|---|---|---|---|---|
| F1 | [observed fact] | [path:line, test, trace, metric, or primary source] | [high / medium / low] | [decision impact] |

### 1.2 Decision question and project goals

[One question that can be answered through per-surface decisions.]

| Goal ID | Required user/project outcome | Success evidence / target | Priority / owner |
|---|---|---|---|
| O1 | [outcome this decision must improve or preserve] | [observable result and acceptance criterion] | [priority / owner] |

Ground metric choices in these outcomes, expected inputs/workloads, operating
conditions, and constraints. More throughput, fewer allocations, or a cleaner
abstraction is useful only where it serves the declared project needs.

### 1.3 Constraints and non-goals

| Type | Item | Evidence / owner |
|---|---|---|
| Hard constraint | [must remain true; violation disqualifies an action] | [source / owner] |
| Soft preference | [important but tradeable outcome] | [source / owner] |
| Non-goal | [explicitly out of scope] | [source / owner] |

### 1.4 Assumptions and unknowns

| ID | Assumption or unknown | Validation needed | Decision impact if false | Owner |
|---|---|---|---|---|
| U1 | [unknown] | [measurement / inspection] | [impact] | [agent] |

## 2. Inventory of Decision Surfaces

Split the problem into independently selectable actions. An inventory value
describes urgency or deviation only; it is not a proposal score.

| ID | Surface | Current behavior / problem | Functional grounding | Severity or deviation (1–5) | Required outcome |
|---|---|---|---|---:|---|
| S1 | [surface] | [specific problem] | [what must be preserved] | [1–5] | [success condition] |

### 2.1 Severity / deviation scale

| Score | Meaning for this brief |
|---:|---|
| 1 | [minimal divergence / risk] |
| 3 | [material but contained concern] |
| 5 | [critical break from contract, safety, or intended architecture] |

## 3. Concilium Design

### 3.1 Participant roles and expected output

Every participant receives the same evidence pack and must independently
complete their own proposal block in §5, including its non-voting metric
forecast, plus peer-action metric reviews in §6. Assign evidence responsibility
for every applicable dimension in §3.3.1; combine/split roles to fit the problem
and reviewer competence. A proposer never performs a peer review of its own
action.

| Participant | Role / decision lens | Scope | Evidence responsibilities | Expected deliverable |
|---|---|---|---|---|
| [Agent A] | [e.g., compatibility and lifecycle] | [S# evidence lead] | [paths / tests / measurements] | [complete §5.A and score peer actions in §6] |
| [Agent B] | [e.g., performance, resources, and boundary costs] | [S# evidence lead] | [paths / benchmarks / traces] | [complete §5.B and score peer actions in §6] |
| [Agent C] | [e.g., architecture, correctness, and tests] | [S# evidence lead] | [paths / fixtures / API review] | [complete §5.C and score peer actions in §6] |

### 3.2 Agent instruction contract

```text
Role: [copy from §3.1]
Scope: [surface IDs and artifacts; lead evidence for assigned surfaces, but
propose an action for every surface]
Coverage: [§3.3.1 applicable dimensions, metric/gate IDs, and evidence duties]
Goals: [§1.2 outcome IDs]
Evidence boundary: distinguish observed results, reasoned estimates, and missing
evidence; cite sources and label uncertainty.
Hard constraints: [constraints from §1.3]
Deliver: north star; one action per surface (or explicit no change /
N/A); a numeric metric forecast and evidence-based rationale; staged plan;
non-goals; acceptance criteria; risks. Then independently score every other
participant's proposed action against the §3.3 metrics applicable to that
surface, calculate the
weighted peer composite, and record it in its named peer-composite cell in §6. Do
not score your own action as a peer.
Do not alter another participant’s proposal or declare the final decision.
```

### 3.3 Quality coverage and operational metrics

#### 3.3.1 Dimension applicability and coverage

Consider every dimension below before proposals. For each relevant surface,
record `scored`, `gate`, `both`, or `N/A` and explain why. Link applicable rows
to concrete metric IDs (`M#`) or hard-gate IDs (`G#`). A dimension can have more
than one metric; one metric can support multiple dimensions only with an
explicit rationale. Add project-specific dimensions when needed.

| Dimension | Assessment intent | Surface applicability / reason | Metric / gate IDs and goal | Evidence owner |
|---|---|---|---|---|
| Functional logic and correctness | Required behavior, state/invariants, edge cases, error/recovery paths, compatibility | [S#: scored/gate/both/N/A; reason] | [M#/G# → O#] | [owner] |
| Algorithms and result quality | Suitability, accuracy/error bounds, convergence, and time/space scaling | [S# and disposition; reason] | [IDs → goal] | [owner] |
| Runtime performance | Latency/distributions, throughput/capacity, responsiveness, startup/steady-state and execution overhead | [S# and disposition; reason] | [IDs → goal] | [owner] |
| Memory and resource behavior | Peak/retained memory, allocation/collection, copies/buffers, growth, and resource lifetime | [S# and disposition; reason] | [IDs → goal] | [owner] |
| UI and interaction quality | User-task success, discoverability, accessibility, feedback/errors, layout, and interaction responsiveness where a UI exists | [S# and disposition; reason] | [IDs → goal] | [owner] |
| IPC and network overhead | Boundary calls, serialization/copies, transfer volume, waiting/queueing, retries/backpressure, and failure costs where communication exists | [S# and disposition; reason] | [IDs → goal] | [owner] |
| Security, privacy, and trust boundaries | Threat exposure, authorization/validation, isolation/privilege, sensitive data, and misuse/failure behavior | [S# and disposition; reason] | [IDs → goal] | [owner] |
| Architecture and maintainability | Ownership, cohesion/coupling, dependency direction, contracts, testability, change locality, evolution, and compatibility | [S# and disposition; reason] | [IDs → goal] | [owner] |

`N/A` means the dimension does not apply to that surface and needs a concrete
reason. If it applies but evidence is unavailable, retain it as `pending`
evidence; do not call it N/A. Preserve coverage of a dimension that is gated
even if it does not contribute a weighted score.

#### 3.3.2 Measurement definitions

Choose the smallest set that covers all applicable dimensions and project
outcomes; there is no fixed metric count. Define the actual observable before
assigning a score. Quantitative metrics use units and better direction.
Qualitative metrics use inspectable criteria and an evidence-backed rubric.

| ID | Dimension / goal / surface | Observable and unit or review criterion; better direction | Baseline and source | Target / acceptable regression | Conditions and reproducible method | Evidence status / uncertainty |
|---|---|---|---|---|---|---|
| M1 | [dimension(s), O#, S#] | [what is measured; unit or criterion; lower/higher/defined condition is better] | [observed baseline + source, or unknown + next action] | [project-specific target and limit] | [inputs/scale, load, environment/build, warm-up, sampling, tool/test/review method] | [observed / estimated with rationale / missing; confidence or limits] |

For numerical comparisons, match representative inputs, input sizes, load /
concurrency, environment, collection methods, and observer overhead. Specify
repetitions/sample strategy and variability where they can change the decision.
Use complexity/reference analysis when direct measurements are not yet
possible, clearly labeled as an estimate with a later verification method.

Define hard gates separately. Mandatory correctness, security, resource,
compatibility, or other requirements cannot be traded away through averaging.
A candidate that fails a gate is disqualified; an unknown required gate remains
unresolved until evidence is available.

| Gate ID | Dimension / goal / surface | Mandatory requirement and pass threshold | Verification method / evidence | Evidence owner |
|---|---|---|---|---|
| G1 | [dimension, O#, S#] | [required invariant or bound] | [test, analysis, measurement, or inspectable review criterion] | [owner] |

#### 3.3.3 Scoring anchors and weights

Define a consistent rubric for each surface. All candidates for a surface use
the same applicable metric set, anchors, weights, and measurement conditions.
Duplicate this table by surface if their applicable sets differ. Higher scores
always mean better project outcomes, including when lower raw values are
better. Hard-gate pass/fail results remain separate from weighted scores.

| Metric ID / surface | Weight | Score 1 — unacceptable | Score 3 — acceptable with reservations | Score 5 — strong / target | Evidence that distinguishes the anchors |
|---|---:|---|---|---|---|
| [M#, S#] | [0.00–1.00] | [measured range or inspectable failed criteria] | [acceptable range/criteria and reservations] | [target range/criteria] | [method/artifact and uncertainty] |

**Weight rule:** included scored metrics sum to `1.00` for each surface. State
why priorities serve the project goals; avoid double counting correlated proxy
metrics. Use equal weights only with a reason. Weights calculate peer
composites; proposer forecasts never carry decision weight.

Freeze applicability, conditions, anchors, and weights before proposals. If
new evidence requires a rubric change, record the reason and independently
rescore every affected candidate under the same revision.

### 3.4 Coverage and measurement principles

The coverage map is a reasoning aid, not a demand to invent a benchmark for
every dimension. A headless surface can justify UI N/A; a surface with no
cross-process or remote communication can justify IPC/network N/A. Existing
constraints can be verified as gates. Applicable architecture or security
questions can use explicit review criteria and findings instead of fabricated
numeric measurements. Project-specific examples and thresholds belong in the
project extension or completed brief.

Trace every applicable dimension to its operational metric/gate and evidence.
Do not silently drop a difficult-to-measure cost, score an unknown as a benefit,
or treat a high aggregate score as proof of correctness, security, or fitness.

### 3.5 Score semantics and gates

- **Proposer metric forecast:** the proposer forecasts its own action against
  every applicable §3.3 metric for the surface, using 1–5 when supported by
  evidence or a reasoned estimate, otherwise `—` with the missing-evidence
  reason. Explain trade-offs, uncertainty, and mitigations. Forecasts are
  non-voting evidence only: never use them in a composite, mean, veto, tie-break,
  or package rank.
- **Peer metric assessment:** each participant rates every *other
  participant's* action 1–5 against the surface's applicable §3.3 metrics.
  Cite evidence in the review note for a score `<=3`, a missing score, or a
  concern that could change the decision.
- **Weighted peer composite:** calculate one value per `(peer reviewer,
  action)` as `sum(metric_weight * peer_metric_score)`. Record that value in a
  separate named peer-score cell in the §6.2 decision matrix.
- **Not applicable:** establish and justify it in §3.3.1 before scoring; omit
  that metric from the surface's rubric equally for all candidates.
- **Missing applicable evidence:** use `—` with the reason. That reviewer/action
  composite is unavailable; do not impute a value, drop an applicable metric,
  or renormalize weights to improve a candidate's score. Expose the number of
  complete independent reviews in the peer mean.
- **Hard-constraint gate:** mark an action `disqualified` if it violates any
  §1.3 or §3.3 gate. Mark an unverified required gate `unresolved`; neither a
  failed nor an unknown required gate can be outweighed by a peer mean.

## 4. Proposal Format

Copy §5.A once per participant. Complete proposals before exposing
cross-scores or a provisional winner.

## 5. Participant Proposals

### 5.A [Agent A] — [role]

#### North star

[2–4 sentences: desired end state and central trade-off.]

#### Per-surface action and metric forecast

Use the metric IDs defined for that surface in §3.3. The four metric columns
below illustrate the format; add/remove columns or separate surface tables to
cover the complete applicable set. Distinguish measured evidence, reasoned
forecasts, and unknowns. Do not use a forecast as a peer vote.

| ID | Action / suggested solution | [Metric M1] | [Metric M2] | [Metric M3] | [Metric M4] | Forecast rationale / mitigation |
|---|---|---:|---:|---:|---:|---|
| S1 | [keep / reshape / remove / new solution / no change] | [1–5/—] | [1–5/—] | [1–5/—] | [1–5/—] | [why this action satisfies the metrics; uncertainty and mitigation] |

#### Per-surface hard-gate evidence

| Surface | Gate ID | Status | Evidence / uncertainty / next action |
|---|---|---|---|
| S1 | [G#] | [pass / fail / unresolved] | [supporting evidence; missing result and how to obtain it] |

Peer review must verify gate claims as well as metric scores. Unknown required
gates remain unresolved even if a proposer predicts a pass.

#### Ordered implementation stages

1. [stage]
2. [stage]

#### Non-goals

- [non-goal]

#### Acceptance criteria and risks

| Criterion / risk | Evidence required | Pass condition / mitigation |
|---|---|---|
| [criterion or risk] | [test / measurement] | [threshold or mitigation] |

### 5.B [Agent B] — [role]

[Copy the complete §5.A structure.]

### 5.C [Agent C] — [role]

[Copy the complete §5.A structure. Add one block per additional participant.]

## 6. Concilium Decision Matrix

Fill only after §5 is complete. First complete the peer metric scorecard, then
derive the peer-composite decision matrix from it. Do not use a
scorer-by-action grid or a proposer-exclusion cell.

### 6.1 Peer metric scorecard

Use one long-form row for each `(proposed action, peer reviewer)` pair. The
reviewer must not be the proposer. Add one metric column for every §3.3 metric
applicable to that surface and calculate the weighted peer composite from that
row only. The illustrated four columns are not a limit. When surfaces have
different metric sets, separate their tables while retaining the declared
rubric for every candidate on each surface.

| Surface | Proposer | Proposed action (short) | Peer reviewer | [Metric M1] | [Metric M2] | [Metric M3] | [Metric M4] | Weighted peer composite | Review note / dissent |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| S1 | [Agent A] | [short action] | [Agent B] | [1–5/—] | [1–5/—] | [1–5/—] | [1–5/—] | [calculation / —] | [source for `<=3`, missing evidence, or `—`; otherwise `—`] |
|  | [Agent A] | [short action] | [Agent C] | [1–5/—] | [1–5/—] | [1–5/—] | [1–5/—] | [calculation / —] | [note / —] |
|  | [Agent B] | [short action] | [Agent A] | [1–5/—] | [1–5/—] | [1–5/—] | [1–5/—] | [calculation / —] | [note / —] |
| S2 | [repeat for every proposal and each non-proposer reviewer] | [short action] | [peer] | [score] | [score] | [score] | [score] | [calculation] | [note / —] |

Match the columns to the complete metric set for the surface. A missing
applicable score makes that reviewer/action composite unavailable; do not infer
a value or remove its weight. Link raw observations or qualitative findings and
their uncertainty in the review note. Record hard-gate results independently.

### 6.2 Long-form peer-composite decision matrix

Use one row per proposed action; group rows by surface. Add exactly
`participant count − 1` peer-composite columns, one for each independent
review. Put the reviewer name and its §6.1 composite in every cell (for
example, `[Agent B]: 4.35`). An action needs at least two complete independent
peer metric reviews to be selected automatically.

| Surface | Proposer | Proposed action (short) | Peer composite 1 | Peer composite 2 | Peer mean (n) | Gate / decision |
|---|---|---|---|---|---:|---|
| S1 | [Agent A] | [short action] | [Agent B]: [1.00–5.00/—] | [Agent C]: [1.00–5.00/—] | [e.g., 4.35 (2)] | [pass / disqualified / vetoed / selected / unresolved] |
|  | [Agent B] | [short action] | [Agent A]: [1.00–5.00/—] | [Agent C]: [1.00–5.00/—] | [calculation] | [status] |
|  | [Agent C] | [short action] | [Agent A]: [1.00–5.00/—] | [Agent B]: [1.00–5.00/—] | [calculation] | [status] |
| S2 | [repeat one row per proposal] | [short action] | [name]: [composite] | [name]: [composite] | [calculation] | [status] |

For four or more participants, append `Peer composite 3`, `Peer composite 4`,
and so on; every value remains named with its reviewer. A table with four or
more peer-composite columns may be split by surface only when necessary for
readable rendering; preserve the same columns and calculation in every split
table.

### 6.3 Selection calculation

For each action that passes hard constraints:

```text
peer_composite(reviewer, action) =
  sum(metric_weight * peer_metric_score)

peer_mean(action) =
  sum(numeric peer_composites from non-proposers) /
  count(numeric peer_composites from non-proposers)
```

1. Reject actions with failed hard gates. Leave actions with unknown required
   gates unresolved; they cannot be selected automatically.
2. Require at least two independent non-proposer complete metric reviews for
   each remaining action. Otherwise mark that action `insufficient peer metric
   review` and do not select it automatically.
3. Veto an action when two or more independent non-proposer reviewers give it
   a weighted peer composite `<=2`; select the next-best non-vetoed action.
4. Winner = highest remaining peer mean for the surface.
5. Break a tie only with predeclared, independently verifiable evidence
   ([measurement, constraint, or factual criterion]). Never use a
   proposer-supplied rating, composite, or rank.
6. If still tied, mark `unresolved` and request human adjudication. Do not
   invent a winner.

Record a dissent when a participant gives a winner `<=2` or identifies missing
evidence that could change the decision.

### 6.4 Optional package vote

Use only to compare coherence of complete packages; it cannot override a
per-surface gate or winner. Use the same long-form convention: one row per
proposer package and one named peer-rank column for each independent rank. A
proposer ranks only peer packages. Each package needs at least two independent
peer ranks; otherwise leave the package decision pending. Do not run this vote
until every required surface has a final selection.

| Proposer | Package summary | Peer rank 1 | Peer rank 2 | Peer rank sum | Result |
|---|---|---|---|---:|---|
| [Agent A] | [summary] | [Agent B]: [1..N-1] | [Agent C]: [1..N-1] | [peer sum] | [winner / pending / tie] |
| [Agent B] | [summary] | [Agent A]: [1..N-1] | [Agent C]: [1..N-1] | [peer sum] | [result] |

For four or more participants, append one named peer-rank column per
additional reviewer. Lowest peer rank sum wins. Ties require human
adjudication. Do not use a proposer-supplied rank.

## 7. Shared Recommendation

### 7.1 Winning actions

| Surface | Winning action | Decision evidence | Constraints preserved | Owner |
|---|---|---|---|---|
| S1 | [action] | [mean, votes, tie-break, dissent] | [constraints] | [owner] |

Check the assembled package against the project goals and cross-surface
interactions. Record any combined memory, latency, boundary, user-flow,
security, or architectural consequences that the isolated scores did not
capture, and add corresponding verification. A package vote cannot waive a gate.

### 7.2 Ordered delivery plan

1. [first bounded stage]
2. [next stage]

### 7.3 Explicitly rejected or deferred actions

| Surface / action | Reason | Revisit trigger |
|---|---|---|
| [action] | [veto, evidence gap, or out of scope] | [new evidence / condition] |

## 8. Verification Stage

Before the decision, record concrete feasibility evidence and define pass/fail
thresholds for implementation acceptance. After implementation, fill the
measured acceptance results before declaring it validated. Verify through
production-equivalent paths unless a test-only seam is the action under
evaluation. Record existing implementation authorization without asking again.

### 8.1 Verification plan

Trace every applicable dimension's metrics/gates from §3.3 to acceptance.
Record raw results with units or inspectable findings, not only a pass label or
normalized score. Compare under the declared conditions and report meaningful
uncertainty. Unknown required evidence remains pending with a next action.

| Metric / gate ID and dimension | Baseline / source | Method / command | Conditions / representative workload | Pass threshold / allowed regression | Owner | Result / uncertainty / next action |
|---|---|---|---|---|---|---|
| [M#/G#, dimension] | [observed baseline + source, or unknown] | [reproducible command, analysis, or review procedure] | [environment/build, inputs/scale/load, sampling and observer controls] | [explicit unit/bound or inspectable criteria] | [agent] | [raw value/finding; pass/fail/pending; limits and follow-up] |

### 8.2 Quality gates

- [Focused deterministic tests and expected result]
- [Compatibility / lifecycle / API gate, if applicable]
- [Performance, allocation, latency, or precision comparison, if applicable]
- [Required formatting, lint, and CI commands]

### 8.3 Failure handling

| Failed or missing evidence | Immediate action | Decision impact |
|---|---|---|
| [case] | [diagnose / gather data / revert to candidate] | [keep unapproved / reopen surface] |

## 9. Finalization Record

| Check | Result | Evidence / note |
|---|---|---|
| Every surface has a completed proposal from every participant or documented N/A | [pass / fail] | [note] |
| All eight dimensions are assessed per relevant surface, with metric/gate IDs or justified N/A and no missing evidence disguised as N/A | [pass / fail] | [§3.3.1 coverage] |
| Applicable metrics/gates trace to project goals, baselines/targets, reproducible methods, and declared evidence status | [pass / fail] | [§3.3 / §8.1] |
| Every surface uses a consistent rubric across candidates, scored weights total 1.00, and scales have 1/3/5 anchors | [pass / fail] | [note] |
| Every selectable action has two complete named peer metric reviews and no proposer forecast affects a composite, mean, veto, tie, or package rank | [pass / fail] | [note] |
| Decision matrix, vetoes, ties, and dissent are calculated | [pass / fail] | [note] |
| All winners have evidence-backed passing hard gates and the assembled package preserves required outcomes | [pass / fail] | [note] |
| Verification plan has commands, baselines, and pass thresholds | [pass / fail] | [note] |
| Human authorization for implementation (if needed) | [pending / granted] | [owner / date] |
