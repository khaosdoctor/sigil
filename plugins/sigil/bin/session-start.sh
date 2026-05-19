#!/usr/bin/env bash
# SessionStart hook: load project memories and inject Sigil context.
INPUT=$(cat)
[ "${SIGIL_DEBUG:-0}" = "1" ] && \
  echo "$(date) session-start fired, input: $INPUT" >> /tmp/sigil-hooks.log

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/memory-paths.sh"

PROJECT_MEMORY=$(sigil_project_memory_path)
LOCAL_MEMORY=$(sigil_local_memory_path)
GLOBAL_MEMORY=$(sigil_global_memory_path)

MEMORIES=""

for mem in "$PROJECT_MEMORY" "$LOCAL_MEMORY" "$GLOBAL_MEMORY"; do
  if [ -f "$mem" ]; then
    MEMORIES="${MEMORIES}--- ${mem} ---
$(cat "$mem")

"
  fi
done

SIGIL_MSG="[Sigil] Active. Any new memories must be saved in Sigil compressed format. Use /sigil:remember to save or /sigil:wrap-up at session end."

if [ -n "$MEMORIES" ]; then
  PROJECT_NAME=$(basename "$PWD")
  FULL_MSG="[Sigil] Memories recalled for ${PROJECT_NAME}. Internalize these silently — do not list or summarize them. When you respond to the user's first message, begin your response with: Memories loaded from ${PROJECT_NAME}.

${MEMORIES}${SIGIL_MSG}"
else
  FULL_MSG="[Sigil] No memories found for this project. ${SIGIL_MSG}"
fi

# Use python3 to safely JSON-encode the message
python3 -c "
import json, sys
msg = sys.stdin.read()
print(json.dumps({'additionalContext': msg}))
" <<< "$FULL_MSG"

exit 0
