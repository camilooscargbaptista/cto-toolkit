#!/bin/bash
# Pre-review summary: quick overview before diving into code review
# Usage: ./pre-review-check.sh [base-branch]

BASE_BRANCH="${1:-main}"

echo "=== Pre-Review Check ==="
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Base: $BASE_BRANCH"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# ============================================================
# GATE 0: Build Verification (TypeScript / Java / Dart)
# ============================================================
echo "## Build Verification"

# TypeScript (Node.js / Angular / NestJS)
if [ -f "tsconfig.json" ]; then
  echo "  Detected: TypeScript project"
  if command -v npx &> /dev/null; then
    echo "  Running: npx tsc --noEmit..."
    BUILD_OUTPUT=$(npx tsc --noEmit 2>&1)
    BUILD_EXIT=$?
    if [ $BUILD_EXIT -ne 0 ]; then
      ERROR_COUNT=$(echo "$BUILD_OUTPUT" | grep -c "error TS")
      echo "  ❌ TypeScript build FAILED — $ERROR_COUNT errors"
      echo "$BUILD_OUTPUT" | grep "error TS" | head -20
      echo ""
      echo "  ⚠️  STOP: Fix build errors before review. Common causes:"
      echo "     - Property/method renamed but not all references updated"
      echo "     - Interface changed but implementations not updated"
      echo "     - Import path changed but consumers not updated"
      echo "     - Type signature changed but callers still use old signature"
    else
      echo "  ✅ TypeScript build passed"
    fi
  else
    echo "  ⚠️  npx not found — skip TypeScript build check"
  fi
# Java (Maven)
elif [ -f "pom.xml" ]; then
  echo "  Detected: Java/Maven project"
  if command -v mvn &> /dev/null; then
    echo "  Running: mvn compile -q..."
    mvn compile -q 2>&1 | tail -5
    [ $? -eq 0 ] && echo "  ✅ Java build passed" || echo "  ❌ Java build FAILED"
  fi
# Java (Gradle)
elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  echo "  Detected: Java/Gradle project"
  if command -v gradle &> /dev/null || [ -f "gradlew" ]; then
    echo "  Running: gradle compileJava -q..."
    ([ -f "gradlew" ] && ./gradlew compileJava -q 2>&1 || gradle compileJava -q 2>&1) | tail -5
    [ $? -eq 0 ] && echo "  ✅ Java build passed" || echo "  ❌ Java build FAILED"
  fi
# Dart / Flutter
elif [ -f "pubspec.yaml" ]; then
  echo "  Detected: Dart/Flutter project"
  if command -v dart &> /dev/null; then
    echo "  Running: dart analyze..."
    DART_OUTPUT=$(dart analyze 2>&1)
    DART_EXIT=$?
    if [ $DART_EXIT -ne 0 ]; then
      echo "  ❌ Dart analysis FAILED"
      echo "$DART_OUTPUT" | grep -E "(error|warning)" | head -20
    else
      echo "  ✅ Dart analysis passed"
    fi
  fi
else
  echo "  No recognized build system found — skipping"
fi
echo ""

# ============================================================
# GATE 1: Rename / Refactor Propagation Check
# ============================================================
echo "## Rename / Refactor Propagation Check"

# Detect property/method renames in the diff (old name removed, new name added)
RENAMED_PROPS=$(git diff $BASE_BRANCH...HEAD --unified=0 | grep -E "^[-+]" | grep -v "^(---|\+\+\+)" | \
  grep -oE "\b[a-z][a-zA-Z]+\b" | sort | uniq -c | sort -rn | \
  awk '$1 == 1 { print $2 }' | head -20)

if [ -n "$RENAMED_PROPS" ]; then
  # Check for entity/model/interface file changes (likely source of renames)
  MODEL_FILES=$(git diff $BASE_BRANCH...HEAD --name-only | grep -iE "(entity|model|interface|type|dto|schema)\." | head -10)
  if [ -n "$MODEL_FILES" ]; then
    echo "  ⚠️  Entity/Model/Interface files changed:"
    echo "$MODEL_FILES" | sed 's/^/     /'
    echo ""
    echo "  Verify ALL consumers of these types are updated."
    echo "  Common miss: property renamed in entity but service/controller still uses old name."
    echo ""

    # For each changed model file, find potentially stale references
    for model_file in $MODEL_FILES; do
      # Get removed property names (lines starting with - that look like property declarations)
      REMOVED_PROPS=$(git diff $BASE_BRANCH...HEAD -- "$model_file" | grep "^-" | grep -v "^---" | \
        grep -oE "\b(this\.)?[a-z][a-zA-Z]+\s*[:=\(;]" | sed 's/[[:space:]]*[:=\(;]//g' | sed 's/this\.//' | sort -u)

      if [ -n "$REMOVED_PROPS" ]; then
        echo "  Properties potentially renamed/removed in $model_file:"
        for prop in $REMOVED_PROPS; do
          # Count remaining usages in the codebase
          USAGE_COUNT=$(grep -rn --include="*.ts" --include="*.js" --include="*.java" --include="*.dart" \
            "\.$prop\b" . 2>/dev/null | grep -v node_modules | grep -v ".git/" | grep -vc "$model_file" || echo "0")
          if [ "$USAGE_COUNT" -gt 0 ]; then
            echo "    ❌ .$prop — still referenced in $USAGE_COUNT places (potential broken reference!)"
            grep -rn --include="*.ts" --include="*.js" --include="*.java" --include="*.dart" \
              "\.$prop\b" . 2>/dev/null | grep -v node_modules | grep -v ".git/" | grep -v "$model_file" | head -5 | sed 's/^/       /'
          fi
        done
        echo ""
      fi
    done
  fi
else
  echo "  ✅ No obvious rename propagation issues detected"
fi
echo ""

# ============================================================
# Standard Checks
# ============================================================
echo "## Files Changed ($(git diff $BASE_BRANCH...HEAD --name-only | wc -l | tr -d ' ') files)"
git diff $BASE_BRANCH...HEAD --name-only
echo ""

echo "## Change Size"
git diff $BASE_BRANCH...HEAD --stat | tail -1
echo ""

echo "## TODO/FIXME/HACK Markers Added"
git diff $BASE_BRANCH...HEAD | grep -E "^\+" | grep -inE "(TODO|FIXME|HACK|XXX|WORKAROUND)" | sed 's/^+//' || echo "None found"
echo ""

echo "## Console.log / System.out / print Statements Added"
git diff $BASE_BRANCH...HEAD | grep -E "^\+" | grep -inE "(console\.(log|debug|info)|System\.out\.print|print\(|debugPrint)" | sed 's/^+//' | head -10 || echo "None found"
echo ""

echo "## New Dependencies"
git diff $BASE_BRANCH...HEAD -- "*/package.json" "*/pubspec.yaml" "*/build.gradle" "*/pom.xml" "*/requirements.txt" --stat 2>/dev/null || echo "No dependency file changes"
echo ""

echo "## Test Files Changed"
git diff $BASE_BRANCH...HEAD --name-only | grep -iE "(test|spec|_test\.|\.test\.)" || echo "No test files changed ⚠️"
echo ""

echo "## Migration Files"
git diff $BASE_BRANCH...HEAD --name-only | grep -iE "(migration|migrate)" || echo "No migration files"
echo ""

echo "## Large Files Added (>500 lines)"
for file in $(git diff $BASE_BRANCH...HEAD --name-only --diff-filter=A); do
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file" 2>/dev/null || echo "0")
    if [ "$lines" -gt 500 ]; then
      echo "  ⚠️  $file ($lines lines)"
    fi
  fi
done || echo "None"
