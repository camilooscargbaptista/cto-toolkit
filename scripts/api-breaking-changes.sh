#!/bin/bash
# CTO Toolkit — API Breaking Changes Detector
# Compares current OpenAPI spec with previous version to detect breaking changes.
# Usage: ./api-breaking-changes.sh [current_spec] [previous_spec]
#        ./api-breaking-changes.sh (auto-detects spec from git diff)

set -euo pipefail

CURRENT="${1:-}"
PREVIOUS="${2:-}"

echo "🔍 API Breaking Changes Detector"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Auto-detect spec files if not provided
if [ -z "$CURRENT" ]; then
  CURRENT=$(find . -name "openapi*.yaml" -o -name "openapi*.json" -o -name "swagger*.yaml" -o -name "swagger*.json" 2>/dev/null | \
    grep -v "node_modules\|dist" | head -1 || true)
fi

if [ -z "$CURRENT" ]; then
  echo "⏭️  No OpenAPI/Swagger spec found"
  echo "   Falling back to route analysis..."
  echo ""
  
  # Fallback: analyze route definitions for changes
  echo "📋 Current API Routes"
  echo "───────────────────────────"
  
  # NestJS routes
  ROUTES=$(grep -rnE "@(Get|Post|Put|Patch|Delete)\(" . \
    --include="*.ts" \
    2>/dev/null | grep -v "node_modules\|dist\|\.spec\." | \
    sed 's/.*@//' | sort || true)
  
  if [ -n "$ROUTES" ]; then
    echo "$ROUTES" | while read -r route; do
      echo "  → $route"
    done
    
    # Check for removed routes (comparing with git)
    echo ""
    echo "📋 Recently Changed Routes (last 5 commits)"
    echo "───────────────────────────"
    
    git diff HEAD~5 --name-only 2>/dev/null | grep -E "controller|route" | while read -r file; do
      REMOVED=$(git diff HEAD~5 -- "$file" 2>/dev/null | grep "^-.*@\(Get\|Post\|Put\|Patch\|Delete\)" || true)
      ADDED=$(git diff HEAD~5 -- "$file" 2>/dev/null | grep "^+.*@\(Get\|Post\|Put\|Patch\|Delete\)" || true)
      
      if [ -n "$REMOVED" ]; then
        echo "  🔴 REMOVED in $file:"
        echo "$REMOVED" | while read -r line; do echo "     $line"; done
      fi
      if [ -n "$ADDED" ]; then
        echo "  🟢 ADDED in $file:"
        echo "$ADDED" | while read -r line; do echo "     $line"; done
      fi
    done
  else
    echo "  No NestJS/Express routes found"
  fi
  
  # Check for DTO changes (breaking for clients)
  echo ""
  echo "📋 Recently Changed DTOs/Interfaces"
  echo "───────────────────────────"
  
  git diff HEAD~5 --name-only 2>/dev/null | grep -iE "dto|interface|type|model" | \
    grep -v "node_modules" | while read -r file; do
    REMOVED_PROPS=$(git diff HEAD~5 -- "$file" 2>/dev/null | grep "^-" | grep -vE "^---\|^-$\|import\|//" || true)
    if [ -n "$REMOVED_PROPS" ]; then
      echo "  ⚠️  Changed in $file:"
      echo "$REMOVED_PROPS" | head -5 | while read -r line; do echo "     $line"; done
    fi
  done
  
  exit 0
fi

# If spec files provided, do structural comparison
echo "Comparing: $PREVIOUS → $CURRENT"
echo ""

if [ -z "$PREVIOUS" ]; then
  # Get previous version from git
  PREVIOUS_CONTENT=$(git show HEAD~1:"$CURRENT" 2>/dev/null || echo "")
  if [ -z "$PREVIOUS_CONTENT" ]; then
    echo "⚠️  Could not find previous version in git history"
    exit 0
  fi
  echo "$PREVIOUS_CONTENT" > /tmp/prev-spec.yaml
  PREVIOUS="/tmp/prev-spec.yaml"
fi

# Compare endpoints
echo "📋 Endpoint Changes"
echo "───────────────────────────"

# Extract paths from YAML/JSON
CURRENT_PATHS=$(grep -E "^\s+/|\"/" "$CURRENT" 2>/dev/null | sort || true)
PREVIOUS_PATHS=$(grep -E "^\s+/|\"/" "$PREVIOUS" 2>/dev/null | sort || true)

# Removed endpoints (breaking!)
REMOVED=$(diff <(echo "$PREVIOUS_PATHS") <(echo "$CURRENT_PATHS") 2>/dev/null | grep "^<" || true)
if [ -n "$REMOVED" ]; then
  echo "  🔴 REMOVED endpoints (BREAKING):"
  echo "$REMOVED" | while read -r line; do echo "     $line"; done
fi

# Added endpoints
ADDED=$(diff <(echo "$PREVIOUS_PATHS") <(echo "$CURRENT_PATHS") 2>/dev/null | grep "^>" || true)
if [ -n "$ADDED" ]; then
  echo "  🟢 ADDED endpoints:"
  echo "$ADDED" | while read -r line; do echo "     $line"; done
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 API analysis complete"
echo "   For detailed comparison, consider: npx @openapitools/openapi-diff"
