#!/usr/bin/env bash
# Smart PreCompact hook — context-aware memory persistence.
# When context >= 90%, blocks /compact until memories are saved.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/context.sh"

THRESHOLD_BLOCK=90
THRESHOLD_WARN=75

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
