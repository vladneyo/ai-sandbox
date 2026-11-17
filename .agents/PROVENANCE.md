# Provenance and licensing

Who wrote what in `.agents/`, and under which license. Author of the original
work: Vladyslav Neichev ([@vladneyo](https://github.com/vladneyo)). Compared
with upstream on 2026-11-18.

## Origin types

| Origin | Meaning | Marker in the folder | License |
| --- | --- | --- | --- |
| `original` | Written by the author. | `LICENSE`, plus `license` and `metadata` in the SKILL.md frontmatter. | MIT, Copyright (c) 2026 Vladyslav Neichev. |
| `compiled` | Assembled and rewritten by the author from several sources. | The `original` markers, plus a `NOTICE.md` that credits each source. | The author's part is MIT. Each third-party part keeps its own license, as stated in `NOTICE.md`. |
| `adapted` | Someone else's work, changed here. | None. Files stay as received, with the upstream license. | The upstream license. |
| `imported` | Someone else's work, copied unchanged or nearly so. | None. Files stay as received. If upstream did not ship its license with them, a `NOTICE.md` next to them quotes it. | The upstream license. |

Work that an agent drafted or edited at the author's direction counts as the
author's. It takes the origin type it would have had if written by hand.

Third-party files are never edited to add the author's name or license. They
are recorded only in the table below. Files inside an `original` or `compiled`
skill (`references/`, `scripts/`, `tests/`, `agents/openai.yaml`) fall under
that skill's `LICENSE`, unless its `NOTICE.md` says otherwise.

MIT is used for the author's own work because it lets anyone use, change, and
share it with one condition: keep the notice. To change it, replace the
`LICENSE` text and the `license` value (an SPDX identifier) in the frontmatter.

## Registry

| Path | Origin | Source | License | Notes |
| --- | --- | --- | --- | --- |
| `skills/app-screenshot` | original | Vladyslav Neichev | MIT | |
| `skills/concilium` | original | Vladyslav Neichev | MIT | |
| `skills/osascript-ui-automation` | original | Vladyslav Neichev | MIT | |
| `skills/ripgrep` | original | Vladyslav Neichev | MIT | |
| `skills/rust-code-review` | compiled | Vladyslav Neichev, with the Google Rust Style Guide summarized in `references/google-rust-style.md` | MIT. The Google guide is CC BY 3.0. | See open item 2. |
| `skills/rust-mutation-testing` | compiled | Vladyslav Neichev, from the cargo-mutants user guide ([mutants.rs](https://mutants.rs/)), its [crates.io page](https://crates.io/crates/cargo-mutants), and its v27.1.0 source | MIT. cargo-mutants is MIT, Copyright (c) 2021 Martin Pool. | Notice text is in its `NOTICE.md`. |
| `skills/dotnet-design-review` | compiled | Vladyslav Neichev, from principles the author specified, drafted and edited by an agent. Its title, `${selection}` placeholder, section names, and starting pattern list derive from the [dotnet-design-pattern-review](https://github.com/github/awesome-copilot/blob/main/skills/dotnet-design-pattern-review/SKILL.md) skill of github/awesome-copilot. | MIT. awesome-copilot is MIT, Copyright GitHub, Inc. | Notice text is in its `NOTICE.md`. About 2% of the lines are identical to that skill (2026-11-18). |
| `skills/asd-ste100` | adapted | [danyuchn/asd-ste100-skill](https://github.com/danyuchn/asd-ste100-skill) | MIT, Copyright (c) 2026 Dustin Yuchen Teng (`LICENSE`) | Heavily reworked: about 25% of the upstream lines remain. Its SKILL.md already has a "Sources and License" section. |
| `skills/dotnet-code-review` | imported | Its SKILL.md says it synthesizes the `requesting-code-review` and `receiving-code-review` skills of [CommandCodeAI/agent-skills](https://github.com/CommandCodeAI/agent-skills). | MIT, Copyright (c) 2025 Mengxin Zhu (`LICENSE.txt`, the CommandCodeAI license) | See open item 1. |
| `agents/CSharpExpert.agent.md` | imported | [github/awesome-copilot](https://github.com/github/awesome-copilot), `agents/CSharpExpert.agent.md` | MIT, Copyright GitHub, Inc. (`agents/NOTICE.md`) | Identical to upstream on 2026-11-18. |
| `agents/expert-dotnet-software-engineer.agent.md` | imported | github/awesome-copilot, `agents/expert-dotnet-software-engineer.agent.md` | MIT, Copyright GitHub, Inc. (`agents/NOTICE.md`) | Identical to upstream on 2026-11-18, except that the `tools:` frontmatter line was removed here. |

## Open items

1. `skills/dotnet-code-review`: record the repository this copy came from. Its
   `LICENSE.txt` names the CommandCodeAI author, but the skill itself is a
   derivative of that work whose publisher is not recorded.
2. `skills/rust-code-review`: only the Google guide is credited. Add every other
   source that was compiled into it to its `NOTICE.md` and to this table.

## Adding a skill

1. Decide the origin from the table above.
2. `original` or `compiled`: copy `LICENSE` from another own skill and add this
   to the frontmatter:

   ```yaml
   license: MIT
   metadata:
     author: "Vladyslav Neichev (@vladneyo)"
     origin: original   # original | compiled
   ```

   For `compiled`, add a `NOTICE.md` with the URL, license, and copyright line
   of each source. Quote the license text when the license requires it.
3. `adapted` or `imported`: keep the upstream files and license file as
   received, and do not add the author's name to them.
4. Add a row to the registry with the upstream URL and the date of the
   comparison.
