#!/bin/bash
# CTO Toolkit — Dependency Audit
# Checks for outdated, unused, and vulnerable dependencies.
# Usage: ./dependency-audit.sh [project_directory]

set -euo pipefail

PROJECT_DIR="${1:-.}"
ISSUES=0

echo "📦 Dependency Audit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Detect package manager
if [ -f "$PROJECT_DIR/package.json" ]; then
  PKG_MANAGER="npm"
elif [ -f "$PROJECT_DIR/pom.xml" ]; then
  PKG_MANAGER="maven"
elif [ -f "$PROJECT_DIR/pubspec.yaml" ]; then
  PKG_MANAGER="pub"
elif [ -f "$PROJECT_DIR/requirements.txt" ] || [ -f "$PROJECT_DIR/pyproject.toml" ]; then
  PKG_MANAGER="pip"
elif [ -f "$PROJECT_DIR/go.mod" ]; then
  PKG_MANAGER="go"
else
  echo "❌ No recognized package manager found"
  exit 1
fi

echo "Detected: $PKG_MANAGER"
echo ""

case $PKG_MANAGER in
  npm)
    # 1. Security vulnerabilities
    echo "🔒 Security Vulnerabilities"
    echo "───────────────────────────"
    cd "$PROJECT_DIR"
    AUDIT_OUTPUT=$(npm audit --json 2>/dev/null || true)
    CRITICAL=$(echo "$AUDIT_OUTPUT" | grep -o '"critical":[0-9]*' | head -1 | cut -d: -f2 || echo "0")
    HIGH=$(echo "$AUDIT_OUTPUT" | grep -o '"high":[0-9]*' | head -1 | cut -d: -f2 || echo "0")

    if [ "$CRITICAL" -gt 0 ] 2>/dev/null || [ "$HIGH" -gt 0 ] 2>/dev/null; then
      echo "  ❌ Critical: $CRITICAL | High: $HIGH"
      echo "  Run: npm audit fix --force"
      ISSUES=$((ISSUES + 1))
    else
      echo "  ✅ No critical/high vulnerabilities"
    fi

    # 2. Outdated packages
    echo ""
    echo "📅 Outdated Packages"
    echo "───────────────────────────"
    OUTDATED=$(npm outdated --json 2>/dev/null || echo "{}")
    OUTDATED_COUNT=$(echo "$OUTDATED" | grep -c '"latest"' || echo "0")
    
    if [ "$OUTDATED_COUNT" -gt 0 ] 2>/dev/null; then
      echo "  ⚠️  $OUTDATED_COUNT outdated package(s)"
      echo "$OUTDATED" | grep -B1 '"latest"' | grep -v '"latest"\|--' | head -10 | while read -r line; do
        echo "     → $line"
      done
    else
      echo "  ✅ All packages up to date"
    fi

    # 3. Unused dependencies (if depcheck is available)
    echo ""
    echo "🗑️  Unused Dependencies"
    echo "───────────────────────────"
    if command -v npx &>/dev/null; then
      UNUSED=$(npx depcheck --json 2>/dev/null | grep -A 100 '"dependencies"' | grep '"' | head -10 || true)
      if [ -n "$UNUSED" ]; then
        echo "  ⚠️  Potentially unused:"
        echo "$UNUSED" | while read -r dep; do
          echo "     → $dep"
        done
      else
        echo "  ✅ No unused dependencies detected"
      fi
    else
      echo "  ⏭️  Skipped (npx not available)"
    fi

    # 4. Lock file check
    echo ""
    echo "🔐 Lock File"
    echo "───────────────────────────"
    if [ -f "package-lock.json" ]; then
      echo "  ✅ package-lock.json exists"
    elif [ -f "yarn.lock" ]; then
      echo "  ✅ yarn.lock exists"
    elif [ -f "pnpm-lock.yaml" ]; then
      echo "  ✅ pnpm-lock.yaml exists"
    else
      echo "  ❌ No lock file found!"
      ISSUES=$((ISSUES + 1))
    fi
    ;;
    
  pub)
    echo "Running pub outdated..."
    cd "$PROJECT_DIR"
    flutter pub outdated 2>/dev/null || dart pub outdated 2>/dev/null || echo "⏭️  Skipped"
    ;;
    
  *)
    echo "⏭️  Detailed audit not yet supported for $PKG_MANAGER"
    echo "   Supported: npm, pub"
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ISSUES -gt 0 ]; then
  echo "🔴 Found $ISSUES issue(s) requiring attention"
  exit 1
else
  echo "🟢 Dependencies look healthy!"
  exit 0
fi
