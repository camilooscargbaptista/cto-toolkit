#!/bin/bash
# CTO Toolkit — Model Routing Advisory Hook (PostToolUse)
#
# After a file is written/edited, checks if the file type suggests
# a higher model tier should be used for subsequent analysis.
#
# This is advisory only — it outputs a suggestion, not a block.

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# ─── Determine if the file warrants elevated analysis ─────────

TIER_SUGGESTION=""
REASON=""

case "$FILE_PATH" in
  # Security-critical files → suggest opus
  *auth*|*security*|*crypto*|*jwt*|*oauth*|*permission*|*rbac*)
    TIER_SUGGESTION="opus"
    REASON="security-critical file"
    ;;
  # Payment/financial files → suggest opus
  *payment*|*billing*|*stripe*|*transaction*|*invoice*)
    TIER_SUGGESTION="opus"
    REASON="financial/payment file"
    ;;
  # Infrastructure → suggest sonnet
  *Dockerfile*|*docker-compose*|*.tf|*.tfvars)
    TIER_SUGGESTION="sonnet"
    REASON="infrastructure file"
    ;;
  # Migrations → suggest sonnet
  *migration*|*schema*)
    TIER_SUGGESTION="sonnet"
    REASON="database migration/schema"
    ;;
  # Config files → haiku is fine
  *.json|*.yaml|*.yml|*.toml|*.env*)
    exit 0
    ;;
esac

# Check file complexity (lines of code)
if [ -z "$TIER_SUGGESTION" ]; then
  LINE_COUNT=$(wc -l < "$FILE_PATH" 2>/dev/null | tr -d ' ')
  if [ "$LINE_COUNT" -gt 500 ]; then
    TIER_SUGGESTION="opus"
    REASON="large file ($LINE_COUNT lines)"
  elif [ "$LINE_COUNT" -gt 200 ]; then
    TIER_SUGGESTION="sonnet"
    REASON="medium file ($LINE_COUNT lines)"
  fi
fi

# Check for sensitive patterns in the written content
if [ -z "$TIER_SUGGESTION" ]; then
  if grep -qiE '(password|secret|private_key|api_key|token|encrypt|decrypt|hash|salt)' "$FILE_PATH" 2>/dev/null; then
    TIER_SUGGESTION="opus"
    REASON="contains sensitive patterns"
  fi
fi

# ─── Output advisory ──────────────────────────────────────────

if [ -n "$TIER_SUGGESTION" ] && [ "$TIER_SUGGESTION" = "opus" ]; then
  echo "🧠 CTO Toolkit — Model Advisory: Consider using opus-tier analysis for $FILE_PATH ($REASON)"
  echo "   Run: /cto-toolkit:security-review or /cto-toolkit:full-review for deep analysis"
fi

exit 0
