#!/bin/bash
# CTO Toolkit — Test Coverage Gate
# Checks test coverage and fails if below threshold.
# Usage: ./test-coverage-gate.sh [threshold_percent] [project_directory]

set -euo pipefail

THRESHOLD="${1:-80}"
PROJECT_DIR="${2:-.}"

echo "🧪 Test Coverage Gate (threshold: ${THRESHOLD}%)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$PROJECT_DIR"

# Detect test framework
if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ] || grep -q '"jest"' package.json 2>/dev/null; then
  FRAMEWORK="jest"
elif [ -f "karma.conf.js" ]; then
  FRAMEWORK="karma"
elif [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
  FRAMEWORK="vitest"
elif [ -f "pubspec.yaml" ]; then
  FRAMEWORK="flutter"
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  FRAMEWORK="pytest"
else
  echo "❌ No recognized test framework found"
  exit 1
fi

echo "Framework: $FRAMEWORK"
echo ""

case $FRAMEWORK in
  jest)
    echo "Running jest with coverage..."
    npx jest --coverage --coverageReporters=text-summary 2>&1 | tee /tmp/coverage-output.txt
    
    # Extract coverage percentage
    COVERAGE=$(grep "Lines" /tmp/coverage-output.txt | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    ;;
    
  vitest)
    echo "Running vitest with coverage..."
    npx vitest run --coverage 2>&1 | tee /tmp/coverage-output.txt
    COVERAGE=$(grep "Lines" /tmp/coverage-output.txt | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "0")
    ;;
    
  flutter)
    echo "Running flutter test with coverage..."
    flutter test --coverage 2>&1
    if [ -f "coverage/lcov.info" ]; then
      TOTAL_LINES=$(grep -c "DA:" coverage/lcov.info || echo "0")
      HIT_LINES=$(grep "DA:" coverage/lcov.info | grep -cv ",0$" || echo "0")
      if [ "$TOTAL_LINES" -gt 0 ]; then
        COVERAGE=$(awk "BEGIN {printf \"%.1f\", ($HIT_LINES / $TOTAL_LINES) * 100}")
      else
        COVERAGE="0"
      fi
    else
      echo "⚠️  coverage/lcov.info not found"
      COVERAGE="0"
    fi
    ;;
    
  pytest)
    echo "Running pytest with coverage..."
    python -m pytest --cov --cov-report=term-missing 2>&1 | tee /tmp/coverage-output.txt
    COVERAGE=$(grep "TOTAL" /tmp/coverage-output.txt | grep -oE '[0-9]+%' | tr -d '%' || echo "0")
    ;;
    
  *)
    echo "Coverage collection not supported for $FRAMEWORK"
    exit 1
    ;;
esac

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Coverage: ${COVERAGE}%"
echo "Threshold: ${THRESHOLD}%"

# Compare (using bc for float comparison)
PASS=$(awk "BEGIN {print ($COVERAGE >= $THRESHOLD)}")

if [ "$PASS" = "1" ]; then
  echo "🟢 PASS — Coverage meets threshold"
  exit 0
else
  echo "🔴 FAIL — Coverage below threshold!"
  echo "   Need ${THRESHOLD}%, got ${COVERAGE}%"
  exit 1
fi
