---
user-invocable: true
disable-model-invocation: true
allowed-tools: Bash(*)
description: "Remove invalid and duplicate entries from Sigil memory. Shows a dry run first, then asks for confirmation before writing."
---

# /sigil:purge

Remove invalid entries (no domain code, duplicates) from every Sigil memory
file. The script operates on all three scopes (project, local, and global) —
see `plugins/sigil/lib/memory-paths.sh::sigil_memory_paths` for the canonical
location list.

## Process

1. Run dry run and show what would be removed:
```bash
npm --prefix "${SIGIL_ROOT:-${CLAUDE_PLUGIN_ROOT}}" run purge:dry
```

2. Show the output to the user and ask for confirmation before proceeding.

3. If confirmed, run for real:
```bash
npm --prefix "${SIGIL_ROOT:-${CLAUDE_PLUGIN_ROOT}}" run purge
```

4. Report the final output verbatim.
