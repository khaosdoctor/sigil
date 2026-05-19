---
user-invocable: false
disable-model-invocation: false
allowed-tools: Read(*), Glob(*), Grep(*), Bash(git:*), Bash(basename:*), Bash(realpath:*), Bash(source:*), Bash(sigil_memory_paths:*)
description: "Silently load and internalize memories at session start. TRIGGER: beginning of a new conversation, or when the user says /recall, 'what do you remember', 'recall memories', or 'load context'. Invoke this ONCE at the very start of each session, before doing any work."
---

# /sigil:recall — Silent Memory Loader

Read and internalize all Sigil memories so the conversation starts with full context. Do NOT present or summarize the memories to the user — just absorb them silently and apply them to your behavior.

## Sigil Format

See the `sigil-syntax.md` reference file in the `remember` skill directory for the format specification used in memory files.

## Process

### Step 1: Identify the current project

Determine the project identity from the working directory:
```bash
basename "$(realpath .)"
```
Also grab the git remote if available:
```bash
git remote get-url origin 2>/dev/null
```

### Step 2: Discover memory locations

Source `plugins/sigil/lib/memory-paths.sh` and call `sigil_memory_paths` to
enumerate the three MEMORY.md locations for the current working directory:

```bash
source plugins/sigil/lib/memory-paths.sh
sigil_memory_paths
```

This emits one path per line, in order: project-scoped
(`~/.claude/projects/<project-slug>/memory/MEMORY.md`, highest relevance),
local (`.claude/memory/MEMORY.md`), then global (`~/.claude/memory/MEMORY.md`,
lower relevance).

For each location that exists, read `MEMORY.md` and any `.md` files in the
same directory.

### Step 3: Decode and internalize

For each memory location found:

1. Read `MEMORY.md` (the index)
2. Read any individual memory files linked from the index
3. Decode all Sigil-compressed entries into their plain meaning
4. Internalize everything — behavioral rules, project context, references, user info

### Step 4: Output

Show brief progress as you work, then confirm when done. Do NOT list or summarize individual memories.

1. **Before scanning**: say `Recalling memories...`
2. **After loading**: say `Recalled all memories from <project-name>.`

If no memories are found anywhere, say so briefly and suggest `/sigil:remember` or `/sigil:init`.

### Step 5: Flag staleness (optional)

If any memory entries reference files or paths, do a quick existence check. Silently note stale entries for yourself — only mention them to the user if they are directly relevant to the current task.
