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
  # Materialized commands dir is the EXPECTED state after `build-config sync --global`
  # (it replaces the symlink with a real dir). Not an error — build-config owns it.
  echo "ℹ️  ~/.claude/commands/ is a materialized directory (managed by build-config sync)."
  echo "   Skills refresh via 'build-config sync --global' — continuing to hooks setup."
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

# build-config CLI → ~/.local/bin/build-config
chmod +x "$REPO/bin/build-config"
if [ -L "$LOCAL_BIN/build-config" ] && [ "$(readlink "$LOCAL_BIN/build-config")" = "$REPO/bin/build-config" ]; then
  echo "✓ build-config CLI already linked"
else
  ln -sf "$REPO/bin/build-config" "$LOCAL_BIN/build-config"
  echo "✓ linked build-config → ~/.local/bin/build-config"
fi

# Ensure ~/.local/bin is on PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
  echo ""
  echo "⚠️  ~/.local/bin is not on your PATH."
  echo "   Add this to your ~/.zshrc or ~/.bashrc:"
  echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

# ---------------------------------------------------------------------------
# Guardrail hooks — merge into ~/.claude/settings.json
#
# Safety rules (see plans/protocol-guardrails/pre-mortem.md R2):
#   - Back up settings.json before any write.
#   - Use python3 for JSON manipulation to preserve all existing keys.
#   - Validate JSON parses after merge.
#   - Idempotent: no-op if hooks already present (detected by command path).
#   - ABSOLUTE paths only — no ~ expansion in settings.json.
#
# These hooks are fail-open — they never break editing even if misconfig'd.
# See build/hooks/README.md for hook behavior details.
# Test the merge logic before running live: build/hooks/test-settings-merge.sh
#
# Note: build-os itself is intentionally NOT given .build/ — adding it would
# make isolation-guard and plan-redirect fire during framework development
# (editing build-os source is the normal workflow here, not an ad-hoc violation).
# This is deferred to backlog. See plans/protocol-guardrails/review.md note 6.
# ---------------------------------------------------------------------------

SETTINGS_FILE="$CLAUDE_DIR/settings.json"
HOOK_ISOLATION="$CLAUDE_DIR/build/hooks/isolation-guard.sh"
HOOK_PLAN="$CLAUDE_DIR/build/hooks/plan-redirect.sh"

echo "Merging guardrail hooks into settings.json..."

# Verify hook scripts exist and are executable (they live under build/ symlink)
if [[ ! -x "$HOOK_ISOLATION" ]]; then
  echo "⚠️  Hook not found/executable: $HOOK_ISOLATION"
  echo "   Ensure build/ symlink is installed first (see above). Skipping hooks merge."
elif [[ ! -x "$HOOK_PLAN" ]]; then
  echo "⚠️  Hook not found/executable: $HOOK_PLAN"
  echo "   Ensure build/ symlink is installed first (see above). Skipping hooks merge."
else
  # Ensure settings.json exists (create minimal if absent)
  if [[ ! -f "$SETTINGS_FILE" ]]; then
    echo '{}' > "$SETTINGS_FILE"
    echo "  created $SETTINGS_FILE (was absent)"
  fi

  # Back up before first merge (idempotent: only if backup doesn't already exist for today)
  BACKUP="$SETTINGS_FILE.bak-$(date +%Y%m%d)"
  if [[ ! -f "$BACKUP" ]]; then
    cp "$SETTINGS_FILE" "$BACKUP"
    echo "  backed up to $BACKUP"
  fi

  # Run the merge via python3 (preserves all existing keys)
  python3 - "$SETTINGS_FILE" "$HOOK_ISOLATION" "$HOOK_PLAN" <<'PYEOF'
import json, sys

settings_file = sys.argv[1]
hook_isolation = sys.argv[2]
hook_plan = sys.argv[3]

# Load existing settings
try:
    with open(settings_file) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

if not isinstance(data, dict):
    data = {}

# --- hooks.PreToolUse ---
hooks = data.get("hooks", {})
pre_tool_use = hooks.get("PreToolUse", [])

# Collect existing command paths to detect already-installed hooks
existing_commands = set()
for entry in pre_tool_use:
    for hook in entry.get("hooks", []):
        cmd = hook.get("command", "")
        existing_commands.add(cmd)

added = []

# Hook 1: isolation-guard — fires on Edit|Write|MultiEdit|NotebookEdit
if hook_isolation not in existing_commands:
    pre_tool_use.append({
        "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [{"type": "command", "command": hook_isolation}]
    })
    added.append("isolation-guard")

# Hook 2: plan-redirect — fires on EnterPlanMode
if hook_plan not in existing_commands:
    pre_tool_use.append({
        "matcher": "EnterPlanMode",
        "hooks": [{"type": "command", "command": hook_plan}]
    })
    added.append("plan-redirect")

hooks["PreToolUse"] = pre_tool_use
data["hooks"] = hooks

# --- worktree.baseRef: head (ensures worktree includes plan/PRD commits on main) ---
worktree = data.get("worktree", {})
worktree["baseRef"] = "head"
data["worktree"] = worktree

# Write back
with open(settings_file, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

if added:
    print(f"  added hooks: {', '.join(added)}")
    print(f"  set worktree.baseRef: head")
else:
    print("  hooks already present — no-op")
PYEOF

  # Validate the result parses as JSON
  if python3 -c "import json; json.load(open('$SETTINGS_FILE'))" 2>/dev/null; then
    echo "✓ settings.json hooks merged + validated"
  else
    echo "❌ settings.json failed JSON validation after merge — restoring backup"
    cp "$BACKUP" "$SETTINGS_FILE"
    echo "  restored from $BACKUP"
    exit 1
  fi
fi

echo ""
echo "Slash commands: /ship /build /hotfix /review /pre-mortem /plan-to-prd /post-mortem /wrap /build-os-retrofit /new-project /plan /approve"
echo "CLI commands:   new-project <name> [--lang typescript|ruby|python|go]"
echo "                build-config init|sync|show — per-skill model configuration"

echo ""
echo "→ Optional: run \`build-config init --global\` to configure per-skill models."
echo "  First sync replaces the ~/.claude/commands symlink with a real directory."
echo "  Requires pyyaml — build-config prints install instructions if missing."

# ---------------------------------------------------------------------------
# build-config sync — materialize new/modified skills into ~/.claude/commands
#
# ~/.claude/commands is currently a REAL directory (not a symlink).
# New and modified skills (/plan, /approve, /hotfix, /ship, /build) are dark
# code until build-config sync copies them into that directory.
#
# IMPORTANT: This is a manual step because sync mutates the live ~/.claude/commands
# (which is shared with the running Claude Code session). Run it yourself:
#
#   build-config sync --global
#
# After sync, verify these slash commands are invocable in Claude Code:
#   /plan    — new skill (task-3)
#   /approve — new skill (task-4)
#   /ship    — updated (lite mode, native worktrees)
#   /hotfix  — updated (mandatory reviewer)
#   /build   — updated (fix-routing note)
#
# Dark-code check: type /plan in a Claude Code session — it should resolve as a
# slash command. If it shows "unknown command", re-run build-config sync --global.
# ---------------------------------------------------------------------------

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "NEXT STEP — run this to activate new/modified skills:"
echo ""
echo "  build-config sync --global"
echo ""
echo "Then verify in Claude Code:"
echo "  /plan    → should resolve as a slash command (new)"
echo "  /approve → should resolve as a slash command (new)"
echo "  /ship    → lite mode + native worktrees"
echo "  /hotfix  → mandatory reviewer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
