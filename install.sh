#!/usr/bin/env bash
set -e

REPO="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing build-os from $REPO"
echo ""

# Commands → global slash commands
if [ -L "$CLAUDE_DIR/commands" ] && [ "$(readlink "$CLAUDE_DIR/commands")" = "$REPO/commands" ]; then
  echo "✓ commands/ already linked"
elif [ -d "$CLAUDE_DIR/commands" ] && [ ! -L "$CLAUDE_DIR/commands" ]; then
  echo "⚠️  ~/.claude/commands/ exists as a real directory — merging not supported."
  echo "   Move or rename it, then re-run install.sh"
  exit 1
else
  ln -sf "$REPO/commands" "$CLAUDE_DIR/commands"
  echo "✓ linked commands/ → ~/.claude/commands/"
fi

# Build support files
if [ -L "$CLAUDE_DIR/build" ] && [ "$(readlink "$CLAUDE_DIR/build")" = "$REPO/build" ]; then
  echo "✓ build/ already linked"
elif [ -d "$CLAUDE_DIR/build" ] && [ ! -L "$CLAUDE_DIR/build" ]; then
  echo "⚠️  ~/.claude/build/ exists as a real directory"
  echo "   Move or rename it, then re-run install.sh"
  exit 1
else
  ln -sf "$REPO/build" "$CLAUDE_DIR/build"
  echo "✓ linked build/ → ~/.claude/build/"
fi

# Global CLAUDE.md — skip if exists, print merge instructions
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  ln -sf "$REPO/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
  echo "✓ linked CLAUDE.md → ~/.claude/CLAUDE.md"
else
  echo "⚠️  ~/.claude/CLAUDE.md already exists — not overwriting."
  echo "   Manually merge content from $REPO/CLAUDE.md"
fi

# Seed collaboration.md from example if not present (personal, gitignored)
if [ ! -f "$REPO/build/memory/collaboration.md" ]; then
  cp "$REPO/build/memory/collaboration.md.example" "$REPO/build/memory/collaboration.md"
  echo "✓ seeded build/memory/collaboration.md from example"
else
  echo "✓ collaboration.md exists (personal preferences preserved)"
fi

# new-project CLI → ~/.local/bin/new-project
chmod +x "$REPO/bin/new-project"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
if [ -L "$LOCAL_BIN/new-project" ] && [ "$(readlink "$LOCAL_BIN/new-project")" = "$REPO/bin/new-project" ]; then
  echo "✓ new-project CLI already linked"
else
  ln -sf "$REPO/bin/new-project" "$LOCAL_BIN/new-project"
  echo "✓ linked new-project → ~/.local/bin/new-project"
fi

# Ensure ~/.local/bin is on PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
  echo ""
  echo "⚠️  ~/.local/bin is not on your PATH."
  echo "   Add this to your ~/.zshrc or ~/.bashrc:"
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
echo "Slash commands: /ship /build /hotfix /review /pre-mortem /plan-to-prd /post-mortem /wrap /new-project"
echo "CLI command:    new-project <name> [--lang typescript|ruby|python|go]"
