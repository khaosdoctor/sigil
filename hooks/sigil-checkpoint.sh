#!/usr/bin/env bash
# Suggest /sigil:remember when context window reaches threshold
THRESHOLD=80

CTX_PCT=$(tail -1 /tmp/statusline-debug.json 2>/dev/null \
  | jq -r '.context_window.used_percentage // 0')

OVER=$(echo "$CTX_PCT $THRESHOLD" | awk '{print ($1 >= $2) ? 1 : 0}')

if [ "$OVER" = "1" ]; then
  printf '{"systemMessage": "Context at %s%% — run /sigil:remember to save session learnings before compacting."}\n' "$CTX_PCT"
fi
