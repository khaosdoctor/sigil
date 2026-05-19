#!/usr/bin/env bash
# PreToolUse hook (Write|Edit): surface project memory before edits.

PROJECT_SLUG=$(echo "$PWD" | sed 's|^/||; s|[/.]|-|g')
MEMORY="$HOME/.claude/projects/-${PROJECT_SLUG}/memory/MEMORY.md"

if [ -f "$MEMORY" ]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "[Sigil] Project memory exists at $MEMORY — read it before writing if you have not yet."
  }
}
EOF
fi

exit 0
