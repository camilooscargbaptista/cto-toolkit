#!/bin/bash
# Scans codebase for potential hardcoded secrets
# Usage: ./scan-secrets.sh [directory]

TARGET="${1:-.}"

echo "=== Secret Scan Report ==="
echo "Target: $TARGET"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

echo "## Potential Hardcoded Secrets"
grep -rn --include="*.ts" --include="*.js" --include="*.dart" --include="*.java" \
  --include="*.py" --include="*.yml" --include="*.yaml" --include="*.json" \
  --include="*.env*" --include="*.properties" --include="*.xml" \
  -iE "(password|passwd|secret|api_key|apiKey|api-key|token|credential|private_key|auth_token|access_key|client_secret)\s*[:=]" \
  --color=never "$TARGET" 2>/dev/null \
  | grep -v node_modules | grep -v ".lock" | grep -v dist/ | grep -v build/ \
  | grep -v __pycache__ | grep -v ".git/" | grep -v "*.test.*" \
  || echo "None found"

echo ""
echo "## AWS Keys Pattern"
grep -rn --include="*.ts" --include="*.js" --include="*.py" --include="*.java" \
  --include="*.yml" --include="*.yaml" --include="*.env*" \
  -E "(AKIA[0-9A-Z]{16}|aws_secret_access_key)" \
  --color=never "$TARGET" 2>/dev/null \
  | grep -v node_modules | grep -v ".lock" \
  || echo "None found"

echo ""
echo "## Private Keys"
grep -rln --include="*.pem" --include="*.key" --include="*.p12" \
  -E "(BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY)" \
  "$TARGET" 2>/dev/null \
  | grep -v node_modules \
  || echo "None found"

echo ""
echo "## .env Files (should not be committed)"
find "$TARGET" -name ".env" -o -name ".env.local" -o -name ".env.production" \
  2>/dev/null | grep -v node_modules | grep -v ".git/" \
  || echo "None found"

echo ""
echo "## High-Entropy Strings (possible tokens)"
grep -rn --include="*.ts" --include="*.js" --include="*.dart" --include="*.java" \
  -E "['\"][A-Za-z0-9+/=]{40,}['\"]" \
  --color=never "$TARGET" 2>/dev/null \
  | grep -v node_modules | grep -v ".lock" | grep -v dist/ \
  | head -20 \
  || echo "None found"
