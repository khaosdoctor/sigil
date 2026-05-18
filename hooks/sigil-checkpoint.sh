#!/usr/bin/env bash
# Stop hook: suggest /sigil:remember when context >= threshold.
# Uses jq when available, falls back to shell-pure parsing otherwise.

THRESHOLD=80
STATUSLINE="/tmp/statusline-debug.json"

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
  [ -z "$v" ] || [ "$v" = "null" ] && v=0
  echo "$v"
}

CTX_PCT=$(read_ctx_pct)
OVER=$(awk -v a="$CTX_PCT" -v b="$THRESHOLD" 'BEGIN { print (a+0 >= b+0) ? 1 : 0 }')

if [ "$OVER" = "1" ]; then
  printf '{"systemMessage": "Context at %s%% — run /sigil:remember to save session learnings before compacting."}\n' "$CTX_PCT"
fi

exit 0
