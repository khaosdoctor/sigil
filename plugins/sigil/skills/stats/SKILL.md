---
name: stats
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash(*)
description: "Show compression statistics for all Sigil memory files. Reports total entries, tokens, domain breakdown, and estimated savings vs prose."
---

# /sigil:stats

```bash
${CLAUDE_PLUGIN_ROOT}/node_modules/.bin/tsx ${CLAUDE_PLUGIN_ROOT}/src/stats.ts
```

Report the output verbatim.
