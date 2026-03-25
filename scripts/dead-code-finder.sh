#!/bin/bash
# CTO Toolkit — Dead Code Finder
# Finds exported functions/classes that are never imported elsewhere.
# Usage: ./dead-code-finder.sh [source_directory]

set -euo pipefail

SRC_DIR="${1:-.}"

echo "💀 Dead Code Finder"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. Exported functions/classes never imported
echo ""
echo "📋 Exported but never imported"
echo "───────────────────────────"

# Find all exported symbols
EXPORTS=$(grep -rn "export\s\+\(function\|class\|const\|enum\|interface\|type\)\s\+" "$SRC_DIR" \
  --include="*.ts" --include="*.js" \
  2>/dev/null | grep -v "node_modules\|dist\|build\|\.spec\.\|\.test\.\|\.d\.ts" || true)

DEAD_COUNT=0

echo "$EXPORTS" | while read -r line; do
  # Extract the symbol name
  SYMBOL=$(echo "$line" | grep -oE "(function|class|const|enum|interface|type)\s+[A-Za-z_][A-Za-z0-9_]*" | awk '{print $2}')
  FILE=$(echo "$line" | cut -d: -f1)
  
  if [ -n "$SYMBOL" ] && [ ${#SYMBOL} -gt 2 ]; then
    # Check if symbol is imported anywhere else
    IMPORT_COUNT=$(grep -rl "$SYMBOL" "$SRC_DIR" \
      --include="*.ts" --include="*.js" \
      2>/dev/null | grep -v "node_modules\|dist\|build\|\.d\.ts" | \
      grep -v "$FILE" | wc -l | tr -d ' ')
    
    if [ "$IMPORT_COUNT" -eq 0 ] 2>/dev/null; then
      echo "  ⚠️  $SYMBOL ($(basename "$FILE"))"
      DEAD_COUNT=$((DEAD_COUNT + 1))
    fi
  fi
done | head -30

echo ""

# 2. Unused files (files never imported)
echo "📋 Potentially Unused Files"
echo "───────────────────────────"

find "$SRC_DIR" -name "*.ts" -o -name "*.js" 2>/dev/null | \
  grep -v "node_modules\|dist\|build\|\.spec\.\|\.test\.\|\.d\.ts\|index\.\|main\.\|app\." | \
  while read -r file; do
    BASENAME=$(basename "$file" | sed 's/\.[^.]*$//')
    
    # Check if this file is imported anywhere
    IMPORT_COUNT=$(grep -rl "$BASENAME" "$SRC_DIR" \
      --include="*.ts" --include="*.js" \
      2>/dev/null | grep -v "node_modules\|dist\|$file" | wc -l | tr -d ' ')
    
    if [ "$IMPORT_COUNT" -eq 0 ] 2>/dev/null; then
      echo "  ⚠️  $file"
    fi
  done | head -20

# 3. Commented-out code
echo ""
echo "📋 Large Commented-Out Blocks"
echo "───────────────────────────"

# Find files with many consecutive commented lines
find "$SRC_DIR" -name "*.ts" -o -name "*.js" 2>/dev/null | \
  grep -v "node_modules\|dist\|build" | while read -r file; do
    COMMENT_BLOCKS=$(awk '/^[[:space:]]*\/\// {count++; next} {if(count > 5) print FILENAME": "count" consecutive comment lines"; count=0}' "$file" 2>/dev/null || true)
    if [ -n "$COMMENT_BLOCKS" ]; then
      echo "  ⚠️  $COMMENT_BLOCKS"
    fi
  done | head -10

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 Dead code analysis complete"
echo "   Note: Review results manually — some exports may be used dynamically"
