# Sigil Command Flows

How each slash command actually runs end-to-end. For the user-facing
description, see [README.md](../README.md); for the security model, see
[SECURITY.md](../SECURITY.md).

Each flow shows: **what the user types → what the skill (`SKILL.md`) does
→ what backing code runs → what gets read/written**. Skills are kept
intentionally thin — heavy lifting lives in `plugins/sigil/src/*.ts` so
the model has minimal prose to follow.

## Reading order (for a new contributor)

You can audit the whole runtime in under thirty minutes:

1. **`plugins/sigil/lib/memory-paths.ts`** — derives the three MEMORY.md
   paths every other module operates on. Start here; everything else is
   "given a path, do X."
2. **`plugins/sigil/src/doctor.ts`** — simplest read-only command;
   establishes the script pattern (`memoryLocations()` → per-file work →
   print → exit code).
3. **`plugins/sigil/src/stats.ts`** and **`dump-memories.ts`** — same
   pattern, different outputs. Each has a header comment explaining the
   constants and why the script exists at all.
4. **`plugins/sigil/src/purge.ts`** — the only script that writes. Pay
   attention to `splitFrontmatter` / `purgeLines` (pure, testable) and
   the always-backup-before-write rule.
5. **`plugins/sigil/skills/*/SKILL.md`** — the model-facing prose. Most
   are now one or two screens; they describe *what to invoke and what
   to do with the output*, not how to compute it.
6. **`plugins/sigil/skills/remember/references/sigil-syntax.md`** — the
   canonical format. The only file the model needs to read to learn how
   to encode or decode.

The bash hooks under `bin/` and `hooks/` are independent of the slash
commands — they only nudge the user and never modify files. See
[SECURITY.md](../SECURITY.md) for the full hook table.

---

## `/sigil:remember`

Save one new memory entry.

```
user → /sigil:remember <prose>
       │
       ▼
skills/remember/SKILL.md
  1. classify type (feedback | project | reference | user)
  2. compress to Sigil per references/sigil-syntax.md
  3. route within MEMORY.md:
       feedback → ## Compressed Behavioral Rules (matching domain code)
       other    → ## Project Context / References / User Context
  4. dedupe before write
       │
       ▼
Reads:  the target MEMORY.md
Writes: appends one Sigil line to MEMORY.md
```

If `$ARGUMENTS` is empty, the skill scans the current conversation for
items worth keeping and applies the same flow to each.

---

## `/sigil:init`

One-time migration of all existing memory files into Sigil format.

```
user → /sigil:init
       │
       ▼
skills/init/SKILL.md
  1. spawn general-purpose subagent → inventory every MEMORY.md
     and `.md` sibling under all three scopes; subagent returns a
     table (path, type, token estimate, draft Sigil line)
  2. back up each memory dir → ~/.claude/backups/sigil/memories/<ts>/
  3. show plan, WAIT for user confirmation
  4. rewrite each MEMORY.md with sections:
       ## Compressed Behavioral Rules (with Legend:)
       ## Project Context / References / User Context
     keep manual-review items as prose w/ <!-- TODO: compress -->
  5. delete absorbed individual files
       │
       ▼
Reads:  all MEMORY.md + linked .md across project/local/global scopes
Writes: timestamped backups, then rewritten MEMORY.md per scope
```

The subagent step keeps raw memory contents out of the main context
during planning.

---

## `/sigil:doctor`

Diagnose memory health across all scopes (read-only).

```
user → /sigil:doctor
       │
       ▼
skills/doctor/SKILL.md → one bash line:
       tsx src/doctor.ts
       │
       ▼
src/doctor.ts (uses lib/memory-paths.ts)
  for each of {project, local, global} MEMORY.md:
    • exists?
    • Legend: line present?
    • analyzeEntries → bare-prose / long / duplicate lines
    • extractRefPaths → flag stale @() paths
  print findings per location; exit 1 if any failures
       │
       ▼
Reads:  all three MEMORY.md
Writes: nothing
```

Skill reports the script's stdout verbatim.

---

## `/sigil:purge`

Remove invalid / duplicate entries, with backup.

```
user → /sigil:purge
       │
       ▼
skills/purge/SKILL.md
  1. dry run:  tsx src/purge.ts --dry-run
  2. show output, WAIT for user confirmation
  3. real run: tsx src/purge.ts
       │
       ▼
src/purge.ts (uses lib/memory-paths.ts)
  for each MEMORY.md:
    • splitFrontmatter → keep frontmatter intact
    • purgeLines → drop bare-prose + duplicate-body lines
    • on real run: copy original to
        ~/.claude/backups/sigil/purge/<date>/<scope>-MEMORY.md
      then overwrite
       │
       ▼
Reads:  all three MEMORY.md
Writes: backups, then rewritten MEMORY.md (real run only)
```

