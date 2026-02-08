#!/bin/bash
# SessionStart Hook (compact matcher): Re-inject critical context after compaction
# This runs AFTER compaction completes and a new session begins.

PROJECT_DIR="D:/Receipt and Warranty Vault"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "[post-compact] Session resumed after compaction at $TIMESTAMP" >> "$PROJECT_DIR/.claude/hooks/compaction.log"

# Output critical reminders that Claude will see
cat <<'CONTEXT'
=== POST-COMPACTION CONTEXT RESTORATION ===

CRITICAL: You just went through context compaction. Before continuing:

1. READ these files to restore full context:
   - D:\Receipt and Warranty Vault\CLAUDE.md (project memory — ALL decisions)
   - D:\Receipt and Warranty Vault\.claude\SESSION_STATE.md (current session state — what you were doing)

2. DO NOT continue working until you have read both files above.

3. After reading, update SESSION_STATE.md with your understanding of where you left off.

=== END CONTEXT RESTORATION ===
CONTEXT

exit 0
