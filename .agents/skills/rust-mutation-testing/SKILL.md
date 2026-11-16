---
name: rust-mutation-testing
description: >-
  Run and interpret mutation testing for Rust with cargo-mutants: find code
  whose bugs the tests would not catch, triage missed mutants, write
  behavior-level tests that catch them, record justified skips, and set up
  configuration and CI. Use when asked to mutation-test a Rust crate or
  workspace, to judge whether tests really check behavior beyond line
  coverage, to act on `cargo mutants` output or a `mutants.out` directory, to
  check the tests for a diff or pull request, or to tune, speed up, or debug a
  cargo-mutants run. Not for other languages, fuzzing, or coverage reports.
---

# Rust Mutation Testing

cargo-mutants injects one small bug at a time (a *mutant*) into a copy of the
source tree, then builds it and runs the tests. A mutant that no test fails on
marks behavior the tests do not check. Line coverage shows that code ran;
mutation testing shows whether a test would notice if the code were wrong.

Run and report by default. Add tests, suppressions, configuration,
dependencies, or CI only when the task also authorizes edits. When invoked
through a project extension, keep its packages, features, test tool, time
budget, and suppression policy in effect. Resolve this skill's references
relative to this shared directory:

- [CLI and config](references/cli-and-config.md): flags, filters, skip
  attributes, config keys, exit codes, `mutants.out`, version notes. Read
  before composing a non-trivial command or editing `.cargo/mutants.toml`.
- [Mutation patterns](references/mutation-patterns.md): what is and is not
  mutated, how to read a mutant name, and which test catches each kind. Read
  before triage or writing tests.
- [CI](references/ci.md): pull-request, full, and sharded pipelines. Read when
  adding or changing automation.
- [Performance and troubleshooting](references/performance-and-troubleshooting.md):
  read when a run is slow, the baseline fails, or results look wrong.

The installed tool is the authority. cargo-mutants changes flags, defaults,
mutant names, and output formats between releases, and this skill was written
against 27.1.0. Check `cargo mutants --version`; when `cargo mutants --help`
disagrees with this text, follow the tool.

## Modes

| Request | Path |
| --- | --- |
| "How good are the tests?" | Steps 1–5, then report. No source edits. |
| "Close the gaps" | Steps 1–8. |
| "Check this change or pull request" | Step 3 with `--in-diff`, then 4–5; 6–8 if edits are authorized. |
| "Set it up for the project" | Steps 1–5 for a truthful starting point, then config and [CI](references/ci.md). |
| "The run is slow, failing, or noisy" | [Troubleshooting](references/performance-and-troubleshooting.md), then resume. |

## 1. Preflight

- Read the project's policy first: an existing `.cargo/mutants.toml`, CI
  workflows, contributor docs, the usual test command, required features, and
  whether tests run under `cargo test` or nextest.
- Run `cargo mutants --version`. If the tool is missing, installing it changes
  the user's machine: ask unless the task already covers it, then use
  `cargo install --locked cargo-mutants` (or `cargo binstall cargo-mutants`).
- Results are only as reliable as the tests. A flaky test fails at random and
  is counted as "caught", so the report would be noise. If the suite is known
  to be flaky or non-hermetic, say so and fix or exclude that first.
- `mutants.out` and `mutants.out.old` appear in the source directory. If
  `/mutants.out*` is not ignored and edits are not authorized, write elsewhere
  with `--output DIR` and say where.

## 2. Safety

- Mutants run under the real tests with real effects. A mutation can change a
  path, a condition, or the target of an existing delete or write. Check that
  tests confine side effects to temporary resources. Do not run with
  production credentials, live services, or shared databases; prefer a
  container, VM, or CI when tests touch the system.
- By default the source tree is never edited: the tool works on a copy and
  writes only the output directory. `--in-place` mutates the real tree and an
  interrupted run can leave a mutation behind. Use it only in a disposable
  checkout such as CI, never in a working tree with uncommitted work. The
  marker to search for is `/* ~ changed by cargo-mutants ~ */`.

## 3. Scope first, then run

Cost is roughly one full build and test run for the baseline, plus one
incremental build and test run per mutant. Three hundred mutants at twenty
seconds each is well over an hour, so size the run before starting it:

```sh
cargo mutants --list | wc -l      # mutants in scope
cargo mutants --list-files        # files in scope
cargo mutants --list --diff -f src/parser.rs   # the exact changes
```

