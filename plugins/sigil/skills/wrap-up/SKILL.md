---
user-invocable: true
disable-model-invocation: true
allowed-tools: Read(*), Edit(*), Write(*), Glob(*), Grep(*), Bash(*), Task(*)
description: "Review the current session and save anything worth remembering long-term. Run at session end to capture feedback, decisions, project context, and references."
---

# /sigil:wrap-up

Extract anything worth keeping long-term from this session and save it.

Format spec: `skills/remember/references/sigil-syntax.md`.

## Process

1. Load existing memory in one call: `${CLAUDE_PLUGIN_ROOT}/node_modules/.bin/tsx ${CLAUDE_PLUGIN_ROOT}/src/dump-memories.ts` (used to filter duplicates).
2. Scan the conversation for: corrections/feedback, project decisions, references (tools/URLs/paths), user-role facts. Skip anything ephemeral, derivable from code/git, or already in memory.
3. For each surviving item, apply the `/sigil:remember` process (compress, route, dedupe).
4. Report saved + skipped (with reason). If nothing qualifies, say so — that's valid.
