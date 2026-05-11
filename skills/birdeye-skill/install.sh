#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Install birdeye-skill
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
SKILL_NAME="birdeye-skill"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$HOME/.claude/skills/$SKILL_NAME"

mkdir -p "$DEST"
cp "$SCRIPT_DIR/SKILL.md" "$DEST/"
[[ -f "$SCRIPT_DIR/.keys.example" ]] && cp "$SCRIPT_DIR/.keys.example" "$DEST/.keys.example"

# Ensure ~/.claude/CLAUDE.md references this skill
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
mkdir -p "$(dirname "$CLAUDE_MD")"
touch "$CLAUDE_MD"
if ! grep -q "skills/$SKILL_NAME" "$CLAUDE_MD" 2>/dev/null; then
  echo "" >> "$CLAUDE_MD"
  echo "## Skill: $SKILL_NAME" >> "$CLAUDE_MD"
  echo "See: ~/.claude/skills/$SKILL_NAME/SKILL.md" >> "$CLAUDE_MD"
fi

[[ "${1:-}" != "--quiet" ]] && echo "  Installed: $SKILL_NAME"
