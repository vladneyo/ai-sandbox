# cargo-mutants CLI and configuration

Contents: version notes · selecting mutants · globs · names and regexes ·
skip attributes · tests and Cargo arguments · execution control · tree copy ·
output · config file · environment · exit codes · `mutants.out`.

Written against cargo-mutants 27.1.0 (released 2026-06-02), the book at
<https://mutants.rs/>, and <https://crates.io/crates/cargo-mutants>. Use
`cargo mutants --help` for the installed version.

## Version notes

| Version | Change that affects commands or results |
| --- | --- |
| any | Building the tool needs a recent toolchain (Rust 1.88 for 26.1 and later). The tested project can use an older one: `cargo +1.70 mutants`. |
| 25.1.0 | `--gitignore` defaults to off. Config path can be set with `--config`. Feature keys allowed in config. |
| 25.3.0 | GitHub Actions annotations for missed mutants. |
| 26.0.0 | Mutants run in source order by default; `--shuffle` restores random order. Default sharding is `slice`. `--cargo-test-arg` added. Functions with any `…::test` attribute are skipped. Struct-literal field deletion added. |
| 27.0.0 | `--file`, `--exclude`, `--re`, and `--exclude-re` are combined with the config values. Earlier releases let the command line replace the config for these four. |
| after 27.1.0 | `#[mutants::exclude_re("…")]` and `#[mutants::skip]` on `const`/`static` are documented but were unreleased at the time of writing. |

Some book pages lag the changelog (for example, shuffle is still described as
the default). The changelog and `--help` win.

## Selecting what to mutate

| Flag | Effect |
| --- | --- |
| `-f, --file GLOB` | Mutate only files that match. Repeatable. |
| `-e, --exclude GLOB` | Exclude files that match. Applied after `--file`. Repeatable. |
| `-F, --re REGEX` | Keep only mutants whose name matches. Repeatable. |
| `-E, --exclude-re REGEX` | Drop mutants whose name matches. Applied after `--re`. Repeatable. |
| `-D, --in-diff FILE` | Keep only mutants that overlap regions changed in the diff. Applied after the other filters. |
| `-p, --package NAME` | Mutate these packages. Comma-separated or repeated. |
| `--workspace` | Mutate every package in the workspace. |
| `--iterate` | Skip mutants that were caught or unviable in the previous run. |
| `--shard K/N` | Run one of `N` equal parts; `K` runs from `0` to `N-1`. |
| `--skip-calls a,b` | Do not mutate inside calls to these functions or methods. |
| `--error EXPR` | Also replace `Result` function bodies with `Err(EXPR)`. Repeatable. |
| `-d, --dir DIR` / `--manifest-path PATH` | Test a tree other than the current directory. |

Short flags that mislead: `-F` is not features, `-v` is `--caught`, `-V` is
`--unviable`, `-C` is `--cargo-arg`, `-e` and `-E` are the two excludes.

Default package selection follows Cargo: inside a package, that package; at
the root of a virtual workspace, `default-members` if set, otherwise all
packages.

`--in-diff` accepts `git diff` output (with or without the `b/` prefix). The
new side must match the tree under test, or the run stops with exit `5`.
Changes to non-Rust files are ignored. The diff is matched against code under
test only, so edits that only touch tests select nothing.

## Globs

- A glob with a path separator matches the path from the tree root:
  `src/*/*.rs`, `src/**/*.rs`.
- A glob without one matches a file or directory name in any directory:
  `-e console` excludes every directory named `console`, not `console.rs`.
- A file match needs the suffix: `-f network` matches `src/network/mod.rs` but
  not `src/network.rs`.
- Excluded files are still parsed and their `mod` statements are followed, so
  `-e src/main.rs` keeps the modules that `main.rs` declares.
- Quote globs so the shell does not expand them.

## Mutant names and regexes

A name is what `--list` prints, for example:

```text
src/outcome.rs:157:9: replace <impl Serialize for ScenarioOutcome>::serialize -> Result<S::Ok, S::Error> with Ok(Default::default())
```

