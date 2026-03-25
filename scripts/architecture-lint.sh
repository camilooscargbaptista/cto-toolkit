#!/bin/bash
# CTO Toolkit — Architecture Lint
# Validates that import/require patterns respect layer boundaries.
# Usage: ./architecture-lint.sh [src_directory]

set -euo pipefail

SRC_DIR="${1:-.}"
ISSUES=0

echo "🏗️  Architecture Lint — Checking layer boundaries..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Rule 1: Domain layer should NOT import from Infrastructure
echo ""
echo "📋 Rule 1: Domain → Infrastructure (should NOT exist)"
DOMAIN_TO_INFRA=$(grep -rn "from.*infrastructure\|require.*infrastructure" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.java" --include="*.py" \
  -l 2>/dev/null | grep -i "domain" || true)

if [ -n "$DOMAIN_TO_INFRA" ]; then
  echo "  ❌ Domain layer importing from Infrastructure:"
  echo "$DOMAIN_TO_INFRA" | while read -r file; do
    echo "     → $file"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ Clean — no domain→infrastructure imports"
fi

# Rule 2: Domain should NOT import from Presentation/Controllers
echo ""
echo "📋 Rule 2: Domain → Presentation (should NOT exist)"
DOMAIN_TO_PRES=$(grep -rn "from.*controller\|from.*presenter\|from.*view\|require.*controller" "$SRC_DIR" \
  --include="*.ts" --include="*.js" --include="*.java" --include="*.py" \
  -l 2>/dev/null | grep -iE "domain|entity|value-object" || true)

if [ -n "$DOMAIN_TO_PRES" ]; then
  echo "  ❌ Domain layer importing from Presentation:"
  echo "$DOMAIN_TO_PRES" | while read -r file; do
    echo "     → $file"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ Clean — no domain→presentation imports"
fi

# Rule 3: Check for circular dependencies (same-level cross-module imports)
echo ""
echo "📋 Rule 3: Checking for potential circular imports..."
CIRCULAR=$(grep -rn "from '\.\./\.\." "$SRC_DIR" \
  --include="*.ts" --include="*.js" 2>/dev/null | \
  grep -v "node_modules\|dist\|build\|test\|spec" | head -20 || true)

if [ -n "$CIRCULAR" ]; then
  echo "  ⚠️  Potential cross-boundary imports (review manually):"
  echo "$CIRCULAR" | while read -r line; do
    echo "     → $line"
  done
else
  echo "  ✅ No suspicious cross-boundary imports"
fi

# Rule 4: Check for direct database imports in non-infrastructure layers
echo ""
echo "📋 Rule 4: Direct DB access outside infrastructure"
DIRECT_DB=$(grep -rn "getRepository\|getConnection\|createQueryBuilder\|\.query(" "$SRC_DIR" \
  --include="*.ts" --include="*.js" \
  -l 2>/dev/null | grep -iv "infrastructure\|repository\|migration\|seed\|spec\|test" || true)

if [ -n "$DIRECT_DB" ]; then
  echo "  ❌ Direct database access outside repository/infrastructure:"
  echo "$DIRECT_DB" | while read -r file; do
    echo "     → $file"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ Database access properly encapsulated"
fi

# Rule 5: Check for HTTP/Express in non-controller layers
echo ""
echo "📋 Rule 5: HTTP concerns outside controllers"
HTTP_LEAK=$(grep -rn "@Req()\|@Res()\|req\.body\|res\.json\|res\.status" "$SRC_DIR" \
  --include="*.ts" --include="*.js" \
  -l 2>/dev/null | grep -iv "controller\|middleware\|guard\|interceptor\|filter\|spec\|test" || true)

if [ -n "$HTTP_LEAK" ]; then
  echo "  ❌ HTTP concerns leaking outside controllers:"
  echo "$HTTP_LEAK" | while read -r file; do
    echo "     → $file"
  done
  ISSUES=$((ISSUES + 1))
else
  echo "  ✅ HTTP concerns properly contained"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES -gt 0 ]; then
  echo "🔴 Found $ISSUES architecture violation(s)"
  exit 1
else
  echo "🟢 Architecture looks clean!"
  exit 0
fi
