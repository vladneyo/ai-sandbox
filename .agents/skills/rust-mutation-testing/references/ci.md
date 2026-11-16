# cargo-mutants in CI

Fit the project's existing pipeline: reuse its test job, toolchain setup,
caching, runner sizes, and action-pinning policy. The snippets are GitHub
Actions; the same commands and exit codes apply to any CI system.

## Choose a strategy

| Strategy | Command | Use when |
| --- | --- | --- |
| Changed code only | `cargo mutants --in-diff git.diff` | Every pull request. Fast, and it starts the conversation about how new code is tested. |
| Full run | `cargo mutants` | Small trees, or on the main branch or a schedule for larger ones. |
| Sharded full run | `cargo mutants --shard K/N` on `N` runners | The full run is too slow for one machine. |

The first two complement each other. A diff-scoped run cannot see that a
change in one place left code elsewhere untested, so keep a periodic full run.

Before making a job required, get a truthful starting point: run the full
suite once, triage the misses, and record justified exclusions in
`.cargo/mutants.toml`. A gate that fails on day one for old gaps gets
disabled. Until then, run the job as informational (`continue-on-error`) and
keep the artifact.

## Common settings

- Install a prebuilt binary with `taiki-e/install-action` (`tool:
  cargo-mutants`); building from source on each run is slow.
- `--in-place` is appropriate in CI: the checkout exists only for the job, so
  the copy is wasted work. It cannot be combined with `-j`.
- Upload `mutants.out` with `if: always()`; the job fails exactly when there
  is something to read.
- `-vV` prints caught and unviable mutants as well, which makes logs complete.
- Inside GitHub Actions, missed mutants are emitted as annotations
  automatically (`--annotations=none` turns that off).
- A non-zero exit fails the job: `2` missed, `3` timeout, `4` baseline failed.
- Limit triggers to paths that can change the result (`src/**`, `tests/**`,
  `Cargo.*`, `.cargo/mutants.toml`, the workflow file).

## Pull request: changed code only

```yaml
name: mutants-pr
on: pull_request
permissions:
  contents: read

jobs:
  incremental-mutants:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
        with:
          fetch-depth: 0   # the base branch must be available for the diff
      - name: Diff against the base branch
        env:
          BASE_REF: ${{ github.base_ref }}
        run: git diff "origin/$BASE_REF.." > git.diff
      - uses: Swatinem/rust-cache@v2
      - uses: taiki-e/install-action@v2
        with:
          tool: cargo-mutants
      - name: Mutants
        run: cargo mutants --no-shuffle -vV --in-diff git.diff
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: mutants-incremental.out
          path: mutants.out
```

## Full run

```yaml
jobs:
  cargo-mutants:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: Swatinem/rust-cache@v2
      - uses: taiki-e/install-action@v2
        with:
          tool: cargo-mutants
      - run: cargo mutants -vV --in-place
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: mutants-out
          path: mutants.out
```

## Sharded full run

```yaml
jobs:
  cargo-mutants:
    runs-on: ubuntu-latest
    needs: [test]            # the normal test job; it justifies --baseline=skip
    strategy:
      fail-fast: false       # collect every shard's misses
      matrix:
        shard: [0, 1, 2, 3, 4, 5, 6, 7]
    steps:
      - uses: actions/checkout@v6
      - uses: Swatinem/rust-cache@v2
      - uses: taiki-e/install-action@v2
        with:
          tool: cargo-mutants
      - name: Mutants
        run: >
          cargo mutants --no-shuffle -vV --in-place
          --shard ${{ matrix.shard }}/8
          --baseline=skip --timeout 300
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: mutants-shard${{ matrix.shard }}.out
          path: mutants.out
```

Rules for shards:

- The matrix size and the `/N` denominator must agree, and every shard must
  receive identical arguments. Otherwise the shards disagree about how the
  work is divided and the result is meaningless.
- `--baseline=skip` saves one full test run per shard, and is only valid
  because an earlier job proved that the tests pass. Set `--timeout`
  explicitly, since there is no baseline to derive it from.
- Each shard pays for setup and a clean build. Choose `N` so that each shard
  tests at least ten mutants; 8 to 32 shards is a reasonable first range.
- The run passes only if every shard passes.
- `--sharding round-robin` evens out shard durations; the default `slice`
  favors incremental build reuse.

The action versions shown are the ones in the cargo-mutants book at the time
of writing. Use the versions and pinning style the repository already uses.
