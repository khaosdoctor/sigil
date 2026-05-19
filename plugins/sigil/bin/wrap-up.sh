#!/usr/bin/env bash
# Stop hook: nudge user to run /sigil:wrap-up when context is getting full.
# Only fires at >= 60% to avoid noise after every response.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/context.sh"

THRESHOLD=60
CTX_PCT=$(read_ctx_pct)

[ "${SIGIL_DEBUG:-0}" = "1" ] && \
  echo "$(date) wrap-up: ctx=${CTX_PCT}% threshold=${THRESHOLD}%" >> /tmp/sigil-hooks.log

OVER=$(awk -v a="$CTX_PCT" -v b="$THRESHOLD" 'BEGIN { print (a+0 >= b+0) ? 1 : 0 }')

if [ "$OVER" = "1" ]; then
  printf '{"systemMessage": "[Sigil] Context at %s%% — run /sigil:wrap-up to capture anything worth keeping before the session ends."}\n' "$CTX_PCT"
fi

exit 0
