---
user-invocable: true
disable-model-invocation: true
allowed-tools: Read(*), Glob(*), Grep(*), Bash(wc:*), Bash(find:*), Bash(cat:*)
description: "Show compression statistics for all Sigil memory files. Reports total entries, tokens, domain breakdown, and estimated savings vs prose."
---

# /sigil:stats

Show a compression summary across all Sigil memory locations.

## Process

### Step 1: Discover memory files

Check these three locations (same as /sigil:doctor):
- `~/.claude/projects/<project-slug>/memory/MEMORY.md` — project-scoped
- `.claude/memory/MEMORY.md` — local (in current working directory)
- `~/.claude/memory/MEMORY.md` — global

The project slug is derived from the current working directory by replacing
every `/` and `.` with `-` (the leading `/` becomes a leading `-`).

For each location, read the file if it exists. Skip locations that don't exist.

### Step 2: For each found MEMORY.md

1. Count total Sigil entries: lines matching `/^[A-Z]{3}:/`
2. Count tokens (word count x 1.3, rounded):
   ```bash
   echo $(( $(wc -w < FILE) * 13 / 10 ))
   ```
3. Build a domain breakdown — count how many entries each 3-letter code has:
   ```bash
   grep -oE '^[A-Z]{3}' FILE | sort | uniq -c | sort -rn
   ```
4. Estimate prose equivalent: multiply compressed tokens x 4
   (conservative; empirically validated at 4-50x depending on entry type)

### Step 3: Output per location

For each memory location found, print:

```
Location: ~/.claude/projects/-Users-you-project/memory/MEMORY.md
Entries:  42
Tokens:   ~210 (compressed)  ->  ~840 estimated as prose  (4x savings)

Domain breakdown:
  STY:  12 entries
  PRJ:  10 entries
  GIT:   8 entries
  TST:   6 entries
  REF:   4 entries
  USR:   2 entries
```

If no memory files exist anywhere, print:
```
No Sigil memory files found.
Run /sigil:remember to save your first memory, or /sigil:init to migrate existing ones.
```

### Step 4: Totals (if more than one location found)

Print a totals line:
```
----------------------------------------------------------
Total: 3 location(s) | 87 entries | ~440 tokens compressed -> ~1,760 as prose
```