`--list` accepts every filter, so use it to preview a scope.
For a large unfamiliar scope, use a short pilot with the intended profile,
test selection, and job count to estimate wall time. Account separately for
startup and incremental build/test costs; parallel jobs do not scale linearly.
Report the estimate and chosen scope before starting the full run.

| Goal | Command |
| --- | --- |
| Changes on a branch | `git diff "$(git merge-base <base> HEAD)" > "$D"` then `cargo mutants --in-diff "$D"` |
| Uncommitted changes | `git diff HEAD > "$D"` then `cargo mutants --in-diff "$D"` |
| One file or directory | `cargo mutants -f src/parser.rs`, `-f 'src/db/**/*.rs'` |
| One workspace package | `cargo mutants -p my-crate` |
| One function or kind of mutant | `cargo mutants -F 'parse_header'`, `-F 'impl Serialize'` |
| Representative sample of a large tree | `cargo mutants --shard 0/20 --sharding round-robin` |
| Whole tree | `cargo mutants` (add `--workspace` to cover every package) |

Here `$D` is a diff file outside the tracked tree. The new side of the diff
must match the tree under test, which is why both recipes diff against the
working tree. `--in-diff` looks only at non-test code: a diff that changes
only tests selects no mutants, and that means "nothing tested", not "tests
are fine".

Short flags do not mean what Cargo habits suggest: `-F` is a regex filter (not
features), `-v` prints caught mutants (not verbose), `-V` prints unviable
mutants (not version), and `-e`/`-E` exclude by glob/regex.

A run is long. Start it in the background or with a generous command timeout
and follow `mutants.out/missed.txt`, which is updated as the run proceeds. Add
`-j2` or `-j3` for parallel jobs when tests are hermetic; higher values rarely
help, and each job needs its own copy of the tree and its own `target`
directory. If the estimate does not fit the time available, narrow the scope
or sample. A run that is stopped early covers only the first files in source
order; never report it as complete.

## 4. Read the results

| Outcome | Meaning | Action |
| --- | --- | --- |
| caught | A test failed with the bug in place. | None. |
| missed | Every test passed with the bug in place. | Triage in step 5. |
| timeout | Tests ran past the limit and were killed. | Inspect for a termination defect, slow tests, or resource contention. Keep unresolved timeouts visible; hanging alone is not a reason to suppress. |
| unviable | The mutated code did not compile. | Confirm the compiler diagnostic. Neither caught nor a survivor; if most are unviable, see strict lints in troubleshooting. |

Exit status: `0` every viable mutant was caught, `2` some were missed, `3`
some timed out, `4` the baseline tests failed before any mutation, `1`, `5`,
`6`, and `70` are usage, diff, and internal errors. Exit `2` or `3` is a
finding, not a tool failure. Exit `4` means there are no results at all.

