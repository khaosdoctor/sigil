#!/usr/bin/env bash
INPUT=$(cat)
echo "$(date) session-start fired, input: $INPUT" >> /tmp/sigil-hooks.log
cat << 'EOF'
{
  "additionalContext": "[Sigil] Active. Any new memories must be saved in Sigil compressed format. Use /sigil:remember to save or /sigil:wrap-up at session end."
}
EOF
exit 0
