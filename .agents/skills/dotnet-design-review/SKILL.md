---
name: dotnet-design-review
description: >-
  Review C#/.NET code and architecture for design patterns, SOLID principles,
  performance, scalability, reliability, operability, and system-design
  trade-offs. Use this skill for code reviews, architecture reviews, design
  proposals, ADRs, performance-sensitive changes, service boundaries, data
  flows, and pre-implementation design decisions. Produce evidence-based,
  context-sensitive recommendations with measurable quality attributes and
  lightweight scoring rather than applying patterns mechanically.
---

# .NET/C# Design Pattern Review

Review the C#/.NET code or design in `${selection}` and suggest improvements for
the solution or project. Evaluate local code quality and the larger system value
of the decision: expected load, latency, reliability, data correctness,
operational cost, delivery speed, and future change.

Do not make code changes. Produce a review or design recommendation that makes
assumptions, trade-offs, evidence, and uncertainty explicit.

## Review principles

- Start from business and operational requirements, not a preferred pattern.
- Distinguish current measured constraints from hypothetical future scale.
- Prefer the simplest design that satisfies the required quality attributes and
  has a safe evolution path.
- Treat abstractions, distribution, caching, concurrency, and asynchronous
  messaging as costs that need demonstrated value.
- Look beyond the changed class when behavior crosses process, database,
  network, deployment, or ownership boundaries.
- Do not use a single aggregate score as a substitute for engineering judgment.
  Preserve the shape of the trade-off and call out the dimension driving the
  recommendation.

## Review workflow

### 1. Establish context

Identify:

- user-facing and business value;
- critical use cases and failure consequences;
- current and expected workload;
- latency, availability, durability, consistency, and recovery requirements;
- data volume, growth, retention, and access patterns;
- deployment model, runtime environment, regions, and dependencies;
- team size, ownership, release frequency, and operational maturity;
- compatibility, security, privacy, and compliance constraints;
- cost or delivery constraints;
- evidence already available from tests, traces, production metrics, profiles,
  benchmarks, incidents, or capacity plans.

If a value is unknown, mark it as unknown rather than inventing precision.
Recommend the smallest useful measurement or experiment needed to resolve it.

### 2. Trace the decision through the system

Review the end-to-end path, not only the selected implementation:

- entry point, validation, authorization, and rate limits;
- command or request orchestration;
- domain logic and state transitions;
- database and external provider calls;
- serialization, queues, caches, and process boundaries;
- retries, cancellation, timeout, idempotency, and partial failure;
- telemetry, deployment, rollback, and recovery;
- consumers, public contracts, migrations, and compatibility.

### 3. Evaluate patterns and implementation quality

Apply the pattern and .NET checklists below. Patterns are required review
coordinates, not mandatory implementation choices. Recommend a pattern only
when it reduces a concrete form of coupling, risk, duplication, or change cost.

### 4. Evaluate system qualities and trade-offs

Use measurable quality attributes and the scoring models in this skill. Compare
viable options, including the current design, and explain what each option
optimizes and sacrifices.

### 5. Recommend a proportionate next step

Choose among:

- keep the current design;
- make a local implementation improvement;
- add measurement, tests, or operational safeguards;
- introduce a modular boundary;
- isolate a proven hotspot;
- change the data or integration model;
- perform a larger architectural change.

Avoid proposing a platform-scale solution for a local problem without evidence
that the extra complexity will pay for itself.

## Required pattern checks

- **Command Pattern**: Where command handlers are part of the architecture,
  check generic base classes such as `CommandHandler<TOptions>`,
  `ICommandHandler<TOptions>` contracts, `CommandHandlerOptions` inheritance,
  validation, cancellation, consistent error handling, and static
  `SetupCommand(IHost host)` registration.
- **Factory Pattern**: Use for genuinely complex or variable object creation.
  Check service-provider integration, ownership, configuration, lifetime, and
  disposal. Do not hide ordinary constructor injection behind unnecessary
  factories.
- **Dependency Injection**: Check primary-constructor clarity,
  `ArgumentNullException` handling where required, interface abstractions at
  useful boundaries, service lifetimes, captive dependencies, scopes, and
  disposal.
- **Repository Pattern**: Check async data-access contracts, cancellation,
  provider abstractions for connections, transaction ownership, query safety,
  batching, and whether storage details leak into domain behavior.
