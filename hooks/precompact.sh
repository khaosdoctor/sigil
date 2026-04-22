#!/usr/bin/env bash
# Smart PreCompact hook - context-aware memory persistence
# If context >= 90%, injects a blocking prompt to save memories first

THRESHOLD_BLOCK=90
THRESHOLD_WARN=75

CTX_PCT=$(tail -1 /tmp/statusline-debug.json 2>/dev/null \
  | jq -r '.context_window.used_percentage // 0')

if [ -z "$CTX_PCT" ] || [ "$CTX_PCT" = "null" ]; then
  CTX_PCT=0
fi

OVER_BLOCK=$(echo "$CTX_PCT $THRESHOLD_BLOCK" | awk '{print ($1 >= $2) ? 1 : 0}')
OVER_WARN=$(echo "$CTX_PCT $THRESHOLD_WARN" | awk '{print ($1 >= $2) ? 1 : 0}')

if [ "$OVER_BLOCK" = "1" ]; then
  # Critical: Force remember before compact
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "block": true,
    "additionalContext": "[CRITICAL] Context at ${CTX_PCT}%. Run /sigil:remember to save important decisions, corrections, and patterns BEFORE running /compact. Memory loss is imminent."
  }
}
EOF
elif [ "$OVER_WARN" = "1" ]; then
  # Warning: Suggest remember
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Context at ${CTX_PCT}% — consider running /sigil:remember to persist session learnings before compacting."
  }
}
EOF
else
  # Normal: Light reminder
  cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Before compacting: run /sigil:remember to persist any important decisions, corrections, or patterns from this session into compressed memory."
  }
}
EOF
fi

exit 0
