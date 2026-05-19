#!/usr/bin/env bash
# PreToolUse hook (Write|Edit): surface project memory before edits.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/memory-paths.sh"

MEMORY=$(sigil_project_memory_path)

# Note: $MEMORY is interpolated into the JSON heredoc below. It is derived from
# $HOME and the cwd via sigil_project_slug, which replaces `/` and `.` with `-`
# so the resulting path cannot contain JSON-special characters (", \, control
# chars) under any realistic $HOME. If that assumption ever breaks, switch to
# python3 -c 'json.dumps(...)' as session-start.sh does.
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