Regexes use the `regex` crate syntax and match any substring: the path, the
trait (`impl Serialize`), the type, the function, or the replacement
(`with Ok\(`). Anchor with `^` and `$` to match the whole name.

`--iterate` identifies mutants by this full name, including line and column.
Edits that move code cause those mutants to be tested again.

## Skip attributes in source

Add `mutants` (0.0.3 or later) under `[dependencies]`, not
`[dev-dependencies]`, because the attribute sits on non-test code. The crate
is tiny and the attribute does not change compiled code.

```rust
#[mutants::skip] // Diagnostic wording is outside this project's test policy.
fn diagnostic_label() -> &'static str { "ready" }

#[cfg_attr(test, mutants::skip)] // Same effect: the condition is not evaluated.
fn also_skipped() {}
```

The book lists these placements for `#[mutants::skip]`: functions, `impl`
blocks, `trait` blocks (default methods), `mod` blocks, a whole file as
`#![mutants::skip]`, `const` and `static` items (honoured only in releases
after 27.1.0), and expressions that can carry an outer attribute (`match`,
struct literals, calls, method calls, unary expressions). Whether rustc accepts a custom attribute in a given
position depends on the toolchain, so run `cargo check --all-targets` after
adding one outside an item, and use a config filter if it is rejected.

`#[mutants::exclude_re("with 0")]` drops only the mutants in that scope whose
name matches, and keeps the rest. It needs `mutants` 0.0.5 and a cargo-mutants
release later than 27.1.0. Confirm both exist before relying on it; otherwise
use `exclude_re` in the config file.

`--skip-calls` and `skip_calls` match the last path segment of a call and
ignore type parameters, so `with_capacity` matches
`Vec::<String>::with_capacity(4 * n)`. They stop mutation of the call's
arguments, not of the called function's body. `with_capacity` is skipped by
default; `--skip-calls-defaults=false` turns that off.

## Which tests run, and arguments passed down

| Flag | Effect |
| --- | --- |
| (default) | The baseline runs the tests of the packages being mutated. Each mutant runs only the tests of its own package. |
| `--test-workspace=true` | Run all workspace tests for the baseline and every mutant. Overrides `--test-package`. |
| `--test-package a,b` | Run the tests of these packages for the baseline and every mutant. |
| `--test-tool=nextest` | Use `cargo nextest` instead of `cargo test`. |
| `--features X`, `--all-features`, `--no-default-features` | Passed to every Cargo invocation. |
| `--profile NAME` | Build with this Cargo profile. |
| `-C, --cargo-arg ARG` | Extra argument for every Cargo invocation. Repeatable. |
| `--cargo-test-arg ARG` | Extra argument for `cargo test` or nextest. Repeatable. |
| `-- ARGS` | Everything after `--` goes to `cargo test` or nextest. |
| `-- -- ARGS` | Everything after the second `--` goes to the test binary. |

Examples: `cargo mutants -- --all-targets` skips doctests;
`cargo mutants -- -- --test-threads 1` serializes tests inside each binary.
Never pass `--no-fail-fast`: one failing test is enough to catch a mutant.

nextest does not run doctests, so behavior that only doctests check shows as
missed. Keep nextest's fail-fast on. The book selects a nextest profile with
`--cargo-arg=--profile=NAME`.

## Execution control

| Flag | Effect |
| --- | --- |
| `-j, --jobs N` | Parallel build and test jobs. Start at 2 or 3. Not allowed with `--in-place`. |
| `--jobserver=false`, `--jobserver-tasks=N` | The tool runs a jobserver that caps compiler tasks at one per CPU across all jobs. Disable or resize it. |
| `-t, --timeout SECS` | Fixed test timeout. |
| `--timeout-multiplier X` | Test timeout as a multiple of the baseline test time. Default is 5×. |
| `--minimum-test-timeout SECS` | Floor for the automatic timeout. Default is 20 s. |
| `--build-timeout SECS`, `--build-timeout-multiplier X` | Build timeout. Off by default because build times vary. |
| `--baseline=skip` | Do not test the unmutated tree first. Only safe when another step has just proved that the tests pass. Set `--timeout` as well. |
| `--in-place` | Mutate the real tree instead of a copy. See the safety rules in the skill. |
| `--cap-lints=true` | Turn off rustc lints so that denied warnings do not make mutants unviable. |
| `--shuffle`, `--no-shuffle` | Random or source order. Source order is the default from 26.0.0. |
| `--sharding slice` or `round-robin` | How mutants are split across shards. `slice` gives each shard a contiguous block (better incremental builds); `round-robin` interleaves them (even run times, representative samples). |
| `--check` | Run `cargo check` on each mutant and no tests. Shows which mutants are viable. |

