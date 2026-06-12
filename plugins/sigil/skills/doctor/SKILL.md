---
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash(*)
description: "Diagnose the health of Sigil memories. Checks format validity, duplicates, stale entries, and compression opportunities."
---

# /sigil:doctor

Run the Sigil diagnostics script and report the findings to the user verbatim.
The script inspects all three memory scopes (project, local, and global) — see
`plugins/sigil/lib/memory-paths.sh::sigil_memory_paths` for the canonical
location list.

```bash
npm --prefix "${SIGIL_ROOT:-${CLAUDE_PLUGIN_ROOT}}" run doctor
```

Report the full output without modification.
