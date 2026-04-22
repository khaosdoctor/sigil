#!/usr/bin/env bash
# PreCommit hook - suggest Sigil memories before git commits
# Fires when user is about to commit changes

cat << 'EOF'
{
  "systemMessage": "[Sigil] Consider running /sigil:remember to save any patterns, decisions, or context from this session before committing. This ensures the next session starts with full context."
}
EOF
exit 0
