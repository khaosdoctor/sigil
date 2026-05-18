#!/usr/bin/env bash
# Stop hook: suggest /sigil:remember when context >= threshold.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/context.sh"

THRESHOLD=80

CTX_PCT=$(read_ctx_pct)
OVER=$(awk -v a="$CTX_PCT" -v b="$THRESHOLD" 'BEGIN { print (a+0 >= b+0) ? 1 : 0 }')

if [ "$OVER" = "1" ]; then
  printf '{"systemMessage": "Context at %s%% — run /sigil:remember to save session learnings before compacting."}\n' "$CTX_PCT"
fi

exit 0
