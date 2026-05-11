#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Install raydium-skill
# Fetches the latest version from the upstream source via npx skills add,
# then also copies the local pointer SKILL.md for offline reference.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
SKILL_NAME="raydium-skill"
UPSTREAM="https://github.com/sendaifun/skills"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/skills/$SKILL_NAME"

echo "  Installing $SKILL_NAME from upstream..."

# 1. Try npx skills add (installs latest from GitHub)
if command -v npx &>/dev/null; then
  if npx skills add "$UPSTREAM" 2>/dev/null; then
    echo "  Installed via npx skills add"
  else
    echo "  npx skills add failed — falling back to local pointer"
    mkdir -p "$DEST"
    cp "$SCRIPT_DIR/SKILL.md" "$DEST/"
    [[ -f "$SCRIPT_DIR/.keys.example" ]] && cp "$SCRIPT_DIR/.keys.example" "$DEST/.keys.example"
  fi
else
  echo "  npx not found — using local pointer"
  mkdir -p "$DEST"
  cp "$SCRIPT_DIR/SKILL.md" "$DEST/"
  [[ -f "$SCRIPT_DIR/.keys.example" ]] && cp "$SCRIPT_DIR/.keys.example" "$DEST/.keys.example"
fi

# 2. Ensure ~/.claude/CLAUDE.md references this skill
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$(dirname "$CLAUDE_MD")"
touch "$CLAUDE_MD"
if ! grep -q "skills/$SKILL_NAME" "$CLAUDE_MD" 2>/dev/null; then
  echo "" >> "$CLAUDE_MD"
  echo "## Skill: $SKILL_NAME" >> "$CLAUDE_MD"
  echo "See: ~/.claude/skills/$SKILL_NAME/SKILL.md" >> "$CLAUDE_MD"
fi

[[ "${1:-}" != "--quiet" ]] && echo "  Installed: $SKILL_NAME"
