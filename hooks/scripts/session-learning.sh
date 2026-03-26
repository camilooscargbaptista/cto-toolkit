#!/bin/bash
# CTO Toolkit — Session Learning Hook (Stop)
#
# Extracts patterns from the completed session and records them
# for continuous improvement. Inspired by everything-claude-code's
# Stop hooks that crystallize session patterns into reusable knowledge.
#
# Stores data in .cto-toolkit/learning/ for future sessions.

LEARNING_DIR=".cto-toolkit/learning"
SESSIONS_DIR="$LEARNING_DIR/sessions"
PATTERNS_FILE="$LEARNING_DIR/patterns.jsonl"

# Create directories if they don't exist
mkdir -p "$SESSIONS_DIR"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
SESSION_ID=$(date +%s)-$$

# ─── Collect session metrics ──────────────────────────────────

# Count files modified in this session (last 2 hours of git history)
FILES_MODIFIED=0
if command -v git &>/dev/null && git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  FILES_MODIFIED=$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')
  [ "$FILES_MODIFIED" = "0" ] && FILES_MODIFIED=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
fi

# Detect languages worked on
LANGUAGES=""
if [ "$FILES_MODIFIED" -gt 0 ]; then
  CHANGED_EXTS=$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only 2>/dev/null)
  echo "$CHANGED_EXTS" | grep -q '\.ts$\|\.tsx$' && LANGUAGES="$LANGUAGES typescript"
  echo "$CHANGED_EXTS" | grep -q '\.js$\|\.jsx$' && LANGUAGES="$LANGUAGES javascript"
  echo "$CHANGED_EXTS" | grep -q '\.py$' && LANGUAGES="$LANGUAGES python"
  echo "$CHANGED_EXTS" | grep -q '\.go$' && LANGUAGES="$LANGUAGES go"
  echo "$CHANGED_EXTS" | grep -q '\.rs$' && LANGUAGES="$LANGUAGES rust"
  echo "$CHANGED_EXTS" | grep -q '\.java$' && LANGUAGES="$LANGUAGES java"
  echo "$CHANGED_EXTS" | grep -q '\.dart$' && LANGUAGES="$LANGUAGES dart"
  echo "$CHANGED_EXTS" | grep -q '\.swift$' && LANGUAGES="$LANGUAGES swift"
  echo "$CHANGED_EXTS" | grep -q '\.cs$' && LANGUAGES="$LANGUAGES csharp"
  echo "$CHANGED_EXTS" | grep -q '\.ex$\|\.exs$' && LANGUAGES="$LANGUAGES elixir"
  echo "$CHANGED_EXTS" | grep -q '\.sql$' && LANGUAGES="$LANGUAGES sql"
  echo "$CHANGED_EXTS" | grep -q '\.tf$' && LANGUAGES="$LANGUAGES terraform"
  echo "$CHANGED_EXTS" | grep -q 'Dockerfile' && LANGUAGES="$LANGUAGES docker"
fi

# Check if tests were written/modified
TESTS_TOUCHED=false
if [ "$FILES_MODIFIED" -gt 0 ]; then
  CHANGED=$(git diff --name-only HEAD~1 2>/dev/null || git diff --name-only 2>/dev/null)
  echo "$CHANGED" | grep -qE '\.(test|spec)\.' && TESTS_TOUCHED=true
fi

# Check for new security-relevant changes
SECURITY_RELEVANT=false
if [ "$FILES_MODIFIED" -gt 0 ]; then
  CHANGED=$(git diff HEAD~1 2>/dev/null || git diff 2>/dev/null)
  echo "$CHANGED" | grep -qiE '(password|secret|api_key|token|auth|jwt|bcrypt|encrypt)' && SECURITY_RELEVANT=true
fi

# ─── Record session data ──────────────────────────────────────

SESSION_DATA=$(cat <<EOF
{
  "session_id": "$SESSION_ID",
  "timestamp": "$TIMESTAMP",
  "files_modified": $FILES_MODIFIED,
  "languages": "$(echo $LANGUAGES | tr ' ' ',')",
  "tests_touched": $TESTS_TOUCHED,
  "security_relevant": $SECURITY_RELEVANT,
  "project_root": "$(pwd)"
}
EOF
)

echo "$SESSION_DATA" >> "$PATTERNS_FILE"

# ─── Pattern extraction ───────────────────────────────────────

# Count total sessions
TOTAL_SESSIONS=$(wc -l < "$PATTERNS_FILE" 2>/dev/null | tr -d ' ')

# Generate periodic learning summary (every 10 sessions)
if [ -n "$TOTAL_SESSIONS" ] && [ "$TOTAL_SESSIONS" -gt 0 ] && [ $((TOTAL_SESSIONS % 10)) -eq 0 ]; then
  echo ""
  echo "📊 CTO Toolkit — Learning Summary ($TOTAL_SESSIONS sessions tracked)"

  # Most used languages
  LANG_COUNTS=$(grep -o '"languages": "[^"]*"' "$PATTERNS_FILE" | sort | uniq -c | sort -rn | head -5)
  echo "  Top languages: $(echo "$LANG_COUNTS" | awk '{print $3}' | tr '\n' ', ' | sed 's/,$//')"

  # Test writing rate
  TESTS_COUNT=$(grep -c '"tests_touched": true' "$PATTERNS_FILE" 2>/dev/null)
  if [ "$TOTAL_SESSIONS" -gt 0 ]; then
    TEST_RATE=$((TESTS_COUNT * 100 / TOTAL_SESSIONS))
    echo "  Test coverage rate: ${TEST_RATE}% of sessions include test changes"
    [ "$TEST_RATE" -lt 30 ] && echo "  ⚠️  Consider running /cto-toolkit:testing-strategy more often"
  fi

  # Security touch rate
  SEC_COUNT=$(grep -c '"security_relevant": true' "$PATTERNS_FILE" 2>/dev/null)
  if [ "$TOTAL_SESSIONS" -gt 0 ]; then
    SEC_RATE=$((SEC_COUNT * 100 / TOTAL_SESSIONS))
    echo "  Security-relevant sessions: ${SEC_RATE}%"
    [ "$SEC_RATE" -gt 50 ] && echo "  💡 High security activity — consider /cto-toolkit:security-review periodically"
  fi
fi

exit 0
