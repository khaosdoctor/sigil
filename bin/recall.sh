#!/usr/bin/env bash
PROJECT_PATH=$(echo "$PWD" | sed 's|/|-|g' | sed 's|^-||')
MEMORY="$HOME/.claude/projects/$PROJECT_PATH/memory/MEMORY.md"
if [ -f "$MEMORY" ]; then
  echo "[Sigil] Memory exists → read before writing: $MEMORY"
fi
