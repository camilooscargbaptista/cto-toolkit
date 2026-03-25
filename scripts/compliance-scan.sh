#!/bin/bash
# CTO Toolkit — Compliance Scan
# Scans codebase for PII in logs, secrets in configs, and TLS issues.
# Usage: ./compliance-scan.sh [source_directory]

set -euo pipefail

SRC_DIR="${1:-.}"
ISSUES=0

echo "🛡️  Compliance Scan"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. PII in logs
echo ""
echo "📋 Rule 1: PII in Logs"
echo "───────────────────────────"

# Check for CPF/CNPJ being logged
PII_LOGS=$(grep -rn "console\.\(log\|info\|warn\|error\)\|logger\.\(log\|info\|warn\|error\)\|Logger\.\(log\|info\)" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.java" --include="*.py" \
  2>/dev/null | grep -iE "cpf|cnpj|password|senha|ssn|credit.card|cartao" | \
  grep -v "node_modules\|dist\|build\|\.spec\.\|\.test\." || true)

if [ -n "$PII_LOGS" ]; then
  echo "  ❌ Potential PII being logged:"
  echo "$PII_LOGS" | head -10 | while read -r line; do
    echo "     → $line"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ No obvious PII in log statements"
fi

# 2. Secrets in code
echo ""
echo "📋 Rule 2: Hardcoded Secrets"
echo "───────────────────────────"

SECRETS=$(grep -rnE \
  "(api[_-]?key|apikey|secret[_-]?key|access[_-]?token|private[_-]?key|password)\s*[:=]\s*['\"][A-Za-z0-9+/=]{8,}" \
  "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.java" --include="*.py" \
  --include="*.yaml" --include="*.yml" --include="*.json" \
  2>/dev/null | grep -v "node_modules\|dist\|\.example\|\.sample\|\.spec\.\|\.test\.\|\.md" | \
  grep -v "process\.env\|os\.environ\|System\.getenv" || true)

if [ -n "$SECRETS" ]; then
  echo "  ❌ Potential hardcoded secrets:"
  echo "$SECRETS" | head -10 | while read -r line; do
    echo "     → $line"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ No hardcoded secrets detected"
fi

# 3. AWS Keys
echo ""
echo "📋 Rule 3: AWS Access Keys"
echo "───────────────────────────"

AWS_KEYS=$(grep -rnE "AKIA[0-9A-Z]{16}" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.yaml" --include="*.yml" \
  --include="*.json" --include="*.env*" --include="*.py" \
  2>/dev/null | grep -v "node_modules\|dist\|\.example" || true)

if [ -n "$AWS_KEYS" ]; then
  echo "  🔴 AWS Access Key detected!"
  echo "$AWS_KEYS" | while read -r line; do
    echo "     → $line"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ No AWS keys found"
fi

# 4. .env files committed
echo ""
echo "📋 Rule 4: Environment Files"
echo "───────────────────────────"

ENV_FILES=$(find "$SRC_DIR" -name ".env" -o -name ".env.production" -o -name ".env.local" 2>/dev/null | \
  grep -v "node_modules\|\.example\|\.sample" || true)

if [ -n "$ENV_FILES" ]; then
  echo "  ⚠️  .env files found (should be in .gitignore):"
  echo "$ENV_FILES" | while read -r file; do
    echo "     → $file"
  done
  
  # Check if they're gitignored
  for env_file in $ENV_FILES; do
    if git check-ignore "$env_file" &>/dev/null; then
      echo "     ✅ $env_file is gitignored"
    else
      echo "     ❌ $env_file is NOT gitignored!"
      ISSUES=$((ISSUES + 1))
    fi
  done
else
  echo "  ✅ No .env files found"
fi

# 5. Insecure HTTP URLs
echo ""
echo "📋 Rule 5: Insecure HTTP URLs"
echo "───────────────────────────"

HTTP_URLS=$(grep -rn "http://" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.yaml" --include="*.yml" \
  2>/dev/null | grep -v "localhost\|127\.0\.0\.1\|http://0\.0\.0\.0\|node_modules\|dist\|\.spec\.\|\.test\.\|\.md" | \
  grep -v "comment\|//.*http://" || true)

if [ -n "$HTTP_URLS" ]; then
  echo "  ⚠️  Insecure HTTP URLs (should be HTTPS):"
  echo "$HTTP_URLS" | head -10 | while read -r line; do
    echo "     → $line"
  done
else
  echo "  ✅ No insecure HTTP URLs"
fi

# 6. Data retention check
echo ""
echo "📋 Rule 6: Data Retention Patterns"
echo "───────────────────────────"

SOFT_DELETE=$(grep -rl "deleted_at\|deletedAt\|soft.delete\|softDelete" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.sql" \
  2>/dev/null | grep -v "node_modules" | wc -l | tr -d ' ')

HARD_DELETE=$(grep -rn "DELETE FROM\|\.delete(\|\.remove(" "$SRC_DIR" \
  --include="*.ts" --include="*.js" \
  2>/dev/null | grep -v "node_modules\|\.spec\.\|\.test\.\|soft" | wc -l | tr -d ' ')

echo "  Soft delete patterns: $SOFT_DELETE files"
echo "  Hard delete patterns: $HARD_DELETE occurrences"
if [ "$HARD_DELETE" -gt "$SOFT_DELETE" ] 2>/dev/null; then
  echo "  ⚠️  More hard deletes than soft deletes — review for LGPD compliance"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES -gt 0 ]; then
  echo "🔴 Found $ISSUES compliance issue(s)"
  exit 1
else
  echo "🟢 Compliance scan passed!"
  exit 0
fi
