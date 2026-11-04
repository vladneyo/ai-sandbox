---
name: ripgrep
description: Search source trees and command output efficiently with ripgrep, using scoped paths, literal or regex matching, explicit line numbers, file filters, and bounded output. Use when running rg from a shell or choosing a text-search command.
---

# Ripgrep

Use the installed `rg` from PATH; do not assume a package-manager location.
Follow the target repository's search policy, including any preferred
symbol-aware tools. When invoked through a project extension, keep that
extension's search roots and tool priorities in effect.

Start with the narrowest relevant path and choose the output mode needed:
matching lines, file names (`-l` / `--files`), or counts (`-c`). Use `-n` for
matching lines that need source locations: non-interactive stdout does not
provide line numbers by default. `-n` is unnecessary for file-list/count modes.
Prefer `-F` for literal text, and single-quote shell patterns containing `$`,
backticks, or backslashes to prevent shell expansion. Use `--` before a pattern
that starts with `-`.

`rg` respects ignore files and skips hidden/binary files by default. Scope any
`--hidden` / `-u` overrides to the required directory rather than scanning the
whole checkout unrestricted. Check the repository's actual ignore rules
instead of assuming its generated/cache directories are excluded.

## Recipes (task → command)

| Task | Command |
| --- | --- |
| Search with line numbers (default habit) | `rg -n "PATTERN" [PATH]` |
| List only matching file paths (cheapest, token-light) | `rg -l "PATTERN" [PATH]` |
| Count matches per file | `rg -c "PATTERN" [PATH]` |
| Restrict to a language | `rg -n "PATTERN" -t rust` (see `rg --type-list`; also: `md`, `json`, `toml`) |
| Restrict/exclude by glob | `rg -n "PATTERN" -g '*.rs' -g '!**/*_test.rs'` |
| Literal string, no regex escaping | `rg -n -F "some.weird[chars]" [PATH]` |
| Whole-word only (avoid `foo` matching `foo_bar`) | `rg -n -w "foo" [PATH]` |
| Case-insensitive | `rg -n -i "PATTERN"` (or `-S` for smart-case) |
| Show surrounding context | `rg -n -C 3 "PATTERN"` (or `-A`/`-B` for after/before only) |
| Search across a hard-wrapped/multi-line construct | `rg -n -U "struct Foo \{[\s\S]*?forbid"` |
| Extract only the matched substring (not the whole line) | `rg -n -o "version = \"[0-9.]+\""` |
| Cap output on a hot symbol | `rg -n -m 5 "PATTERN"` (per file) |
| Avoid dumping huge minified/generated lines (JSON, lock files) | `rg -n --max-columns 200 --max-columns-preview "PATTERN" config.json` |
| Multiple alternative patterns | `rg -n -e "PatternA" -e "PatternB"` (OR) |
| Search files rg would normally skip (ignored/hidden) | `rg -n -uu "PATTERN"` (add a third `-u` to also search binaries) |
| Deterministic, reproducible ordering | `rg -n --sort path "PATTERN"` |
| Sanity-check which files a glob/type filter would hit | `rg --files -t rust` |
| Search command output / a diff | `git diff \| rg -n "^\+.*unsafe"` |
| Regex features `rg`'s default engine lacks (lookaround, backrefs) | `rg -n -P "(?<!//)\bTODO\b"` |

## Flags glossary (search and output controls)

- `-n, --line-number` — print `file:line:content`. **Default off when piped.**
- `-l, --files-with-matches` / `-c, --count` — summary modes, cheapest on tokens.
- `-t/-T TYPE` — include/exclude by known type (`rust`, `md`, `json`, `toml`, `markdown`); `rg --type-list` to enumerate.
- `-g GLOB` — include/exclude by glob; prefix `!` to exclude. Repeatable.
- `-F, --fixed-strings` — treat pattern as a literal, not regex.
- `-w, --word-regexp` / `-x, --line-regexp` — anchor to word/line boundaries.
- `-i` / `-S` — case-insensitive / smart-case (case-insensitive unless pattern has an uppercase letter).
- `-A/-B/-C NUM` — context lines after/before/both.
- `-U, --multiline` — allow matches to span newlines; `.` still needs `--multiline-dotall` or `(?s)` to match a newline. Opt in only when needed.
- `-P, --pcre2` — swap in PCRE2 for lookaround/backreferences the default Rust regex engine can't express.
- `-o, --only-matching` — print just the matched span, not the whole line.
- `-m NUM, --max-count` — stop after NUM matches per file.
- `--max-columns NUM [--max-columns-preview]` — truncate (with a preview) instead of printing pathologically long lines.
- `-uu` / `-uuu` (`--unrestricted` x2/x3) — ignore `.gitignore`/hidden-file rules, then also search binaries. Use sparingly and scoped to a path.
- `--sort path` — deterministic ordering (costs some parallelism; fine at this repo's size).
- `-e PATTERN` (repeatable) — OR multiple patterns in one pass.
- `--files` — list files that would be searched, without searching; good for validating a glob/type filter first.
- `-h` vs `--help` — short vs. long flag descriptions. You shouldn't need either after this file; if a task genuinely doesn't map to a recipe above, `rg -h` is the fallback, not the first move.

If no recipe fits, use the installed version's `rg -h` or `rg --help`.
A no-match exit status (`1`) is a normal search result; distinguish it from an
invalid pattern or other execution error (`2`).
