#!/bin/bash
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

SKILL_REPO_DIR="$HOME/.claude/skill-sources/last30days-skill"
SKILL_LINK="$HOME/.claude/skills/last30days"

mkdir -p "$(dirname "$SKILL_REPO_DIR")" "$(dirname "$SKILL_LINK")"

if [ -d "$SKILL_REPO_DIR/.git" ]; then
  git -C "$SKILL_REPO_DIR" pull --ff-only
else
  rm -rf "$SKILL_REPO_DIR"
  git clone https://github.com/mvanhorn/last30days-skill.git "$SKILL_REPO_DIR"
fi

ln -sfn "$SKILL_REPO_DIR/skills/last30days" "$SKILL_LINK"
