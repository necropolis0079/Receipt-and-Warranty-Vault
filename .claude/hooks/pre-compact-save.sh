#!/bin/bash
# PreCompact Hook: Auto-save before context compaction
# This runs BEFORE Claude Code compacts the conversation context.

INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger // "unknown"')
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
PROJECT_DIR="D:/Receipt and Warranty Vault"

# Log the compaction event
echo "[pre-compact] Triggered at $TIMESTAMP (trigger: $TRIGGER)" >> "$PROJECT_DIR/.claude/hooks/compaction.log"

# Auto-commit any unsaved work
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Only if it's a git repo
if [ -d ".git" ]; then
  git add -A 2>/dev/null
  git commit -m "Auto-checkpoint before compaction ($TRIGGER) - $TIMESTAMP" 2>/dev/null || true
  echo "[pre-compact] Git checkpoint created" >> "$PROJECT_DIR/.claude/hooks/compaction.log"
fi

exit 0
