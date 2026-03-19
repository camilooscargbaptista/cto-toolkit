#!/bin/bash
# Generates formatted diff summary for PR description
# Usage: ./generate-diff.sh [base-branch]

BASE_BRANCH="${1:-main}"

echo "=== PR Diff Summary ==="
echo ""
echo "## Branch Info"
echo "Current: $(git rev-parse --abbrev-ref HEAD)"
echo "Base: $BASE_BRANCH"
echo "Commits: $(git log --oneline $BASE_BRANCH..HEAD | wc -l | tr -d ' ')"
echo ""

echo "## Commits"
git log --oneline --no-merges $BASE_BRANCH..HEAD
echo ""

echo "## Files Changed"
git diff $BASE_BRANCH...HEAD --stat
echo ""

echo "## Changed Files by Type"
git diff $BASE_BRANCH...HEAD --name-only | sed 's/.*\.//' | sort | uniq -c | sort -rn
echo ""

echo "## Diff Size"
INSERTIONS=$(git diff $BASE_BRANCH...HEAD --shortstat | grep -oP '\d+ insertion' | grep -oP '\d+' || echo "0")
DELETIONS=$(git diff $BASE_BRANCH...HEAD --shortstat | grep -oP '\d+ deletion' | grep -oP '\d+' || echo "0")
echo "Insertions: +$INSERTIONS"
echo "Deletions: -$DELETIONS"
TOTAL=$((INSERTIONS + DELETIONS))
echo "Total: $TOTAL lines"
if [ "$TOTAL" -gt 400 ]; then
  echo "⚠️  PR is large (>400 lines). Consider splitting."
fi