Read results from the output directory, not from console text:
`missed.txt`, `timeout.txt`, `caught.txt`, and `unviable.txt` hold one mutant
name per line; `outcomes.json` holds the summary and recorded log/diff paths.
Follow those paths rather than assuming a log directory name. Each new run
renames the directory to `mutants.out.old` and deletes the older copy, so save results
that are still needed. For source snapshots, output schemas, and combining
runs, see [run evidence](references/cli-and-config.md#run-evidence-and-reconciliation).
To see where the gaps cluster:

```sh
cut -d: -f1 mutants.out/missed.txt | sort | uniq -c | sort -rn
```

## 5. Triage missed mutants

Start with the surprising ones (an important function replaced by `Ok(())`
and nothing fails) and with clusters in one module. For each mutant, read its
diff and the tests that should have noticed, then decide the cause:

| Cause | Evidence | Action |
| --- | --- | --- |
| Weak assertion | Tests run the code but assert little: `is_ok()`, "does not panic", a length. | Assert the actual result or effect. |
| Not reached | No test exercises the path. | Add a behavior test, or ask whether the code is needed. |
| Tests are elsewhere | The mutant is in a workspace package tested from another package, covered only by doctests while nextest or `--all-targets` is in use, or behind a feature that was off. | Rerun with `--test-workspace=true`, `--test-package`, the right features, or the default test tool. Not a test gap. |
| Real defect or dead code | The mutated code is as plausible as the original, or the original has no effect. | Report it. Do not hide it with a test that pins the current behavior. |
| Equivalent mutant | The change cannot alter any observable behavior. | Skip narrowly with the reason (step 7). |
| Out of policy | `Debug` output, log text, capacity hints, performance-only code the project chooses not to test. | Suppress by class in config (step 7). |
| Wrong platform | `cfg` is not evaluated, so code for another OS is mutated and reported as missed. | Exclude those files or names. |

A missed mutant is evidence of a test gap in that spot. It is not by itself a
correctness defect, and a clean run is not proof of correctness. When the run
supports a code review, report missed mutants in the changed code as test-gap
evidence under that review's own severity rules.

## 6. Write tests that catch them

Treat the mutant as one example of a wrong implementation, not as the thing
to test. Ask what observable behavior would break if this code were wrong,
and assert that behavior at the level the project already tests, preferably
through a public interface. For a mutant in a private helper, test the public
behavior that depends on the helper.

- Choose inputs that tell the original from the mutant: values on both sides
  of a boundary, operands for which `+` and `*` differ, a non-default value
  for each field. [Mutation patterns](references/mutation-patterns.md) lists
  the distinguishing test for each kind of mutant.
- Assert precise results or effects. A test that restates the implementation,
  or names the mutant, passes today and protects nothing tomorrow.
- Follow the project's test layout, helpers, and naming.
- Leave production code alone unless the finding is that it is wrong or dead
  and the task covers fixing it. Restructuring code so a mutant disappears is
  not a fix.

## 7. Suppress deliberately

Suppress only what was classified as equivalent, out of policy, or
wrong-platform in step 5. A timeout needs investigation and an explicit
policy justification before exclusion. Use the narrowest mechanism, record
the reason next to it, and list every suppression in the report. Never suppress to reach
exit `0`; an unexplained skip hides exactly what the run exists to show.

| Situation | Mechanism |
| --- | --- |
| One function, impl, or item; reason should be visible in code | `#[mutants::skip]` with a comment. Needs the `mutants` crate as a regular dependency, so follow the project's dependency policy. |
| A whole file, module, or directory | `exclude_globs` in `.cargo/mutants.toml` |
| A class of mutants, such as `impl Debug` | `exclude_re` in `.cargo/mutants.toml` |
| Arguments of calls to a named function, such as capacity hints | `skip_calls` in `.cargo/mutants.toml` |
| A one-off focused run | Command-line filters; do not persist them |

Check the effect with `cargo mutants --list`. Keep project-wide decisions in
`.cargo/mutants.toml` and commit it, so a bare `cargo mutants` gives everyone
the same result.

## 8. Verify

- After adding tests, rerun the same scope with `--iterate`. It skips mutants
  that were caught or unviable in the previous run, so each pass is short.
- `--iterate` assumes later edits did not reduce coverage. Finish with one run
  of the same scope without `--iterate`.
- If diagnostic runs use fewer tests, replay their misses with the project's
  full relevant test selection before claiming project-level test gaps.
  Label reconciled coverage across runs separately from a single clean run.
- Run the project's normal test, format, and lint commands for the new tests.

## Limits to state in a report

- Not mutated, so silence there means nothing: `unsafe` functions, test code,
  macro invocations and `macro_rules!` bodies, macro expansions, and code
  generated by build scripts.
- Only tests that `cargo test` or nextest runs count. Manual and external
  integration tests are invisible to the tool.
- The tree must build for the host; cross-compilation and non-Cargo builds are
  not supported.
- A scoped or sampled run speaks only for its scope.

## Report template

```markdown
Mutation testing: <scope>

Run
- Tool and command: cargo-mutants <version>, `<exact command>`
- Source: <commit plus saved dirty diff, or content hashes; includes tests>
- Test context: <packages, features, profile, test tool, filters, exclusions>
- Evidence: <preserved output directory; baseline result; complete/partial/iterated>
- Mutants: N tested: C caught, M missed, T timeout, U unviable
- Not covered: <excluded, sampled, or not run, and why>
- If combining runs: <per-run counts and deduplicated identities; unresolved conflicts>

Missed mutants
1. `<mutant name>`
   Meaning: <the wrong behavior that would go unnoticed>
   Cause: <weak assertion | not reached | tests elsewhere | defect | equivalent | out of policy>
   Action: <test added at path::name | proposed test | suppression and reason | question>

Timeouts
- `<mutant name>`: <cause and action>

Suppressions
- <mechanism and location>: <reason>

Verification
- <rerun command and result; project test and lint commands>

Open questions
- ...
```

The tool prints counts, not a score. If one figure is requested, give
caught ÷ (caught + missed) together with the timeout and unviable counts and
the scope, and present it as a description of this run rather than a grade.