---

## `/sigil:stats`

Compression statistics across all memory locations (read-only).

```
user → /sigil:stats
       │
       ▼
skills/stats/SKILL.md → one bash line:
       tsx src/stats.ts
       │
       ▼
src/stats.ts (uses lib/memory-paths.ts)
  for each existing MEMORY.md:
    • entries: lines matching /^[A-Z]{3}:/
    • tokens:  word_count × 1.3
    • prose estimate: tokens × 4
    • domain breakdown: count of each 3-letter prefix
  print per-location block; print totals line if >1 location
       │
       ▼
Reads:  all three MEMORY.md
Writes: nothing
```

Empty-state branch prints a friendly nudge to run `/sigil:remember` or
`/sigil:init`.

---

## `/sigil:encode`

Preview-only compression. No file I/O.

```
user → /sigil:encode <prose>
       │
       ▼
skills/encode/SKILL.md
  1. classify type
  2. pick 3-letter domain code
  3. compress per references/sigil-syntax.md
  4. print before/after + estimated token delta
       │
       ▼
Reads:  references/sigil-syntax.md
Writes: nothing
```

If the user wants to save the result, the skill tells them to run
`/sigil:remember`.

---

## `/sigil:decode`

Inverse of encode — pure transform.

```
user → /sigil:decode <sigil-snippet>
       │
       ▼
skills/decode/SKILL.md
  1. read Legend from references/sigil-syntax.md (▸ etc.)
  2. parse each operator
  3. emit one sentence per entry + token delta
       │
       ▼
Reads:  references/sigil-syntax.md
Writes: nothing
```

---

## `/sigil:wrap-up`

End-of-session capture.

```
user → /sigil:wrap-up
       │
       ▼
skills/wrap-up/SKILL.md
  1. dump existing memory in one call:
       tsx src/dump-memories.ts
  2. scan conversation for: corrections, decisions, references,
     user-role facts; skip ephemeral / derivable / already-stored
  3. for each surviving item, run the /sigil:remember flow
  4. report saved + skipped (with reason)
       │
       ▼
Reads:  all three MEMORY.md (via dump-memories.ts)
Writes: appends Sigil lines through the remember flow
```

The single-call dump is what makes the dedup check cheap — the model
sees all existing entries in one tool result instead of issuing many
`Read`s.

---

## `/sigil:recall` (model-invoked at session start)

Silent context loader.

```
session-start (or user says "recall memories")
       │
       ▼
skills/recall/SKILL.md
  1. say "Recalling memories..."
  2. tsx src/dump-memories.ts
  3. internalize (decode Sigil per references/sigil-syntax.md);
     do NOT summarize to the user
  4. say "Recalled all memories." (or NO_MEMORIES nudge)
       │
       ▼
Reads:  all three MEMORY.md (+ sibling .md files)
Writes: nothing
```

Output of `dump-memories.ts` looks like:

```
===== MEMORY: /path/to/MEMORY.md =====
<file contents>
----- LINKED: /path/to/feedback_no_mocks.md -----
<file contents>
```

---

## Shared building blocks

| Module | Used by | Purpose |
|--------|---------|---------|
| `lib/memory-paths.ts` | `doctor`, `purge`, `stats`, `dump-memories` | resolves project / local / global MEMORY.md paths |
| `lib/memory-paths.sh` | `recall.sh`, `wrap-up.sh`, `session-start.sh` (hooks) | same logic in bash |
| `lib/context.sh` | `hooks/sigil-checkpoint.sh`, `bin/wrap-up.sh` | reads context-usage % from `/tmp/statusline-debug.json` |
| `skills/remember/references/sigil-syntax.md` | every encode/decode/remember step | canonical format spec — the only file the model needs to read to learn the operators |

## Where to make changes

- New operator or format rule → `skills/remember/references/sigil-syntax.md`
- Change `/sigil:stats` output → `src/stats.ts`
- Change what `/sigil:recall` and `/sigil:wrap-up` see → `src/dump-memories.ts`
- Change purge behavior → `src/purge.ts` (don't forget the dry-run path)
- Change skill prose only when the *flow* changes — keep skills thin.
