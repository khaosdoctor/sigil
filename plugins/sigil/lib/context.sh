#!/usr/bin/env bash
# Shared context-usage reader for Sigil hooks.
# Prefers jq; falls back to shell-pure parsing.

STATUSLINE="${SIGIL_STATUSLINE:-/tmp/statusline-debug.json}"

read_ctx_pct() {
  [ -f "$STATUSLINE" ] || { echo 0; return; }
  local v=""
  if command -v jq >/dev/null 2>&1; then
    v=$(tail -1 "$STATUSLINE" 2>/dev/null \
      | jq -r '.context_window.used_percentage // 0' 2>/dev/null)
  else
    v=$(tail -1 "$STATUSLINE" 2>/dev/null \
      | grep -oE '"used_percentage"[[:space:]]*:[[:space:]]*[0-9.]+' \
      | head -1 \
      | grep -oE '[0-9.]+$')
  fi
  if [ -z "$v" ] || [ "$v" = "null" ]; then
    v=0
  fi
  echo "$v"
}
