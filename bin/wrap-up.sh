#!/usr/bin/env bash
# Stop hook: nudge user to run /sigil:wrap-up at session end.
INPUT=$(cat)
[ "${SIGIL_DEBUG:-0}" = "1" ] && \
  echo "$(date) stop fired, input: $INPUT" >> /tmp/sigil-hooks.log

cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "Stop"
  },
  "systemMessage": "[Sigil] Session ending — run /sigil:wrap-up to capture anything worth keeping."
}
EOF
exit 0
