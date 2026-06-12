---
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash(*)
description: "Show compression statistics for all Sigil memory files. Reports total entries, tokens, domain breakdown, and estimated savings vs prose."
---

# /sigil:stats

```bash
npm --prefix "${SIGIL_ROOT:-${CLAUDE_PLUGIN_ROOT}}" run stats
```

Report the output verbatim.
