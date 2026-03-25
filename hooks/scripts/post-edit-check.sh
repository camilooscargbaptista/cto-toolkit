#!/bin/bash
# CTO Toolkit — Post-Edit Security Quick Check
# Runs after every Write/Edit to catch obvious security issues early.
# This is a fast, lightweight check — not a full security audit.

# Read the tool result from stdin (JSON with file path and content)
INPUT=$(cat)

# Extract the file path from the tool result
FILE_PATH=$(echo "$INPUT" | grep -oP '"file_path"\s*:\s*"([^"]*)"' | head -1 | sed 's/.*"\([^"]*\)"/\1/')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
  exit 0
fi

# Skip non-code files
case "$FILE_PATH" in
  *.md|*.txt|*.json|*.yaml|*.yml|*.toml|*.lock|*.sum|*.mod)
    exit 0
    ;;
esac

ISSUES=""

# Check for potential hardcoded secrets
if grep -nEi '(password|secret|api_key|apikey|token|private_key)\s*[:=]\s*["\x27][A-Za-z0-9+/=]{8,}' "$FILE_PATH" 2>/dev/null; then
  ISSUES="${ISSUES}\n⚠️  Potential hardcoded secret detected in $FILE_PATH"
fi

# Check for AWS access keys
if grep -nE 'AKIA[0-9A-Z]{16}' "$FILE_PATH" 2>/dev/null; then
  ISSUES="${ISSUES}\n⚠️  Potential AWS access key detected in $FILE_PATH"
fi

# Check for common dangerous patterns
if grep -nE '(eval\(|exec\(|os\.system\(|subprocess.*shell\s*=\s*True)' "$FILE_PATH" 2>/dev/null; then
  ISSUES="${ISSUES}\n⚠️  Potentially dangerous function call detected in $FILE_PATH"
fi

# Check for SQL injection patterns (string concatenation in queries)
if grep -nEi "(query|execute|sql).*[\"\`].*\\\$\{|.*\+\s*['\"]" "$FILE_PATH" 2>/dev/null; then
  ISSUES="${ISSUES}\n⚠️  Potential SQL injection pattern (string concatenation in query) in $FILE_PATH"
fi

if [ -n "$ISSUES" ]; then
  echo -e "🔍 CTO Toolkit Post-Edit Check:${ISSUES}"
  echo ""
  echo "Run a full security review with: /cto-toolkit:security-review"
fi

exit 0
