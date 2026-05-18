#!/usr/bin/env bash
# Smart PreCompact hook — context-aware memory persistence.
# When context >= 90%, blocks /compact until memories are saved.

THRESHOLD_BLOCK=90
THRESHOLD_WARN=75
STATUSLINE="/tmp/statusline-debug.json"

# Read context_window.used_percentage from the statusline file.
# Prefers jq if available; falls back to a shell-pure parser so the hook
# stays functional on minimal systems.
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

OVER_BLOCK=$(awk -v a="$CTX_PCT" -v b="$THRESHOLD_BLOCK" 'BEGIN { print (a+0 >= b+0) ? 1 : 0 }')
OVER_WARN=$(awk -v a="$CTX_PCT" -v b="$THRESHOLD_WARN"  'BEGIN { print (a+0 >= b+0) ? 1 : 0 }')

if [ "$OVER_BLOCK" = "1" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "block": true,
    "additionalContext": "[CRITICAL] Context at ${CTX_PCT}%. Run /sigil:remember to save important decisions, corrections, and patterns BEFORE running /compact. Memory loss is imminent."
  }
}
EOF
elif [ "$OVER_WARN" = "1" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Context at ${CTX_PCT}% — consider running /sigil:remember to persist session learnings before compacting."
  }
}
EOF
else
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Before compacting: run /sigil:remember to persist any important decisions, corrections, or patterns from this session into compressed memory."
  }
}
EOF
fi

exit 0
