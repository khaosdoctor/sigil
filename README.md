# Sigil

**This is a temporary readme because I didn't have time to write a proper one yet**

> Sigil is a token-compressed memory format for Agents with up to 33x lossless compression (currently only tested in claude code). 

It encodes behavioral rules, project context, references, and user preferences in ~8–16 tokens per entry (vs ~30 tokens in prose), with empirically validated 100% decode accuracy.

**Format example:**
```
Legend: 🚫=never, ▸=prefer-over

GIT: commit-single-m-flag, wrap(env -i), 🚫bg, 🌳worktree
STY: give-todo+user-implements, 🚫workaround, 🚫tangent
TSX: switch-default(x satisfies never), Record<Enum,T>
```

Sigil is meant to be writable by humans but not necessarily readable. 

## Installation

Copy three things into your Claude Code user directory (`~/.claude/`):

### 1. Commands (slash commands)

```bash
mkdir -p ~/.claude/commands/sigil
cp commands/init.md ~/.claude/commands/sigil/init.md
cp commands/remember.md ~/.claude/commands/sigil/remember.md
```

### 2. Skill (syntax reference)

```bash
mkdir -p ~/.claude/skills/remember/references
cp skills/remember/SKILL.md ~/.claude/skills/remember/SKILL.md
cp skills/remember/references/sigil-syntax.md ~/.claude/skills/remember/references/sigil-syntax.md
```

### 3. Verify

Restart Claude Code (or open a new session) and check that the commands are listed:

```
/sigil:remember    — save a memory in Sigil format
/sigil:init        — migrate all existing memories to Sigil format
```

---

## Forge/Agent Integration

Agents like Forge can read your Sigil memories at session start to understand your preferences, patterns, and project context.

### How It Works

Forge automatically reads `~/.claude/memory/MEMORY.md` on session start if it exists. Your compressed memories are parsed and applied as behavioral context, reducing redundant explanations across sessions.

### Setup (for Forge)

1. **Create global memory file:**
   ```bash
   mkdir -p ~/.claude/memory
   touch ~/.claude/memory/MEMORY.md
   ```

2. **Add your preferences in Sigil format:**
   ```
   Legend: 🚫=never, ▸=prefer-over

   GIT: commit-single-m-flag, wrap(env -i), 🚫bg, 🌳worktree
   STY: give-todo+user-implements, 🚫workaround, 🚫tangent
   TSX: switch-default(x satisfies never), Record<Enum,T>
   ```

3. **Use `/sigil:remember`** during sessions to add new entries:
   ```
   /sigil:remember I prefer TypeScript strict mode enabled
   /sigil:remember 🚫use var, always const or let
   /sigil:remember API calls go in src/api/ folder
   ```

### Memory Locations (Priority Order)

| Scope | Path | Contents |
|-------|------|----------|
| Global | `~/.claude/memory/MEMORY.md` | User preferences, cross-project rules |
| Project | `~/.claude/projects/*/memory/MEMORY.md` | Project-specific context |
| Session | `./.claude/memory/MEMORY.md` | Current project rules |

Forge reads all available memory files at session start. Use the scope that makes sense for each entry.

### Tips for Agent-Friendly Memories

- **Use domain codes**: `GIT:`, `STY:`, `TSX:`, `PRJ:`, `REF:`, `USR:`
- **Be specific**: `commit-single-m-flag` not `good-commits`
- **Include examples**: `wrap(env -i)` not just `env-prefix`
- **Use `Legend:` line**: Required for `▸` to decode correctly

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

Two hooks that trigger Sigil at the right moments automatically.

### Hook 1: PreCompact — save before context is lost

Fires when you run `/compact`. Injects a message telling Claude to call `/sigil:remember` before the context window is cleared.

### Hook 2: Context-aware checkpoint

Fires after each Claude response. When context usage reaches 80%, shows a reminder to save session learnings.

> **Note:** The checkpoint hook reads context usage from `/tmp/statusline-debug.json`. This file is written by a custom statusline command. If you don't have one configured, the hook exits silently.

### Full hooks block for settings.json

```json
{
  "hooks": {
    "PreCompact": [
      {
        "matcher": "manual",
        "hooks": [
          {
            "type": "command",
            "command": "printf '{\"hookSpecificOutput\":{\"hookEventName\":\"PreCompact\",\"additionalContext\":\"Before compacting: run /sigil:remember to persist any important decisions, corrections, or patterns from this session into compressed memory.\"}}'"
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
          }
        ]
      }
    ]
  }
}
```

---

## File locations after install

```
~/.claude/
  commands/
    sigil/
      init.md        → /sigil:init
      remember.md    → /sigil:remember
  skills/
    remember/
      SKILL.md
      references/
        sigil-syntax.md
  hooks/
    sigil-checkpoint.sh   → Stop hook (context-aware)
  memory/
    MEMORY.md             → Global memory (read by agents)
```

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
