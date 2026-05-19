---
disable-model-invocation: false
user-invocable: true
allowed-tools: Read(*), Edit(*), Write(*), Glob(*), Grep(*), Bash(wc:*)
description: "Save a memory in Sigil compressed format. TRIGGER: user says /remember, 'remember this', 'keep this in mind', 'note that', 'don't forget', or similar. Also invoke proactively when you notice something worth remembering long-term (feedback, corrections, project context, references)."
---

# /sigil:remember

Save to the auto-memory system at the path in the auto-memory system prompt.

Format spec: `references/sigil-syntax.md` (sibling dir).
Token estimate: word count × 1.3.

## Process

If `$ARGUMENTS` is non-empty:
1. Classify type: `feedback` / `project` / `reference` / `user`.
2. Compress to Sigil — prose only as a last resort.
3. Route in MEMORY.md:
   - **feedback** → append under `## Compressed Behavioral Rules`, matching domain code (create a new 3-letter code if needed).
   - **project / reference / user** → append as a one-liner under the matching section. Separate file only if a one-liner is impossible.
4. Check for duplicates first — update existing entries instead of adding.

If `$ARGUMENTS` is empty: scan the conversation for anything worth keeping; for each item apply the above. If nothing, say so.

## Output

```
Before: "Never mock the database in tests — we got burned…"
After:  TST:🚫mock-db,integration-only
Tokens: ~18 → ~5 (-72%)
```
