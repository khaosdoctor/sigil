#!/usr/bin/env bash
INPUT=$(cat)
echo "$(date) stop fired, input: $INPUT" >> /tmp/sigil-hooks.log
cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "Stop"
  },
  "systemMessage": "[Sigil] Session ending — run /sigil:wrap-up to capture anything worth keeping."
}
EOF
exit 0
