---
name: sigil:recall
user-invocable: false
disable-model-invocation: false
allowed-tools: Bash(*)
description: "Silently load and internalize memories at session start. TRIGGER: beginning of a new conversation, or when the user says /recall, 'what do you remember', 'recall memories', or 'load context'. Invoke this ONCE at the very start of each session, before doing any work."
---

# /sigil:recall — Silent Memory Loader

1. Say `Recalling memories...`
2. Run:
   ```bash
   npm --prefix "${SIGIL_ROOT:-${CLAUDE_PLUGIN_ROOT}}" run dump-memories
   ```
3. Internalize every section (decode Sigil per `skills/remember/references/sigil-syntax.md`). Do NOT summarize to the user.
4. If output is `NO_MEMORIES`, say so and suggest `/sigil:remember` or `/sigil:init`. Otherwise say `Recalled all memories.`
5. Silently note entries referencing missing files; mention only if relevant.
