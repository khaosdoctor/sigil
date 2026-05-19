# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

**Sigil** is a Claude Code plugin that provides a compressed memory format for encoding behavioral rules, project context, references, and user info into token-efficient symbolic notation. It achieves ~4× compression at 100% decode accuracy (validated across 14 rounds, 37 subagent tests).

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

Both skills use `user-invocable: true`. The `remember` skill also has `disable-model-invocation: false` so Claude auto-invokes it when detecting something worth saving. The `init` skill has `disable-model-invocation: true` — it only runs when explicitly invoked.

## The Sigil Format

The format lives in `skills/remember/references/sigil-syntax.md`. The winning encoding (Round 14A) uses:

- 3-letter uppercase domain codes (`GIT:`, `STY:`, `OBS:`)
- `🚫` for never, `▸` for prefer-over, `∈` for inside, `→` for leads-to
- `verb(detail)` for parenthetical examples on ambiguous rules
- A required `Legend:` line — without it, `▸` decodes wrong
- Readable words only — vowel stripping destroys decode accuracy

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
- **`/sigil:stats` output** → `plugins/sigil/src/stats.ts` (skill is a one-liner that invokes the TS)
- **`/sigil:recall` / `/sigil:wrap-up` memory dump** → `plugins/sigil/src/dump-memories.ts`
- **Plugin metadata** → `plugins/sigil/.claude-plugin/plugin.json`
- **Marketplace catalog** → `.claude-plugin/marketplace.json`

## Empirical Constraints (from `token-compression-experiment.md`)

These are hard-won findings — don't reverse them without re-running validation:

- Vowel stripping is net negative (saves ~15% chars, loses 20–40% accuracy)
- The `Legend:` line is load-bearing for `▸` — never remove it
- Parenthetical examples (`wrap(env -i)`, `switch-default(x satisfies never)`) are required for rules involving exact tool commands
- Domain codes must always be present — without them, fragments are ambiguous
- Ultra-terse single-letter domains fail (~54% accuracy)
