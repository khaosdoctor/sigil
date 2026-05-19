# shellcheck shell=bash
# Shared helpers for resolving Sigil memory file locations.
# Mirrors plugins/sigil/lib/memory-paths.ts — keep the two in sync.
#
# Project slug formula: strip the leading `/` from cwd, then replace every
# remaining `/` and `.` with `-`. Callers prepend a literal `-` to match
# Claude Code's `~/.claude/projects/-Users-...` layout.

sigil_project_slug() {
  local cwd="${1:-$PWD}"
  echo "$cwd" | sed 's|^/||; s|[/.]|-|g'
}

sigil_project_memory_path() {
  local cwd="${1:-$PWD}"
  echo "$HOME/.claude/projects/-$(sigil_project_slug "$cwd")/memory/MEMORY.md"
}

sigil_local_memory_path() {
  local cwd="${1:-$PWD}"
  echo "$cwd/.claude/memory/MEMORY.md"
}

sigil_global_memory_path() {
  echo "$HOME/.claude/memory/MEMORY.md"
}

sigil_memory_paths() {
  local cwd="${1:-$PWD}"
  sigil_project_memory_path "$cwd"
  sigil_local_memory_path "$cwd"
  sigil_global_memory_path
}
