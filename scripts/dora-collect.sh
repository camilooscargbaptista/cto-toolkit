#!/bin/bash
# CTO Toolkit — DORA Metrics Collector
# Collects Deployment Frequency and Lead Time from Git history.
# Usage: ./dora-collect.sh [days] [main_branch]

set -euo pipefail

DAYS="${1:-30}"
MAIN_BRANCH="${2:-main}"
SINCE_DATE=$(date -v-${DAYS}d '+%Y-%m-%d' 2>/dev/null || date -d "${DAYS} days ago" '+%Y-%m-%d' 2>/dev/null || echo "")

echo "📊 DORA Metrics — Last $DAYS days"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Deployment Frequency
echo "🚀 Deployment Frequency"
echo "───────────────────────────"

# Count merges to main (proxy for deployments)
if [ -n "$SINCE_DATE" ]; then
  DEPLOY_COUNT=$(git log "$MAIN_BRANCH" --merges --oneline --since="$SINCE_DATE" 2>/dev/null | wc -l | tr -d ' ')
else
  DEPLOY_COUNT=$(git log "$MAIN_BRANCH" --merges --oneline -n 100 2>/dev/null | wc -l | tr -d ' ')
fi

# Also count direct commits tagged as deployments
TAG_DEPLOYS=$(git tag -l --sort=-creatordate | head -50 | while read -r tag; do
  TAG_DATE=$(git log -1 --format='%ai' "$tag" 2>/dev/null | cut -d' ' -f1)
  if [ -n "$SINCE_DATE" ] && [ "$TAG_DATE" \> "$SINCE_DATE" ] 2>/dev/null; then
    echo "$tag"
  fi
done | wc -l | tr -d ' ')

TOTAL_DEPLOYS=$((DEPLOY_COUNT + TAG_DEPLOYS))

echo "  Merges to $MAIN_BRANCH: $DEPLOY_COUNT"
echo "  Release tags: $TAG_DEPLOYS"
echo "  Total deployments: $TOTAL_DEPLOYS"

# Classify DORA level
DEPLOYS_PER_WEEK=$((TOTAL_DEPLOYS * 7 / DAYS))
if [ "$DEPLOYS_PER_WEEK" -ge 7 ]; then
  FREQ_LEVEL="Elite (multiple per day)"
elif [ "$DEPLOYS_PER_WEEK" -ge 1 ]; then
  FREQ_LEVEL="High (between weekly and daily)"
elif [ "$TOTAL_DEPLOYS" -ge 1 ]; then
  FREQ_LEVEL="Medium (between monthly and weekly)"
else
  FREQ_LEVEL="Low (less than monthly)"
fi
echo "  DORA Level: $FREQ_LEVEL"

# 2. Lead Time for Changes
echo ""
echo "⏱️  Lead Time for Changes"
echo "───────────────────────────"

# Calculate time from first commit on branch to merge
LEAD_TIMES=""
git log "$MAIN_BRANCH" --merges --format='%H %ai' --since="$SINCE_DATE" 2>/dev/null | head -20 | while read -r MERGE_HASH MERGE_DATE REST; do
  # Get the merge parents
  PARENTS=$(git log -1 --format='%P' "$MERGE_HASH" 2>/dev/null)
  BRANCH_TIP=$(echo "$PARENTS" | awk '{print $2}')
  
  if [ -n "$BRANCH_TIP" ]; then
    # Find first commit on the branch
    FIRST_COMMIT_DATE=$(git log "$MERGE_HASH" --not $(echo "$PARENTS" | awk '{print $1}') --format='%ai' --reverse 2>/dev/null | head -1 | cut -d' ' -f1)
    MERGE_DATE_CLEAN=$(echo "$MERGE_DATE" | cut -d' ' -f1)
    
    if [ -n "$FIRST_COMMIT_DATE" ] && [ -n "$MERGE_DATE_CLEAN" ]; then
      echo "  $FIRST_COMMIT_DATE → $MERGE_DATE_CLEAN"
    fi
  fi
done

echo "  (Showing sample of recent merges)"

# 3. Change Failure Rate (proxy: reverts and hotfixes)
echo ""
echo "🔥 Change Failure Rate (proxy)"
echo "───────────────────────────"

REVERTS=$(git log "$MAIN_BRANCH" --oneline --since="$SINCE_DATE" --grep="revert\|Revert" 2>/dev/null | wc -l | tr -d ' ')
HOTFIXES=$(git log "$MAIN_BRANCH" --oneline --since="$SINCE_DATE" --grep="hotfix\|fix:\|bugfix" 2>/dev/null | wc -l | tr -d ' ')

echo "  Reverts: $REVERTS"
echo "  Hotfixes/bugfixes: $HOTFIXES"

if [ "$TOTAL_DEPLOYS" -gt 0 ]; then
  FAILURE_RATE=$(( (REVERTS + HOTFIXES) * 100 / TOTAL_DEPLOYS ))
  echo "  Estimated failure rate: ${FAILURE_RATE}%"
  
  if [ "$FAILURE_RATE" -le 15 ]; then
    echo "  DORA Level: Elite (0-15%)"
  elif [ "$FAILURE_RATE" -le 30 ]; then
    echo "  DORA Level: High (16-30%)"
  else
    echo "  DORA Level: Low (>30%)"
  fi
fi

# 4. Commit Patterns
echo ""
echo "📈 Commit Patterns"
echo "───────────────────────────"

TOTAL_COMMITS=$(git log --oneline --since="$SINCE_DATE" 2>/dev/null | wc -l | tr -d ' ')
FEAT_COMMITS=$(git log --oneline --since="$SINCE_DATE" --grep="feat:" 2>/dev/null | wc -l | tr -d ' ')
FIX_COMMITS=$(git log --oneline --since="$SINCE_DATE" --grep="fix:" 2>/dev/null | wc -l | tr -d ' ')
REFACTOR_COMMITS=$(git log --oneline --since="$SINCE_DATE" --grep="refactor:" 2>/dev/null | wc -l | tr -d ' ')
CHORE_COMMITS=$(git log --oneline --since="$SINCE_DATE" --grep="chore:" 2>/dev/null | wc -l | tr -d ' ')

echo "  Total commits: $TOTAL_COMMITS"
echo "  feat: $FEAT_COMMITS | fix: $FIX_COMMITS | refactor: $REFACTOR_COMMITS | chore: $CHORE_COMMITS"

if [ "$TOTAL_COMMITS" -gt 0 ]; then
  FIX_RATIO=$((FIX_COMMITS * 100 / TOTAL_COMMITS))
  echo "  Fix ratio: ${FIX_RATIO}% (>30% = team in reactive mode)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 DORA collection complete"
