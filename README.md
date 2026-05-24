# Sigil

> Sigil is a token-compressed memory format for AI coding agents. It allows up to
> 75% lossless compression with 100% decode accuracy (validated across 14
> rounds, 37 subagent passes).

It encodes behavioral rules, project context, references, and user preferences in ~8–16 tokens per entry (vs ~30 tokens in prose).

**Format example:**
```
Legend: 🚫=never, ▸=prefer-over

GIT: commit-single-m-flag, wrap(env -i), 🚫bg, 🌳worktree
STY: give-todo+user-implements, 🚫workaround, 🚫tangent
TSX: switch-default(x satisfies never), Record<Enum,T>
```

Sigil is meant to be writable by humans but not necessarily readable. 

## Installation

### Claude Code (marketplace)

Inside Claude Code, add the marketplace and install:

```
/plugin marketplace add khaosdoctor/sigil
/plugin install sigil@sigil
```

Updates are automatic when you run `/plugin marketplace update sigil`.

> The plugin is in verification process in the official Anthropic marketplace

### Claude Code (local clone)

For development or if you prefer a local copy:

```bash
git clone https://github.com/khaosdoctor/sigil.git
claude --plugin-dir ./sigil/plugins/sigil
```

### Development (running tests)

The TypeScript scripts under `plugins/sigil/src/` ship with a small `node:test`
suite. To run it:

```bash
cd plugins/sigil
npm install
npm test
```

This runs every `tests/*.test.ts` file via `tsx` — zero new dependencies beyond
what `doctor`/`purge` already use. Coverage is reproducible with:

```bash
node --import tsx --test --experimental-test-coverage tests/*.test.ts
```

### After install

Restart Claude Code and the slash commands will be available:

```
/sigil:remember    — save a memory in Sigil format
/sigil:init        — migrate all existing memories to Sigil format
/sigil:doctor      — diagnose memory health
/sigil:purge       — clean up duplicate / malformed entries (with backup)
/sigil:stats       — show compression statistics across all memory locations
/sigil:encode      — preview how prose would compress into Sigil (no save)
/sigil:decode      — expand a Sigil snippet back into plain prose
/sigil:wrap-up     — capture session learnings before the window closes
```

See [`docs/COMMAND_FLOWS.md`](./docs/COMMAND_FLOWS.md) for the end-to-end flow of each slash command, [`CHANGELOG.md`](./CHANGELOG.md) for release history, and [`SECURITY.md`](./SECURITY.md) for a detailed breakdown of what the plugin runs, reads, and writes.

---

## Usage

### Save a memory

```
/sigil:remember never use let, always const
```

Or just describe it naturally:

```
/sigil:remember the API auth uses Bearer tokens from process.env.API_KEY
```

Claude compresses it into Sigil and appends to your `MEMORY.md`.

### Migrate existing memories (one-time)

```
/sigil:init
```

Scans all your memory locations, shows a before/after compression table with token counts, waits for confirmation, then rewrites everything in Sigil format. Backs up originals to `~/.claude/backups/sigil/memories/` before overwriting.

### Check compression stats

```
/sigil:stats
```

Shows how many Sigil entries exist across all memory locations, their compressed
token count, estimated prose equivalent, and a breakdown by domain code.

---

## How it works

Sigil uses a small set of symbolic operators on top of readable words:

| Operator | Meaning | Example |
|----------|---------|---------|
| `🚫X` | never do X | `🚫mock-db` |
| `A▸B` | prefer A over B | `Read▸paste` |
| `verb(detail)` | do verb with specifics | `wrap(env -i)` |
| `X→Y` | X leads to / causes Y | `auth-rewrite→compliance` |
| `X@Y` | X at location Y | `pipeline-bugs@Linear(INGEST)` |
| `X+Y` | X and Y | `give-todo+user-implements` |
| `X∈Y` | X inside Y | `[[xlinks]]∈bullets` |

Rules:
- Always include a `Legend:` line — it's load-bearing for `▸`
- Use 3-letter uppercase domain codes (GIT, STY, TSX, PRJ, REF, USR)
- Keep words readable — vowel stripping kills accuracy
- Use parenthetical examples for ambiguous rules: `switch-default(x satisfies never)` not just `satisfies-never`

See `skills/remember/references/sigil-syntax.md` for the full reference.

---

## Smart Hooks (optional but recommended)

Five hooks fire at the right moments to keep Sigil memory in sync without
manual prompting.

