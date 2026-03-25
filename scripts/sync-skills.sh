#!/bin/bash
# CTO Toolkit — Sync Skills to Target Project
# Copies skills from cto-toolkit to a project's agent skills directory.
# Usage: ./sync-skills.sh [target_project_path] [skills_dir_name]
#
# Example:
#   ./sync-skills.sh ~/Documentos/camilo/ZECA/zeca_site .gemini/antigravity/skills
#   ./sync-skills.sh ~/my-project .claude/skills

set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_PROJECT="${1:-}"
SKILLS_DIR_NAME="${2:-.gemini/antigravity/skills}"

if [ -z "$TARGET_PROJECT" ]; then
  echo "Usage: ./sync-skills.sh <target_project_path> [skills_dir_name]"
  echo ""
  echo "Example:"
  echo "  ./sync-skills.sh ~/Documentos/camilo/ZECA/zeca_site"
  echo "  ./sync-skills.sh ~/my-project .claude/skills"
  exit 1
fi

TARGET_SKILLS="$TARGET_PROJECT/$SKILLS_DIR_NAME"

echo "🔄 CTO Toolkit → Project Sync"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source: $TOOLKIT_DIR"
echo "Target: $TARGET_SKILLS"
echo ""

# Ensure target directory exists
mkdir -p "$TARGET_SKILLS"

# Find all SKILL.md files in toolkit
SKILL_COUNT=0
SYNCED=0
SKIPPED=0

find "$TOOLKIT_DIR" -name "SKILL.md" -not -path "*/node_modules/*" -not -path "*/.git/*" | while read -r skill_file; do
  SKILL_DIR=$(dirname "$skill_file")
  SKILL_NAME=$(basename "$SKILL_DIR")
  
  # Skip non-skill directories
  if [ "$SKILL_NAME" = "cto-toolkit" ]; then
    continue
  fi
  
  SKILL_COUNT=$((SKILL_COUNT + 1))
  TARGET_SKILL_DIR="$TARGET_SKILLS/$SKILL_NAME"
  
  # Check if skill already exists in target
  if [ -d "$TARGET_SKILL_DIR" ]; then
    # Compare timestamps
    SOURCE_MOD=$(stat -f %m "$skill_file" 2>/dev/null || stat -c %Y "$skill_file" 2>/dev/null || echo "0")
    TARGET_MOD=$(stat -f %m "$TARGET_SKILL_DIR/SKILL.md" 2>/dev/null || stat -c %Y "$TARGET_SKILL_DIR/SKILL.md" 2>/dev/null || echo "0")
    
    if [ "$SOURCE_MOD" -le "$TARGET_MOD" ] 2>/dev/null; then
      echo "  ⏭️  $SKILL_NAME (up to date)"
      SKIPPED=$((SKIPPED + 1))
      continue
    fi
  fi
  
  # Create target directory and copy
  mkdir -p "$TARGET_SKILL_DIR"
  
  # Copy SKILL.md
  cp "$skill_file" "$TARGET_SKILL_DIR/SKILL.md"
  
  # Copy references/ if exists
  if [ -d "$SKILL_DIR/references" ]; then
    mkdir -p "$TARGET_SKILL_DIR/references"
    cp -r "$SKILL_DIR/references/"* "$TARGET_SKILL_DIR/references/" 2>/dev/null || true
    echo "  ✅ $SKILL_NAME (SKILL.md + references/)"
  else
    echo "  ✅ $SKILL_NAME (SKILL.md)"
  fi
  
  SYNCED=$((SYNCED + 1))
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏁 Sync complete"
echo "   Synced: skills updated"
echo "   Target: $TARGET_SKILLS"