- **Provider Pattern**: Check external database, HTTP, AI, storage, or messaging
  abstractions for clear contracts, configuration validation, resilience,
  observability, and replaceability.
- **Resource Pattern**: Check `ResourceManager` usage and separate `.resx` files
  such as `LogMessages` and `ErrorMessages` where localization is required.
- **Template Method and Strategy**: Check stable invariants, substitutability,
  extension pressure, and whether composition is clearer than inheritance.

## System-design checklist

### Workload and capacity

- Model average, peak, and burst traffic rather than relying on averages alone.
- Check requests per second, concurrent operations, payload size, fan-out,
  background work, scheduled spikes, and tenant skew.
- Use `concurrency ~= throughput x latency` as a rough capacity check when units
  are consistent. Account for queueing and headroom before saturation.
- Identify bottlenecks in CPU, memory, thread pool, connection pools, database,
  downstream quotas, network, storage IOPS, or queue consumers.
- Prefer bounded concurrency, bounded queues, backpressure, rate limiting, and
  load shedding over unbounded parallelism.

### Latency and throughput

- Define latency budgets for the end-to-end path and important dependencies.
- Evaluate p50, p95, and p99 latency; averages conceal tail-latency failures.
- Identify serial network calls, excessive fan-out, N+1 access, chatty APIs,
  lock contention, repeated serialization, and duplicated work.
- Check whether asynchronous processing changes user-visible semantics,
  consistency, ordering, retries, and observability.
- Require measurement before micro-optimizing code that is not on a critical
  path.

### Data architecture

- Review access patterns before selecting storage, indexes, partitions, or
  caches.
- Check transaction boundaries, consistency requirements, idempotency,
  concurrency control, duplicate delivery, ordering, and reconciliation.
- Model data size, growth, retention, archival, migration, and restore time.
- Examine partition keys for hotspots, uneven tenants, fan-out queries, and
  future re-partitioning cost.
- Treat cache invalidation, ownership, staleness, stampedes, eviction, and
  fallback behavior as part of the design.

### Reliability and recovery

- Define service-level objectives where the system warrants them: availability,
  latency, error rate, durability, and freshness.
- Check timeout budgets, retry limits, jitter, circuit breaking, bulkheads,
  health checks, and degraded modes.
- Prevent retry amplification across nested dependencies.
- Check idempotency before enabling retries for writes.
- Identify single points of failure and correlated failure domains.
- Define recovery time objective (RTO) and recovery point objective (RPO) for
  important state.
- Verify rollback, forward recovery, schema compatibility, and partial-deployment
  behavior.

### Evolution and organizational fit

- Compare a modular monolith, independently deployable service, asynchronous
  workflow, and shared library based on ownership and change boundaries.
- Watch for distributed monoliths: coupled releases, shared databases, chatty
  synchronous calls, and unclear ownership despite service separation.
- Consider team cognitive load, on-call capability, deployment tooling, and the
  number of independently changing domains.
- Prefer reversible decisions when requirements are uncertain. Use interfaces,
  adapters, feature flags, compatibility layers, and incremental migrations to
  preserve options.
- Record major irreversible or cross-team decisions in an architecture decision
  record with context, alternatives, consequences, and revisit triggers.

### Cost and sustainability

- Consider infrastructure cost, engineering time, support burden, incident
  cost, licensing, data transfer, observability volume, and idle capacity.
- Evaluate cost per request, job, tenant, or business transaction where useful.
- Do not trade substantial delivery and operational complexity for small
  infrastructure savings without evidence.

### Security and trust boundaries

- Identify authentication, authorization, tenant isolation, secrets, sensitive
  data, audit, and external-input boundaries.
- Review parameterized queries, safe serialization, file and process access,
  SSRF and injection risks, and AI prompt/tool boundaries.
- Consider blast radius and least privilege when selecting service, database,
  queue, and deployment boundaries.

## .NET performance and runtime checklist

- Check sync-over-async, blocked threads, thread-pool starvation, unnecessary
  `Task.Run`, missing cancellation, fire-and-forget tasks, and lock scope.
- Use `Task` and `ValueTask` according to measured call patterns; avoid
  `ValueTask` when its complexity does not provide a demonstrated benefit.
- Check allocation rate, large-object-heap pressure, boxing, closure allocation,
  repeated enumeration, large buffers, and excessive serialization.
- Recommend `Span<T>`, `Memory<T>`, pooling, custom serializers, or unsafe code
  only when profiling identifies a meaningful hotspot and ownership remains
  safe.
