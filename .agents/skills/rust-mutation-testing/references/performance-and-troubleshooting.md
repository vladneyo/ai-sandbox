# Performance and troubleshooting

## Symptoms

| Symptom | Likely cause | What to do |
| --- | --- | --- |
| Exit `4`: baseline fails, yet `cargo test` passes in the tree | Tests need something that is not copied (`.git`, `target/` artifacts, files outside the tree, a fixed absolute path), or a test is flaky. | Read the baseline's recorded `log_path` in `outcomes.json`. Try `--copy-vcs=true` or `--copy-target=true`. To isolate a copy problem, run with `--in-place` in a disposable checkout. Fix flaky tests first. |
| Most mutants are unviable | The crate denies warnings (`#![deny(warnings)]`, `deny(unused)`); a mutation leaves a parameter unused and the build fails. | `--cap-lints=true` or `cap_lints = true`. This also lifts rustc's limit on long const evaluation, so add `--build-timeout` if a build then hangs. |
| Timeouts (exit `3`) on a few mutants | The mutation removes a loop's exit condition, or exposes another blocking path. | Inspect the diff and recorded log; reproduce with a bounded harness. Keep a termination failure visible as a timeout unless an explicit policy justifies exclusion. |
| Timeouts on many mutants | The limit is too tight: tests slow down under `-j`, or the baseline was skipped. | Raise `--timeout` or `--timeout-multiplier`; lower `-j`. |
| A build never finishes | A mutated `const` expression loops in the compiler while lints are capped or `long_running_const_eval` is off. | Set `--build-timeout SECS` or `--build-timeout-multiplier X`; retain the compiler log and unresolved build timeout. Suppression needs a separate policy reason. |
| Everything is "caught", implausibly | Tests fail for another reason: a flaky test, or `--baseline=skip` on a broken tree. | Run with the baseline. Check one caught mutant's log to see which test failed and why. |
| Results differ between runs | Tests are not hermetic. They share a port, database, or file, and collide under `-j`. | Lower `-j`; isolate test resources; `-- -- --test-threads 1` if the clash is inside one binary. |
| Missed mutants in code that has tests | The tests are in another workspace package; or only doctests cover it and nextest or `--all-targets` is in use; or the tests need a feature. | `--test-workspace=true` or `--test-package`; the right feature flags; the default test tool. |
| Missed mutants in code for another OS or feature | `cfg` conditions are not evaluated. | Exclude those files or names in the config, with the reason. |
| Very few or no mutants | Filters are too narrow, the wrong package is selected, or the code is mostly macros, generated, or `unsafe`. | `--list-files` and `--list`; check `-p` and `--workspace`. If the code cannot be mutated, say that the tool has little to offer there. |
| Exit `5` with `--in-diff` | The diff's new side is not the tree being tested. | Regenerate the diff against the current working tree. |
| Exit `6` with `--in-diff` | The file is not a valid diff. | Regenerate it with plain `git diff`. |
| Compiler flags from `.cargo/config.toml` have no effect | The tool passes flags through the environment and does not read that file. | Set `RUSTFLAGS` for the run. |
| Disk fills up or the machine thrashes | Each job has a full copy of the tree and its own multi-gigabyte `target`. | Lower `-j`; `--gitignore=true` to copy less; point `TMPDIR` at a larger disk. |
| `--in-place` is rejected with `-j` or copy options | They are incompatible. | Choose one. |
| A mutation is left in the source after an interrupted `--in-place` run | The tool could not restore the file. | Search for `/* ~ changed by cargo-mutants ~ */` and restore the file from version control. |
| A test fails only under mutation and the reason is unclear | The mutant changes behavior in a way the diff does not make obvious. | Follow that outcome's `log_path` and `diff_path`. To reproduce by hand, apply the diff in a scratch copy or worktree, not in the user's working tree. |

## Making runs faster

Total time is about the number of viable mutants multiplied by one incremental
build plus one test run. In order of usual payoff:

1. **Test less per run.** Scope to a diff, files, or packages. Use `--iterate`
   while closing gaps.
2. **Make the test suite itself fast.** Every second saved is saved once per
   mutant. The console output shows build time and test time separately; work
   on the larger one.
3. **Skip doctests** when they are documentation and not the tests of record:
   `cargo mutants -- --all-targets`. Each doctest is a separate binary.
4. **Run two or three jobs**: `-j2` or `-j3`. Cargo and the test harness are
   already parallel, so scaling with core count does not work, and the tool
   warns above 8. Tests may need a longer `--timeout` under load.
5. **Use a lean profile.** In `Cargo.toml`:

   ```toml
   [profile.mutants]
   inherits = "test"
   debug = "none"
   ```

   and `profile = "mutants"` in `.cargo/mutants.toml`. Failing tests are the
   expected outcome, so debug info is rarely worth its build cost. If tests
   dominate the time, try a higher `opt-level` in that profile. Adding a
   profile edits the manifest; treat it as a project decision.
6. **Try nextest** (`--test-tool=nextest`). It stops sooner when many quick
   tests exist, and can be slower when slow integration tests keep running
   after the first failure. Measure it. It does not run doctests.
7. **Stop inside a test binary at the first failure** on a recent nightly:
   `cargo mutants -- -- -Zunstable-options --fail-fast`.
8. **Use a faster linker** (mold; wild on Linux). Incremental builds are
   dominated by link time when tests are quick.
9. **Put the scratch directory on a RAM disk** on Linux
   (`TMPDIR=/ram cargo mutants`) if memory allows for one `target` per job.
10. **Skip the baseline** (`--baseline=skip --timeout SECS`) when an earlier
    step has just run the same tests on the same tree. The saving is one test
    run, so this matters mainly for shards and repeated scoped runs.
11. **Reuse an existing build** with `--in-place` in a disposable checkout.
12. **Shard across machines** for full runs. See the CI reference.

Do not use `--no-fail-fast`, and do not lower timeouts to hurry a run: a
spurious timeout is recorded as a result and hides whether the mutant would
have been caught.
