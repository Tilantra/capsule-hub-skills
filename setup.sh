#!/usr/bin/env bash
# setup.sh — Links Capsule Hub skills into ~/.claude/skills/
# Run once after cloning. Re-run after pulling updates (symlinks persist).

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

SKILLS=(
  capsule-login
  capsule-search
  capsule-read
  capsule-save
  capsule-version
  capsule-team
)

echo "Capsule Hub Skills — setup"
echo "Repo:       $REPO_DIR"
echo "Skills dir: $SKILLS_DIR"
echo ""

mkdir -p "$SKILLS_DIR"

for skill in "${SKILLS[@]}"; do
  target="$SKILLS_DIR/$skill"
  source="$REPO_DIR/$skill"

  if [ ! -d "$source" ]; then
    echo "SKIP  $skill — directory not found in repo"
    continue
  fi

  if [ -L "$target" ]; then
    ln -sf "$source" "$target"
    echo "UPDATED  $target"
  elif [ -d "$target" ]; then
    echo "SKIP     $target already exists as a real directory (not a symlink). Remove it manually first."
  else
    ln -s "$source" "$target"
    echo "LINKED   $target -> $source"
  fi
done

echo ""
echo "Done."
echo ""
echo "────────────────────────────────────────────"
echo " One-time env setup (add to ~/.zshrc or ~/.bashrc):"
echo ""
echo "   export CAPSULE_API_BASE=https://backend.tilantra.com"
echo ""
echo " Then reload your shell:"
echo "   source ~/.zshrc   # or ~/.bashrc"
echo ""
echo " Each new terminal session, authenticate:"
echo "   /capsule-login"
echo "────────────────────────────────────────────"
