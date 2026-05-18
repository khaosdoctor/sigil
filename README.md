# Sigil

> Sigil is a token-compressed memory format for AI coding agents — up to
> 33× lossless compression with 100% decode accuracy (validated across 14
> rounds, 37 subagent passes).

```bash
curl -fsSL https://github.com/khaosdoctor/sigil/raw/main/install.sh | bash
```

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

### Claude Code (recommended)

Inside Claude Code, run these two slash commands:

```
/plugin marketplace add khaosdoctor/sigil
/plugin install sigil@khaosdoctor/sigil
```

The first registers this repo as a plugin marketplace; the second installs
Sigil from it. Updates are handled by Claude Code's plugin system — no
manual reinstall needed.

### Universal installer (other harnesses or manual install)

For environments outside Claude Code, or if you prefer not to use the
plugin system, run the interactive installer ([bash](https://www.gnu.org/software/bash/) +
[gum](https://github.com/charmbracelet/gum)):

```bash
curl -fsSL https://github.com/khaosdoctor/sigil/raw/main/install.sh | bash
```

Or after cloning:

```bash
./install.sh             # install
./install.sh uninstall   # remove
```

Only `curl` is required — `gum` is auto-bootstrapped into a temporary
directory when missing, so the host system stays untouched.

The installer detects your installed agents and lets you pick where to place
Sigil. **Today only Claude Code is fully supported.** OpenCode, Kilo Code,
Pi Agent, Cursor, Windsurf, Gemini CLI, Codex and Goose are listed as
"Coming soon" in the picker — visible but not selectable until each
integration lands.

### After install

Restart your harness and the slash commands will be available:

```
/sigil:remember    — save a memory in Sigil format
/sigil:init        — migrate all existing memories to Sigil format
/sigil:doctor      — diagnose memory health
```

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

## File locations after install

```
~/.claude/
  skills/
    remember/
      SKILL.md          → /sigil:remember
      references/
        sigil-syntax.md
    init/SKILL.md       → /sigil:init
    doctor/SKILL.md     → /sigil:doctor
    purge/SKILL.md      → /sigil:purge
    encode/SKILL.md     → /sigil:encode
    decode/SKILL.md     → /sigil:decode
    wrap-up/SKILL.md    → /sigil:wrap-up
  hooks/
    hooks.json
    precompact.sh         → PreCompact (tiered save prompt)
    sigil-checkpoint.sh   → Stop (context-threshold reminder)
  bin/
    session-start.sh      → SessionStart
    recall.sh             → PreToolUse on Write/Edit
    wrap-up.sh            → Stop (session-end nudge)
  src/
    doctor.ts             → invoked by /sigil:doctor
    purge.ts              → invoked by /sigil:purge
  memory/
    MEMORY.md             → Global memory (read by agents)
```

Each skill in `skills/<name>/SKILL.md` has `user-invocable: true`, so it
exposes its own slash command — no duplicate `commands/` directory needed.

### Agent Memory Hierarchy

```
~/.claude/memory/MEMORY.md           ← Global (user preferences)
~/.claude/projects/*/memory/MEMORY.md ← Project-specific
./.claude/memory/MEMORY.md           ← Current workspace
```

---

## Background

The format was developed through 14 rounds of compression experiments testing 37 subagent passes across 16 coding rules and 50 cross-domain rules. The winning format (Round 14A) achieves:

- **3.9× compression** on technical rules (132 tokens vs 516 prose)
- **100% decode accuracy** across all validation passes (zero errors in 406 total rule decodes)