- Check `IDisposable` and `IAsyncDisposable` ownership for streams, scopes,
  database connections, timers, registrations, and response bodies.
- Check `HttpClient` lifetime, connection reuse, DNS behavior, timeout policy,
  resilience handlers, and downstream connection limits.
- For EF Core, inspect tracking mode, projections, query count, includes,
  client-side evaluation, pagination, batching, transactions, compiled queries,
  and context lifetime.
- Prefer bounded `Channel<T>`, queue, or worker designs for producer-consumer
  workloads. Define overflow and shutdown behavior.
- Check `IMemoryCache` and distributed-cache size limits, expiration, stampede
  protection, invalidation, and multi-instance behavior.
- Use structured logging, `ActivitySource`, `Meter`, OpenTelemetry, and
  correlation where they provide actionable diagnostics. Control cardinality
  and telemetry cost.
- Consider trimming, Native AOT, ReadyToRun, or startup optimization only when
  deployment size, startup time, or memory footprint is a real constraint.

## Measurement coordinates

Capture concrete targets when available:

| Coordinate | Useful measures |
|---|---|
| Demand | Average/peak RPS, jobs per second, concurrent users, burst duration |
| Latency | End-to-end and dependency p50/p95/p99, timeout budget |
| Capacity | CPU, memory, allocation rate, GC pause, thread-pool and pool saturation |
| Data | Current size, growth rate, read/write ratio, query count, retention |
| Reliability | Availability, error rate, retry rate, queue age, RTO, RPO |
| Efficiency | Throughput per instance, cost per transaction, cache hit rate |
| Delivery | Deployment frequency, lead time, rollback time, change failure rate |

Do not call an optimization successful without comparing a relevant before and
after measure under a representative workload.

## System pressure vector

Score each dimension from 1 to 5. Use `?` when evidence is missing.

| Dimension | 1 | 3 | 5 |
|---|---|---|---|
| **Criticality** | Inconvenience | Material workflow degradation | Safety, major revenue, legal, or core operation |
| **Scale pressure** | Small, stable load | Growing load with known peaks | Extreme volume, burst, skew, or hard quotas |
| **Latency sensitivity** | Minutes acceptable | Interactive seconds | Tight tail-latency or real-time deadline |
| **Data correctness** | Recomputable or disposable | Important with repair path | Financial, regulated, irreversible, or strongly consistent |
| **Availability** | Best effort | Defined business-hours expectation | Strict SLO, multi-region, or continuous operation |
| **Change pressure** | Rare, single-owner changes | Regular multi-feature evolution | Many teams, independent releases, rapid domain change |
| **Security exposure** | Internal low-sensitivity | Authenticated sensitive workflow | Internet-facing, privileged, regulated, or multi-tenant |
| **Operational readiness** | Minimal automation/on-call | Standard CI/CD and monitoring | Mature SRE, capacity, incident, and resilience practices |
| **Cost pressure** | Cost is secondary | Budget requires trade-offs | Unit economics or fixed budget drives architecture |

Interpret the vector rather than averaging it:

- A single score of 5 can dominate the architecture.
- Several scores of 4 or 5 justify explicit ADRs, measurable SLOs, capacity
  tests, and failure-mode analysis.
- High scale or availability with low operational readiness favors managed
  services and simpler boundaries over custom distributed infrastructure.
- High change pressure favors modularity and ownership boundaries.
- Low pressure across dimensions favors a simple, well-structured monolith and
  incremental evolution.

## Finding risk score

For each material finding, score:

- **Impact**: 1 cosmetic, 2 localized, 3 user-visible, 4 major outage/data issue,
  5 catastrophic, security-critical, or irreversible.
- **Likelihood**: 1 rare, 2 unlikely, 3 plausible, 4 likely, 5 expected or already
  observed.
- **Blast radius**: 1 single operation, 2 subset of users, 3 one tenant/service,
  4 many tenants/services, 5 system-wide or cross-boundary.

Calculate `risk = impact x likelihood x blast radius`:

- **1-12**: low;
- **13-32**: moderate;
- **33-64**: high;
- **65-125**: critical.

Record confidence separately as low, medium, or high. Do not hide weak evidence
inside a precise-looking risk number.

## Architecture option scorecard

When comparing designs, score each option from 1 to 5:

| Criterion | 1 | 5 | Direction |
|---|---|---|---|
| Business value | Marginal | Directly enables critical outcome | Higher is better |
| Quality-attribute fit | Misses important requirements | Meets measured targets with margin | Higher is better |
| Simplicity | High conceptual and implementation complexity | Simple and locally understandable | Higher is better |
| Operability | Difficult to deploy, observe, and recover | Routine and well-supported | Higher is better |
| Evolvability | Expensive coupled changes | Clear independent change boundaries | Higher is better |
| Reversibility | Costly or irreversible | Easy incremental rollback or replacement | Higher is better |
| Cost efficiency | Poor lifecycle economics | Strong lifecycle economics | Higher is better |

Assign weights from 1 to 3 based on the system pressure vector, then calculate:

`option score = sum(weight x rating) / sum(weights)`

Use the result to compare options, not to declare an automatic winner. Document:

- the highest-weighted criteria;
- assumptions and missing evidence;
- the option's main downside;
- conditions that would reverse the decision;
- a measurement or revisit trigger.

## Review Checklist

- **Design patterns**: Are Command Handler, Factory, Provider, Repository,
  Resource, Template Method, or Strategy patterns correctly implemented and
  justified?
- **Architecture**: Does the solution follow its namespace and project
  conventions, such as `{Core|Console|App|Service}.{Feature}`? Are boundaries,
  dependencies, deployment units, and ownership coherent?
- **.NET practices**: Are primary constructors, async APIs, cancellation,
  disposal, structured logging, nullable types, and strongly typed
  configuration used appropriately?
- **SOLID**: Are responsibilities cohesive, extension points justified,
  substitutions safe, interfaces focused, and dependencies inverted at useful
  boundaries?
- **Performance**: Are critical paths measured? Are latency, throughput,
  allocations, I/O, contention, saturation, and resource lifetimes acceptable?
- **Scalability**: Can the design handle expected peaks, growth, skew, and
  backpressure without premature distribution?
- **Reliability**: Are timeouts, retries, idempotency, partial failure, degraded
  modes, recovery, and rollout safety addressed?
- **Maintainability**: Are concerns separated, errors handled consistently,
  configuration explicit, and complexity proportional to value?
- **Testability**: Are dependencies replaceable, concurrency and failure paths
  testable, and tests compatible with arrange-act-assert?
- **Security**: Are inputs validated, credentials protected, queries
  parameterized, permissions minimal, and exceptions safe?
- **Documentation**: Are public APIs, important invariants, operational
  requirements, and architectural decisions documented?
- **Clarity and clean code**: Do names reflect domain concepts, methods and
  classes remain focused, and duplication or accidental complexity stay low?

## Improvement Focus Areas

- **Command handlers**: validation, cancellation, consistent errors, idempotency,
  orchestration boundaries, and resource ownership.
- **Factories**: dependency configuration, service-provider integration,
  lifetime and disposal, and whether complexity justifies the factory.
- **Providers**: connection management, async contracts, resilience,
  observability, quotas, exception translation, and safe fallback behavior.
- **Configuration**: data annotations or validators, startup validation,
  immutable options, safe secrets, and environment-specific constraints.
- **Persistence**: access patterns, query shape, transactions, consistency,
  batching, indexes, migrations, retention, and recovery.
- **Distributed workflows**: ownership, contracts, ordering, idempotency,
  retries, dead letters, compensation, observability, and operational burden.
- **AI/ML integration**: Semantic Kernel patterns, structured-output and schema
  validation, model configuration, token and latency budgets, rate limits,
  prompt injection, tool authorization, sensitive data, and nondeterministic
  test strategy.

## Report structure

Use this structure when enough system context is available:

```markdown
## Executive assessment
Scope, business value, current design, and highest-risk trade-off.

## System context
Known workload, SLOs, data, deployment, operations, constraints, and unknowns.

## System pressure vector
Dimension scores with evidence; do not average away dominant constraints.

## Findings
For each finding: location or decision, evidence, impact, likelihood, blast
radius, risk score, confidence, and actionable recommendation.

## Architecture options
Compare the current approach and realistic alternatives using weighted criteria.

## Recommended direction
Explain what to do now, what not to build yet, and why the recommendation is
proportionate.

## Measurement and revisit plan
Define benchmarks, telemetry, load or failure tests, thresholds, and conditions
that should trigger reconsideration.
```

If evidence is limited, provide a provisional assessment and explicitly list the
measurements or requirements needed before making an irreversible decision.