| Event | Script | What it does |
|-------|--------|---------------|
| `SessionStart` | `bin/session-start.sh` | reminds Claude to use Sigil format for new memories |
| `PreToolUse` (`Write`/`Edit`) | `bin/recall.sh` | surfaces existing project memory before edits |
| `PreCompact` (`/compact`) | `hooks/precompact.sh` | tiered save prompt before context is cleared |
| `Stop` | `hooks/sigil-checkpoint.sh` | reminder when context usage crosses 80% |
| `Stop` | `bin/wrap-up.sh` | suggests `/sigil:wrap-up` at session end |

### PreCompact — tiered save prompt

Fires when you run `/compact`. Behavior varies by context usage:

| Context | Action |
|---------|--------|
| < 75% | Light reminder to save |
| 75–89% | Warning to consider saving |
| >= 90% | **Critical** — blocks compact until memories are saved |

Reads context usage from `/tmp/statusline-debug.json`. If unavailable, falls
back to the light reminder.

### Stop checkpoint — context threshold reminder

Fires after each Claude response. When context usage reaches 80%, surfaces a
reminder to save session learnings before the window fills further.

### SessionStart — activate Sigil awareness

Injects a system message at session start so Claude formats new memories in
Sigil from the first prompt.

### PreToolUse — recall before edit

When Claude is about to `Write` or `Edit`, surfaces the path to the project's
`MEMORY.md` so existing context is read before changes are made.

### Stop wrap-up — session-end nudge

Suggests running `/sigil:wrap-up` to capture anything worth keeping before the
session closes.

### Full hooks configuration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/session-start.sh"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/recall.sh"
          }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "manual",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/precompact.sh"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/sigil-checkpoint.sh",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/bin/wrap-up.sh"
          }
        ]
      }
    ]
  }
}
```

> **Note:** Checkpoint and PreCompact hooks read context usage from `/tmp/statusline-debug.json`. This file is written by a custom statusline command. If you don't have one configured, hooks fall back to safe defaults.

---

## Repository structure

```
sigil/
  .claude-plugin/marketplace.json     ← Marketplace catalog
  plugins/sigil/
    .claude-plugin/plugin.json        ← Plugin manifest
    skills/
      remember/
        SKILL.md                      → /sigil:remember
        references/sigil-syntax.md    ← Canonical format spec
      init/SKILL.md                   → /sigil:init
      doctor/SKILL.md                 → /sigil:doctor
      purge/SKILL.md                  → /sigil:purge
      stats/SKILL.md                  → /sigil:stats
      encode/SKILL.md                 → /sigil:encode
      decode/SKILL.md                 → /sigil:decode
      wrap-up/SKILL.md                → /sigil:wrap-up
      recall/SKILL.md                 ← silent memory loader (model-invocable only)
    hooks/
      hooks.json
      precompact.sh                   → PreCompact (tiered save prompt)
      sigil-checkpoint.sh             → Stop (context-threshold reminder)
    bin/
      session-start.sh                → SessionStart
      recall.sh                       → PreToolUse on Write/Edit
      wrap-up.sh                      → Stop (session-end nudge)
    lib/
      context.sh                      ← Shared context-usage reader
      memory-paths.sh                 ← Shared slug + MEMORY.md path helper (bash)
      memory-paths.ts                 ← Shared slug + MEMORY.md path helper (TS)
    src/
      doctor.ts                       ← Invoked by /sigil:doctor
      purge.ts                        ← Invoked by /sigil:purge
      stats.ts                        ← Invoked by /sigil:stats
      dump-memories.ts                ← Invoked by /sigil:recall and /sigil:wrap-up
    tests/
      doctor.test.ts                  ← Pure-logic tests for doctor
      purge.test.ts                   ← Pure-logic tests for purge
      stats.test.ts                   ← Integration tests for stats and dump-memories
      memory-paths.test.ts            ← Tests for shared path helper
```

Each skill in `skills/<name>/SKILL.md` has `user-invocable: true`, so it
exposes its own slash command — no duplicate `commands/` directory needed.

---

## Background

The format was developed through 14 rounds of compression experiments testing 37 subagent passes across 16 coding rules and 50 cross-domain rules. The winning format (Round 14A) achieves:

- **Up to 75% compression** on memory entries (depends on the type of memory and
token repetition, but it's a rough estimate)
- **100% decode accuracy** across all validation passes (zero errors in 406 total rule decodes)

## License and privacy

Licensed under [Elastic License 2.0](./LICENSE) (source-available). You can use it, fork it, modify it, and distribute it. Two things you can't do: offer it as a hosted/managed service, or remove the licensing notices. I chose ELv2 over MIT because MIT permits repackaging the code as a competing closed-source SaaS, which I don't want to. ELv2 prevents that while keeping the source available to everyone.


See [the security notice](./SECURITY.md) for privacy and security concerns.