With `--baseline=skip` or `--in-place` the multipliers do not apply. Without
an explicit `--timeout`, the test timeout is then 300 s and there is no build
timeout.

All shards of one run must use identical arguments and the same `N`.

## Tree copy

The tree is copied to a temporary directory, one copy per job. Not copied by
default: `target/`, VCS directories (`.git`, `.hg`, `.jj`, `.bzr`, `.svn`,
`_darcs`, `.pijul`), `mutants.out`, and `mutants.out.old`.

| Flag | Effect |
| --- | --- |
| `--copy-vcs=true` | Copy VCS directories, for tests that need the repository. |
| `--copy-target=true` | Copy `target/`, for tests that need existing build artifacts. |
| `--gitignore=true` | Skip files matched by gitignore rules while copying. |

Relative path dependencies in the top-level `Cargo.toml` and
`.cargo/config.toml` are rewritten to absolute paths in the copy.

## Output and inspection

| Flag | Effect |
| --- | --- |
| `--list` | Print the mutants that would be tested and stop. |
| `--list-files` | Print the source files that would be mutated and stop. |
| `--diff` | With `--list`, include the diff of each mutant. |
| `--json` | With `--list`, print JSON (same format as `mutants.json`). |
| `-v, --caught` / `-V, --unviable` | Also print caught or unviable mutants. |
| `-o, --output DIR` | Create `mutants.out` inside `DIR`. |
| `--no-times` | Omit durations, for stable output. |
| `--line-col=false` | Omit line and column from names. |
| `--all-logs` | Print cargo output for every invocation. |
| `-L, --level debug` | More trace output on stderr. |
| `--annotations=github` or `none` | Force CI annotations on or off. Automatic inside GitHub Actions. |
| `--colors=always`, `never`, or `auto` | Color control. |
| `--leak-dirs` | Keep the scratch copies for debugging. |
| `--Zmutate-file FILE` | List mutants of one file without a package (27.0.0 and later). |
| `--completions SHELL` | Print a shell completion script. |
| `--emit-schema=config` | Print the JSON schema of the config file. |

## Config file

Default location: `.cargo/mutants.toml` at the tree root. `--config FILE`
reads another file; `--no-config` reads none. Unknown keys are an error. The
schema is at <https://json.schemastore.org/cargo-mutants-config.json>.

| Key | Same as |
| --- | --- |
| `examine_globs`, `exclude_globs` | `--file`, `--exclude` |
| `examine_re`, `exclude_re` | `--re`, `--exclude-re` |
| `skip_calls`, `skip_calls_defaults` | `--skip-calls`, `--skip-calls-defaults` |
| `error_values` | `--error` |
| `test_tool` | `--test-tool` (`"cargo"` or `"nextest"`) |
| `test_package`, `test_workspace` | `--test-package`, `--test-workspace` |
| `features`, `all_features`, `no_default_features` | the feature flags |
| `profile` | `--profile` |
| `additional_cargo_args` | `--cargo-arg` |
| `additional_cargo_test_args` | `--cargo-test-arg` and arguments after `--` |
| `timeout_multiplier`, `build_timeout_multiplier`, `minimum_test_timeout` | the timeout flags |
| `cap_lints` | `--cap-lints` |
| `copy_vcs`, `copy_target`, `gitignore` | the copy flags |
| `output` | `--output` |
| `sharding` | `--sharding` |

There is no config key for `--timeout`, `--jobs`, `--baseline`, `--in-place`,
`--in-diff`, or `--shard`; these describe one run, not the project.

