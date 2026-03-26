#!/bin/bash
# CTO Toolkit — Auto-Activation Hook (SessionStart)
#
# Scans the project to detect frameworks, file patterns, and context,
# then suggests which skills to activate based on the enriched frontmatter.
#
# Inspired by everything-claude-code's skill activation pattern.

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$(dirname "$0")")")}"

# Detect project root (look for common markers)
PROJECT_ROOT="."
for marker in package.json go.mod Cargo.toml pyproject.toml pom.xml build.gradle pubspec.yaml; do
  if [ -f "$marker" ]; then
    PROJECT_ROOT="$(pwd)"
    break
  fi
done

# ─── Framework Detection ──────────────────────────────────────

FRAMEWORKS=""

# Node.js ecosystem
[ -f "package.json" ] && {
  DEPS=$(cat package.json 2>/dev/null)
  echo "$DEPS" | grep -q '"express"' && FRAMEWORKS="$FRAMEWORKS express"
  echo "$DEPS" | grep -q '"@nestjs' && FRAMEWORKS="$FRAMEWORKS nestjs"
  echo "$DEPS" | grep -q '"fastify"' && FRAMEWORKS="$FRAMEWORKS fastify"
  echo "$DEPS" | grep -q '"react"' && FRAMEWORKS="$FRAMEWORKS react"
  echo "$DEPS" | grep -q '"@angular' && FRAMEWORKS="$FRAMEWORKS angular"
  echo "$DEPS" | grep -q '"vue"' && FRAMEWORKS="$FRAMEWORKS vue"
  echo "$DEPS" | grep -q '"next"' && FRAMEWORKS="$FRAMEWORKS nextjs"
  echo "$DEPS" | grep -q '"prisma"' && FRAMEWORKS="$FRAMEWORKS prisma"
  echo "$DEPS" | grep -q '"typeorm"' && FRAMEWORKS="$FRAMEWORKS typeorm"
  echo "$DEPS" | grep -q '"sequelize"' && FRAMEWORKS="$FRAMEWORKS sequelize"
  echo "$DEPS" | grep -q '"@apollo' && FRAMEWORKS="$FRAMEWORKS apollo"
  echo "$DEPS" | grep -q '"graphql"' && FRAMEWORKS="$FRAMEWORKS graphql"
  echo "$DEPS" | grep -q '"jest"' && FRAMEWORKS="$FRAMEWORKS jest"
  echo "$DEPS" | grep -q '"vitest"' && FRAMEWORKS="$FRAMEWORKS vitest"
  echo "$DEPS" | grep -q '"tensorflow"' && FRAMEWORKS="$FRAMEWORKS tensorflow"
  echo "$DEPS" | grep -q '"langchain"' && FRAMEWORKS="$FRAMEWORKS langchain"
  echo "$DEPS" | grep -q '"openai"' && FRAMEWORKS="$FRAMEWORKS openai"
}

# Go
[ -f "go.mod" ] && {
  FRAMEWORKS="$FRAMEWORKS go"
  grep -q "gin-gonic" go.mod 2>/dev/null && FRAMEWORKS="$FRAMEWORKS gin"
  grep -q "echo" go.mod 2>/dev/null && FRAMEWORKS="$FRAMEWORKS echo"
  grep -q "grpc" go.mod 2>/dev/null && FRAMEWORKS="$FRAMEWORKS grpc-go"
}

# Rust
[ -f "Cargo.toml" ] && {
  FRAMEWORKS="$FRAMEWORKS rust"
  grep -q "tokio" Cargo.toml 2>/dev/null && FRAMEWORKS="$FRAMEWORKS tokio"
  grep -q "actix" Cargo.toml 2>/dev/null && FRAMEWORKS="$FRAMEWORKS actix"
  grep -q "axum" Cargo.toml 2>/dev/null && FRAMEWORKS="$FRAMEWORKS axum"
}

# Python
[ -f "pyproject.toml" ] || [ -f "requirements.txt" ] && {
  FRAMEWORKS="$FRAMEWORKS python"
  PYFILES="pyproject.toml requirements.txt"
  for f in $PYFILES; do
    [ -f "$f" ] && {
      grep -qi "django" "$f" 2>/dev/null && FRAMEWORKS="$FRAMEWORKS django"
      grep -qi "flask" "$f" 2>/dev/null && FRAMEWORKS="$FRAMEWORKS flask"
      grep -qi "fastapi" "$f" 2>/dev/null && FRAMEWORKS="$FRAMEWORKS fastapi"
      grep -qi "pytorch\|torch" "$f" 2>/dev/null && FRAMEWORKS="$FRAMEWORKS pytorch"
      grep -qi "scikit" "$f" 2>/dev/null && FRAMEWORKS="$FRAMEWORKS scikit-learn"
    }
  done
}

