---
user-invocable: true
disable-model-invocation: true
allowed-tools: Read(*), Edit(*), Write(*), Glob(*), Grep(*), Bash(wc:*), Bash(cat:*), Bash(rm:*), Bash(cp:*), Bash(mkdir:*), Task(*)
description: "Migrate all existing memory files to Sigil compressed format. Discovers, inventories, compresses, and cleans up memory across all scopes."
---

# /sigil:init — Migrate All Memories to Sigil

One-time migration: convert every existing memory file into Sigil format.

Format spec: `skills/remember/references/sigil-syntax.md`.
Token estimate: `wc -w FILE` × 1.3.

## Step 1 — Delegate discovery (subagent)

Spawn one `general-purpose` Agent with this prompt to keep the main context clean:

> Inventory every memory file at the locations emitted by `source ${CLAUDE_PLUGIN_ROOT}/lib/memory-paths.sh && sigil_memory_paths` (canonical scope list: project, local, global). For each file: path, type (`feedback`/`project`/`reference`/`user`), word-count token estimate, and a draft Sigil one-liner per the format in `${CLAUDE_PLUGIN_ROOT}/skills/remember/references/sigil-syntax.md`. Flag entries that are clearer in prose. Return a markdown table grouped by location with totals. Do not modify any files.

## Step 2 — Backup

Copy each discovered memory dir to `~/.claude/backups/sigil/memories/<timestamp>/` (timestamp = `date -u +%Y%m%dT%H%M%SZ`) before any write. Tell the user the path.

## Step 3 — Show plan, wait for confirmation

Present the subagent's table plus estimated savings. **Stop until the user confirms.**

## Step 4 — Execute

Per location, build one `MEMORY.md` with sections:
- `## Compressed Behavioral Rules` (feedback, grouped by 3-letter domain, with `Legend:`)
- `## Project Context`, `## References`, `## User Context` (one-liners)
- Manual-review entries kept as prose with `<!-- TODO: compress -->`

Delete absorbed files. Report final token count and ratio.

## Won't touch

CLAUDE.md or non-memory files. Won't proceed without confirmation.
