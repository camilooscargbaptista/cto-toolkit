#!/bin/bash
# CTO Toolkit — Migration Check
# Validates database migration files for naming, ordering, and safety.
# Usage: ./migration-check.sh [migrations_directory]

set -euo pipefail

MIGRATIONS_DIR="${1:-.}"
ISSUES=0

echo "🗄️  Migration Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Find migration files
MIGRATION_FILES=$(find "$MIGRATIONS_DIR" -name "*.sql" -o -name "*.ts" | grep -i "migrat" | sort || true)

if [ -z "$MIGRATION_FILES" ]; then
  echo "  ⏭️  No migration files found in $MIGRATIONS_DIR"
  exit 0
fi

MIGRATION_COUNT=$(echo "$MIGRATION_FILES" | wc -l | tr -d ' ')
echo "Found $MIGRATION_COUNT migration file(s)"
echo ""

# 1. Naming convention check
echo "📋 Rule 1: Naming Convention (NNN_description.sql)"
echo "───────────────────────────"
echo "$MIGRATION_FILES" | while read -r file; do
  basename=$(basename "$file")
  if ! echo "$basename" | grep -qE '^[0-9]+[_-]'; then
    echo "  ❌ Bad naming: $basename (should start with number prefix)"
    ISSUES=$((ISSUES + 1))
  fi
done

# 2. Sequential ordering check
echo ""
echo "📋 Rule 2: Sequential Ordering"
echo "───────────────────────────"
PREV_NUM=0
echo "$MIGRATION_FILES" | while read -r file; do
  basename=$(basename "$file")
  NUM=$(echo "$basename" | grep -oE '^[0-9]+' || echo "0")
  if [ "$NUM" -le "$PREV_NUM" ] 2>/dev/null && [ "$PREV_NUM" -gt 0 ]; then
    echo "  ⚠️  Possible duplicate/out-of-order: $basename (number: $NUM, previous: $PREV_NUM)"
  fi
  PREV_NUM=$NUM
done
echo "  ✅ Ordering checked"

# 3. Dangerous operations check
echo ""
echo "📋 Rule 3: Dangerous Operations"
echo "───────────────────────────"
echo "$MIGRATION_FILES" | while read -r file; do
  basename=$(basename "$file")
  
  # DROP TABLE
  if grep -qi "DROP TABLE" "$file" 2>/dev/null; then
    echo "  🔴 DROP TABLE in: $basename"
  fi
  
  # TRUNCATE
  if grep -qi "TRUNCATE" "$file" 2>/dev/null; then
    echo "  🔴 TRUNCATE in: $basename"
  fi
  
  # ALTER COLUMN TYPE (potential table lock)
  if grep -qi "ALTER.*COLUMN.*TYPE\|ALTER.*ALTER.*TYPE" "$file" 2>/dev/null; then
    echo "  ⚠️  ALTER COLUMN TYPE in: $basename (may lock table)"
  fi
  
  # ADD NOT NULL without DEFAULT
  if grep -qi "ADD.*NOT NULL" "$file" 2>/dev/null && ! grep -qi "DEFAULT" "$file" 2>/dev/null; then
    echo "  ⚠️  ADD NOT NULL without DEFAULT in: $basename (may fail on existing data)"
  fi
  
  # CREATE INDEX without CONCURRENTLY
  if grep -qi "CREATE INDEX" "$file" 2>/dev/null && ! grep -qi "CONCURRENTLY" "$file" 2>/dev/null; then
    echo "  ⚠️  CREATE INDEX without CONCURRENTLY in: $basename (may lock writes)"
  fi
done

# 4. Check for hardcoded values
echo ""
echo "📋 Rule 4: Hardcoded Values"
echo "───────────────────────────"
echo "$MIGRATION_FILES" | while read -r file; do
  basename=$(basename "$file")
  
  # Hardcoded UUIDs (except in seed files)
  if echo "$basename" | grep -qvi "seed"; then
    UUID_COUNT=$(grep -cE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$file" 2>/dev/null || echo "0")
    if [ "$UUID_COUNT" -gt 0 ] 2>/dev/null; then
      echo "  ⚠️  Hardcoded UUID(s) in: $basename ($UUID_COUNT found)"
    fi
  fi
  
  # Hardcoded passwords/secrets
  if grep -qiE "password.*=.*'[^']+'" "$file" 2>/dev/null; then
    echo "  🔴 Hardcoded password in: $basename"
  fi
done

# 5. Check for rollback/down migration
echo ""
echo "📋 Rule 5: Rollback Scripts"
echo "───────────────────────────"
HAS_DOWN=$(echo "$MIGRATION_FILES" | grep -ci "down\|rollback\|revert" || echo "0")
if [ "$HAS_DOWN" -eq 0 ] 2>/dev/null; then
  echo "  ⚠️  No rollback/down migrations found — consider adding them"
else
  echo "  ✅ Found $HAS_DOWN rollback migration(s)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 Migration check complete"