# Flutter/Dart
[ -f "pubspec.yaml" ] && {
  FRAMEWORKS="$FRAMEWORKS flutter dart"
  grep -q "riverpod" pubspec.yaml 2>/dev/null && FRAMEWORKS="$FRAMEWORKS riverpod"
  grep -q "bloc" pubspec.yaml 2>/dev/null && FRAMEWORKS="$FRAMEWORKS bloc"
}

# C# / .NET
ls *.csproj 2>/dev/null | head -1 | grep -q . && FRAMEWORKS="$FRAMEWORKS dotnet"
ls *.sln 2>/dev/null | head -1 | grep -q . && FRAMEWORKS="$FRAMEWORKS dotnet"

# Swift
[ -f "Package.swift" ] && FRAMEWORKS="$FRAMEWORKS swift swiftui"

# Elixir
[ -f "mix.exs" ] && {
  FRAMEWORKS="$FRAMEWORKS elixir"
  grep -q "phoenix" mix.exs 2>/dev/null && FRAMEWORKS="$FRAMEWORKS phoenix"
}

# Java
[ -f "pom.xml" ] || [ -f "build.gradle" ] && {
  FRAMEWORKS="$FRAMEWORKS java"
  grep -qi "spring" pom.xml build.gradle 2>/dev/null && FRAMEWORKS="$FRAMEWORKS spring"
}

# Infrastructure
[ -d ".github/workflows" ] && FRAMEWORKS="$FRAMEWORKS github-actions"
ls Dockerfile* 2>/dev/null | head -1 | grep -q . && FRAMEWORKS="$FRAMEWORKS docker"
ls docker-compose* 2>/dev/null | head -1 | grep -q . && FRAMEWORKS="$FRAMEWORKS docker"
[ -d "terraform" ] || ls *.tf 2>/dev/null | head -1 | grep -q . && FRAMEWORKS="$FRAMEWORKS terraform"
[ -d "k8s" ] || [ -d "charts" ] && FRAMEWORKS="$FRAMEWORKS kubernetes"
[ -d "dbt" ] && FRAMEWORKS="$FRAMEWORKS dbt"

# ─── File Pattern Detection ───────────────────────────────────

HAS_TESTS=false
HAS_MIGRATIONS=false
HAS_GRAPHQL=false
HAS_OPENAPI=false
HAS_ML_FILES=false

find . -maxdepth 4 -name "*.test.*" -o -name "*.spec.*" 2>/dev/null | head -1 | grep -q . && HAS_TESTS=true
find . -maxdepth 4 -path "*/migrations/*" 2>/dev/null | head -1 | grep -q . && HAS_MIGRATIONS=true
find . -maxdepth 4 -name "*.graphql" 2>/dev/null | head -1 | grep -q . && HAS_GRAPHQL=true
find . -maxdepth 4 -name "openapi.*" -o -name "swagger.*" 2>/dev/null | head -1 | grep -q . && HAS_OPENAPI=true
find . -maxdepth 4 -name "*.ipynb" -o -path "*/models/*" -o -path "*/ml/*" 2>/dev/null | head -1 | grep -q . && HAS_ML_FILES=true

# ─── Skill Matching ───────────────────────────────────────────

SUGGESTED=""

# Parse each skill's frontmatter and match against detected context
for skill_dir in "$PLUGIN_ROOT"/*/; do
  skill_file="$skill_dir/SKILL.md"
  [ -f "$skill_file" ] || continue

  skill_name=$(basename "$skill_dir")

  # Skip non-skill directories
  case "$skill_name" in
    hooks|scripts|agents|adr) continue ;;
  esac

  # Extract trigger frameworks from frontmatter
  trigger_frameworks=$(sed -n '/^triggers:/,/^[a-z]/p' "$skill_file" 2>/dev/null | grep "frameworks:" | sed 's/.*\[//;s/\].*//' | tr ',' ' ')

  matched=false
  for fw in $trigger_frameworks; do
    fw=$(echo "$fw" | tr -d ' ')
    for detected in $FRAMEWORKS; do
      if [ "$fw" = "$detected" ]; then
        matched=true
        break 2
      fi
    done
  done

  $matched && SUGGESTED="$SUGGESTED $skill_name"
done

# ─── Output ───────────────────────────────────────────────────

if [ -n "$FRAMEWORKS" ] || [ -n "$SUGGESTED" ]; then
  echo "🔍 CTO Toolkit — Project Context Detected"
  echo ""
  [ -n "$FRAMEWORKS" ] && echo "  Frameworks: $(echo $FRAMEWORKS | tr ' ' ', ')"
  $HAS_TESTS && echo "  Tests: detected"
  $HAS_MIGRATIONS && echo "  Migrations: detected"
  $HAS_GRAPHQL && echo "  GraphQL: detected"
  $HAS_OPENAPI && echo "  OpenAPI: detected"
  $HAS_ML_FILES && echo "  ML files: detected"

  if [ -n "$SUGGESTED" ]; then
    echo ""
    echo "  Suggested skills:$(echo $SUGGESTED | tr ' ' '\n' | sort -u | sed 's/^/ \/cto-toolkit:/')"
  fi
fi

exit 0
