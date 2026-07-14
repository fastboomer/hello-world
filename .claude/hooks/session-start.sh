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

# --- llm-council: single SKILL.md, no build step. Skip if already cloned. ---
COUNCIL_DIR="$HOME/.claude/skills/llm-council"
if [ ! -d "$COUNCIL_DIR/.git" ]; then
  rm -rf "$COUNCIL_DIR"
  git clone https://github.com/tenfoldmarc/llm-council-skill.git "$COUNCIL_DIR" || true
fi

# --- gstack: clone + build once; skip entirely once linked. ---
GSTACK_DIR="$HOME/.claude/skills/gstack"
GSTACK_MARKER="$HOME/.claude/skills/_gstack-command"

if [ ! -d "$GSTACK_DIR/.git" ]; then
  rm -rf "$GSTACK_DIR"
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$GSTACK_DIR" || true
fi

if [ -d "$GSTACK_DIR/.git" ] && [ ! -d "$GSTACK_MARKER" ]; then
  # This sandbox only has Chromium revision 1194 pre-installed and can't reach
  # cdn.playwright.dev to fetch newer revisions, so pin playwright to the last
  # release that targets 1194 - otherwise ./setup exits before linking skills.
  sed -i 's/"playwright": "[^"]*"/"playwright": "1.56.1"/' "$GSTACK_DIR/package.json" || true
  ( cd "$GSTACK_DIR" && ./setup ) || true
fi

# --- superpowers: clone once, symlink each of its skills individually. ---
# The remote sandbox has no `/plugin` marketplace support, so install the
# same skills the "superpowers@claude-plugins-official" plugin ships.
SUPERPOWERS_DIR="$HOME/.claude/skill-sources/superpowers"
if [ -d "$SUPERPOWERS_DIR/.git" ]; then
  git -C "$SUPERPOWERS_DIR" pull --ff-only || true
else
  rm -rf "$SUPERPOWERS_DIR"
  git clone --depth 1 https://github.com/obra/superpowers.git "$SUPERPOWERS_DIR" || true
fi

if [ -d "$SUPERPOWERS_DIR/skills" ]; then
  for skill_dir in "$SUPERPOWERS_DIR"/skills/*/; do
    skill_name="$(basename "$skill_dir")"
    ln -sfn "$skill_dir" "$HOME/.claude/skills/$skill_name"
  done
fi
