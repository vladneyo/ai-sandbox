---
name: app-screenshot
description: Capture native macOS application screenshots with process readiness, warm-up, display or window selection, bounded repeats, and optional owned launch and cleanup. Use for native UI evidence and visual inspection of a running macOS app.
license: MIT
metadata:
  author: "Vladyslav Neichev (@vladneyo)"
  origin: original
---

# Native macOS App Screenshots

Use this skill's `scripts/capture_screenshot.sh` with `/usr/sbin/screencapture`.
It observes an existing application by default. Launch and cleanup are an
explicit opt-in; capture alone does not prove functional or performance
correctness. Inspect required PNGs with the available image viewer at original
detail, preserve the originals, and report what was checked.

When invoked through a project extension, use its entrypoint, target process,
launch policy, artifact root, and defaults. Resolve this skill's bundled helper
relative to this shared directory. The target project is a separate input;
never infer it from the shared skill's installation directory.

## Target and evidence contract

- Run capture only on macOS. Native window evidence requires the appropriate
  Screen Recording permission and a visible target window.
- Supply `--project-root` explicitly when the working directory is not the
  target project. It defaults to the current directory, not the skill's root.
- `--artifact-root` defaults to `<project-root>/artifacts`. Relative artifact
  and output paths resolve against the project root. Output must remain within
  the configured artifact root; path traversal and escaping symlinks fail.
- Supply `--ready-pattern REGEX`, or use `--window-process REGEX` as both the
  readiness and window-owner pattern. Prefer anchored process patterns.
- Readiness means a process was observed, followed by a configurable warm-up;
  it is not proof of a first rendered frame or application-specific readiness.
  Resolve permission dialogs and wrong-window state before collecting evidence.
- Without `--launch`, never start or terminate the target app. Check for an
  active test session before attaching and preserve the caller's lifecycle.
- Run names, prefixes, and PNG stems are single safe path components. Capture
  files receive unique suffixes unless `--overwrite` is explicitly supplied.

## Observe a running app

Invoke the helper by its resolved path, for example:

```bash
/path/to/app-screenshot/scripts/capture_screenshot.sh \
  --project-root /path/to/project \
  --run ui-smoke --name app-window --warmup-secs 5 \
  --window-process '(^|/)ExampleApp( |$)'
```

Choose the capture surface according to the claim:

| Need | Selector |
| --- | --- |
| Full desktop / absolute placement evidence | Omit the window selectors |
| One display | `--display N` |
| Known macOS window ID | `--window-id ID` |
| Front visible window owned by a matching process | `--window-process REGEX` |
| Human interactive window selection | `--window` |

Window selectors are mutually exclusive and cannot be combined with
`--display`. Process resolution selects the first matching PID and its first
front-to-back normal-layer window, with a non-normal-layer fallback. For
multiple instances/windows, resolve the intended window ID explicitly.
A window crop cannot establish placement relative to the display/menu bar.

Use `--ready-pattern` independently when readiness and window-owner patterns
differ. `--timeout-secs` bounds readiness (default 120); `--warmup-secs` begins
only after observation (default 5). Use bounded `--repeat N` and
`--interval-secs N` for temporal evidence.

## Optional owned launch

Only when the task authorizes launch and cleanup, add:

```bash
/path/to/app-screenshot/scripts/capture_screenshot.sh \
  --project-root /path/to/project --run ui-smoke \
  --ready-pattern '(^|/)ExampleApp( |$)' \
  --launch -- /path/to/ExampleApp
```

The command after `--` is an argument vector, not evaluated shell text. Keep
it foregrounded: do not pass `open`, `nohup`, a detached shell, or a command
that intentionally abandons its child. A matching pre-existing process blocks
launch; do not kill it to make the run proceed.

The runner owns the capture subprocess and, with `--launch`, the launched
process tree. On success, failure, INT, or TERM it stops capture first and
uses bounded TERM/KILL cleanup for that exact launch PID and descendants.
`--keep-running` transfers cleanup responsibility to the caller; record that
ownership explicitly. If a run is interrupted outside normal cleanup, verify
retained process identities before terminating only owned PIDs. Readiness
failure or an early launch exit is a failed run, not a valid blank capture.

## Artifacts and reporting

Default paths are `artifacts/screenshots/<name>.png` or, with `--run NAME`,
`artifacts/screenshots/NAME/<name>.png`. `--output-dir` can place evidence
beside another run's logs inside the artifact root. Combining it with `--run`
adds another nested directory. Repeats receive numbered suffixes.

Report absolute PNG paths, source state when available, run name, target,
launch/readiness mode, warm-up, capture surface, image inspection, and cleanup
result. Preserve failed evidence. Keep crops/annotations as separate files.
Project extensions define ignored-artifact and review-retention conventions.

Use `--dry-run` to validate and print the plan without launching, waiting,
creating output directories, or capturing. Use `--help` for all options,
including `--name-prefix` (default `app`) and `--overwrite`.

Keep stimulus playback, diagnostics, telemetry assertions, and performance
sampling in the caller's verification workflow rather than adding them here.

For CLI regression checks without native capture, run `python3 -m unittest
discover -s /path/to/app-screenshot/tests -v`.
