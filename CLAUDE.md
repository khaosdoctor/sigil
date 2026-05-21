# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Sigil** is a Claude Code plugin that provides a compressed memory format for encoding behavioral rules, project context, references, and user info into token-efficient symbolic notation. It achieves up to 50× compression at 100% decode accuracy (validated across 14 rounds, 37 subagent tests).

The format is documented and empirically validated in `token-compression-experiment.md`.

## Plugin Structure

This repo is a marketplace containing the Sigil plugin under `plugins/sigil/`:

```
sigil/
├── .claude-plugin/marketplace.json  ← Marketplace catalog
└── plugins/sigil/
    ├── .claude-plugin/plugin.json   ← Plugin manifest (name, version, author)
    ├── skills/
    │   ├── init/SKILL.md
    │   ├── remember/
    │   │   ├── SKILL.md
    │   │   └── references/sigil-syntax.md
    │   ├── doctor/SKILL.md
    │   ├── purge/SKILL.md
    │   ├── stats/SKILL.md
    │   ├── recall/SKILL.md
    │   ├── encode/SKILL.md
    │   ├── decode/SKILL.md
    │   └── wrap-up/SKILL.md
    ├── src/                          ← TypeScript scripts invoked by skills
    │   ├── doctor.ts / purge.ts / stats.ts / dump-memories.ts
    ├── hooks/
    ├── bin/
    └── lib/
```

Every `skills/<name>/SKILL.md` ships with `user-invocable: true`, so each skill exposes its own `/sigil:<name>` slash command. The `remember` skill also sets `disable-model-invocation: false` so Claude auto-invokes it when it spots something worth saving. `init`, `doctor`, `purge`, `stats`, `encode`, `decode`, and `wrap-up` are user-invoked only; `recall` is model-invoked only (triggered silently at `SessionStart`).

The full slash-command set is:

- `/sigil:remember` — save one memory entry
- `/sigil:init` — one-time migration of existing memories into Sigil
- `/sigil:doctor` — read-only health check across all scopes
- `/sigil:purge` — drop bare-prose / duplicate entries (with backup)
- `/sigil:stats` — entry counts, token totals, domain breakdown
- `/sigil:encode` — preview compression without saving
- `/sigil:decode` — expand a Sigil snippet back into prose
- `/sigil:wrap-up` — capture session learnings before context fills
- `/sigil:recall` — silent loader (model-invoked at session start)

See [`docs/COMMAND_FLOWS.md`](./docs/COMMAND_FLOWS.md) for the end-to-end flow of each command.

## The Sigil Format

The format lives in `skills/remember/references/sigil-syntax.md`. The winning encoding (Round 14A) uses:

- 3-letter uppercase domain codes (`GIT:`, `STY:`, `OBS:`)
- `🚫` for never, `▸` for prefer-over, `∈` for inside, `→` for leads-to
- `verb(detail)` for parenthetical examples on ambiguous rules
- A required `Legend:` line — without it, `▸` decodes wrong
- Readable words only — vowel stripping destroys decode accuracy

## Multi-Agent Compatibility

All scripts and hooks use `SIGIL_ROOT` as the primary environment variable for
locating the plugin directory, with `CLAUDE_PLUGIN_ROOT` as a fallback. This
means Sigil works with any agent (Claude Code, Codex, Cursor, etc.) — set
`SIGIL_ROOT` to `plugins/sigil/` and invoke scripts via `npm --prefix "$SIGIL_ROOT" run <command>`.

Available npm scripts: `doctor`, `purge`, `purge:dry`, `stats`, `dump-memories`.

## Testing the Plugin

Load locally with:
```bash
claude --plugin-dir ./plugins/sigil
```

Then try:
```
/sigil:remember something worth keeping
/sigil:init
```

Reload changes during development without restarting:
```
/reload-plugins
```

## What Changes When Editing

- **Format rules** → `plugins/sigil/skills/remember/references/sigil-syntax.md`
- **`/sigil:remember` behavior or trigger description** → `plugins/sigil/skills/remember/SKILL.md`
- **`/sigil:init` migration logic** → `plugins/sigil/skills/init/SKILL.md`
- **`/sigil:doctor` checks** → `plugins/sigil/src/doctor.ts`
- **`/sigil:purge` rules / backup paths** → `plugins/sigil/src/purge.ts`
- **`/sigil:stats` output** → `plugins/sigil/src/stats.ts`
- **`/sigil:encode` and `/sigil:decode` prose** → `plugins/sigil/skills/encode/SKILL.md` and `plugins/sigil/skills/decode/SKILL.md`
- **`/sigil:recall` / `/sigil:wrap-up` memory dump** → `plugins/sigil/src/dump-memories.ts`
- **Shared MEMORY.md path resolution** → `plugins/sigil/lib/memory-paths.ts` (and `memory-paths.sh` for the hooks)
- **Hooks (SessionStart, PreToolUse, PreCompact, Stop)** → `plugins/sigil/bin/*.sh` and `plugins/sigil/hooks/*.sh`
- **Tests** → `plugins/sigil/tests/*.test.ts` (run with `npm test` from `plugins/sigil/`)
- **Plugin metadata** → `plugins/sigil/.claude-plugin/plugin.json`
- **Marketplace catalog** → `.claude-plugin/marketplace.json`
- **Release notes** → `CHANGELOG.md`

## Empirical Constraints (from `token-compression-experiment.md`)

These are hard-won findings — don't reverse them without re-running validation:

- Vowel stripping is net negative (saves ~15% chars, loses 20–40% accuracy)
- The `Legend:` line is load-bearing for `▸` — never remove it
- Parenthetical examples (`wrap(env -i)`, `switch-default(x satisfies never)`) are required for rules involving exact tool commands
- Domain codes must always be present — without them, fragments are ambiguous
- Ultra-terse single-letter domains fail (~54% accuracy)