Merging: for single values the command line wins. For lists the two sources
are combined (see the 27.0.0 note above). To run without the project's
filters, use `--no-config` or `--config OTHER`.

```toml
# .cargo/mutants.toml: commit it, so a bare `cargo mutants` works for everyone.
exclude_globs = ["src/generated/**/*.rs"]   # generated code, tested upstream
exclude_re = ["impl Debug"]                 # Debug output is not a contract here
error_values = ["::anyhow::anyhow!(\"mutated\")"]
timeout_multiplier = 3.0
# test_tool = "nextest"
# profile = "mutants"
```

## Environment

| Variable | Effect |
| --- | --- |
| `CARGO_MUTANTS_JOBS` | Same as `--jobs`. |
| `CARGO_MUTANTS_OUTPUT` | Same as `--output`. |
| `CARGO_MUTANTS_MINIMUM_TEST_TIMEOUT` | Same as `--minimum-test-timeout`. |
| `CARGO_MUTANTS_TRACE_LEVEL` | Same as `--level`. |
| `CARGO_TERM_COLOR`, `NO_COLOR`, `CLICOLOR_FORCE` | Color control. |
| `RUSTFLAGS`, `CARGO_ENCODED_RUSTFLAGS` | Read and passed on. Flags set in `.cargo/config.toml` are ignored. |
| `TMPDIR` | Where the scratch copies and their `target` directories live. |

## Exit codes

| Code | Meaning |
| --- | --- |
| 0 | Every viable mutant that was tested was caught. |
| 1 | Usage error. |
| 2 | Some mutants were missed. |
| 3 | Some tests timed out. |
| 4 | The baseline tests failed or hung; no mutants were tested. |
| 5 | The new side of the `--in-diff` diff does not match the tree. |
| 6 | The `--in-diff` file is not a valid diff. |
| 70 | Internal error. |

## The `mutants.out` directory

Created in the source directory, or inside `--output DIR`. On each run the
existing directory becomes `mutants.out.old` and the previous `.old` is
deleted. Files are updated while the run proceeds, so they can be read to
follow progress. Formats can change between releases.

| Path | Content |
| --- | --- |
| `missed.txt`, `caught.txt`, `timeout.txt`, `unviable.txt` | Mutant names by outcome, one per line. |
| `previously_caught.txt` | Accumulated by `--iterate`. |
| `mutants.json` | Every generated mutant, written before testing starts. |
| `outcomes.json` | Result of each scenario, summary counts, tool version. |
| `diff/` | One diff per mutant against the unmutated tree. |
| Recorded `log_path` (27.1.0 uses `log/`) | One log per mutant and one for the baseline: the diff plus cargo output. |
| `lock.json` | Lock held during a run; start time, version, user, host. |

Add `/mutants.out*` to `.gitignore`.

## Run evidence and reconciliation

Preserve a distinct output directory per run that will be cited; do not let a
later run rotate away its evidence. Record the tool version, exact command and
effective config, test packages/features/profile/filters, baseline result, and
completion status. Identify the actual source and tests used by the run with
a commit plus saved dirty diff, or content hashes. A worker's copied source
does not acquire edits made later in the original tree.

Inspect the installed output schema before parsing it. In 27.1.0 the baseline
`scenario` is a string while mutant scenarios are objects. Use each outcome's
`log_path` and `diff_path`, resolved against `mutants.out`, rather than assuming
`logs/`, deriving filenames, or treating every scenario as a mutant. Check
unexplained catches against the failing assertion and unviable results against
the compiler error; infrastructure failures do not establish test strength.

Keep primary outcomes unchanged when reconciling focused replays. Combine
evidence only for the same source/test snapshot and tool version; identify a
mutant by its full name and exact diff, and retain each run's test context.
Count repeated catches once. A later catch with a broader test selection can
resolve a diagnostic miss, but preserve both outcomes and the assertion that
catches it. Conflicting results in the same context need investigation.
Source movement or extraction changes identities: replay the changed scope
instead of adding historical catches to the new total. Verify that the union
covers the selected preview, list exclusions and untested candidates separately,
and label the result as reconciled coverage rather than one zero-miss run.
