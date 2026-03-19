#!/bin/bash
# Pre-review summary: quick overview before diving into code review
# Usage: ./pre-review-check.sh [base-branch]

BASE_BRANCH="${1:-main}"

echo "=== Pre-Review Check ==="
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Base: $BASE_BRANCH"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

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
