#!/usr/bin/env bash
# test-settings-merge.sh — Test the install.sh settings.json merge logic
#
# Tests the merge_guardrail_hooks() function against COPIES of settings.json.
# NEVER touches ~/.claude/settings.json.
#
# Usage:
#   build/hooks/test-settings-merge.sh         # run all tests
#   build/hooks/test-settings-merge.sh --verbose
#
# Exit 0 = all tests passed. Exit 1 = one or more failed.

set -euo pipefail

VERBOSE=false
[[ "${1:-}" == "--verbose" ]] && VERBOSE=true

PASS=0
FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

HOOK_ISOLATION="/Users/johnkoht/.claude/build/hooks/isolation-guard.sh"
HOOK_PLAN="/Users/johnkoht/.claude/build/hooks/plan-redirect.sh"

log() { [[ "$VERBOSE" == true ]] && echo "$*" || true; }
pass() { PASS=$((PASS + 1)); echo "  PASS: $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL: $1"; echo "        $2"; }

# ---------------------------------------------------------------------------
# Core merge function (mirrors install.sh logic exactly)
# ---------------------------------------------------------------------------

merge_guardrail_hooks() {
  local settings_file="$1"

  python3 - "$settings_file" "$HOOK_ISOLATION" "$HOOK_PLAN" <<'PYEOF'
import json, sys, os

settings_file = sys.argv[1]
hook_isolation = sys.argv[2]
hook_plan = sys.argv[3]

# Load (or start empty)
try:
    with open(settings_file) as f:
        data = json.load(f)
except (json.JSONDecodeError, FileNotFoundError):
    data = {}

if not isinstance(data, dict):
    data = {}

# --- hooks section ---
hooks = data.get("hooks", {})
pre_tool_use = hooks.get("PreToolUse", [])

# Collect existing command paths to detect already-installed hooks
existing_commands = set()
for entry in pre_tool_use:
    for hook in entry.get("hooks", []):
        cmd = hook.get("command", "")
        existing_commands.add(cmd)

added = []

# Hook 1: isolation-guard — Edit|Write|MultiEdit|NotebookEdit
if hook_isolation not in existing_commands:
    pre_tool_use.append({
        "matcher": "Edit|Write|MultiEdit|NotebookEdit",
        "hooks": [{"type": "command", "command": hook_isolation}]
    })
    added.append("isolation-guard")

# Hook 2: plan-redirect — EnterPlanMode
if hook_plan not in existing_commands:
    pre_tool_use.append({
        "matcher": "EnterPlanMode",
        "hooks": [{"type": "command", "command": hook_plan}]
    })
    added.append("plan-redirect")

hooks["PreToolUse"] = pre_tool_use
data["hooks"] = hooks

# --- worktree.baseRef: head ---
worktree = data.get("worktree", {})
worktree["baseRef"] = "head"
data["worktree"] = worktree

# Write back
with open(settings_file, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

if added:
    print(f"  added hooks: {', '.join(added)}")
else:
    print("  hooks already present — no-op")
PYEOF
}

# ---------------------------------------------------------------------------
# Assertion helpers
# ---------------------------------------------------------------------------

assert_json_valid() {
  local file="$1" label="$2"
  if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
    pass "$label: JSON valid"
  else
    fail "$label: JSON invalid" "$(cat "$file")"
  fi
}

assert_hook_present_once() {
  local file="$1" hook_path="$2" label="$3"
  local count
  count=$(python3 - "$file" "$hook_path" <<'PYEOF'
import json, sys
data = json.load(open(sys.argv[1]))
hook_path = sys.argv[2]
pre = data.get("hooks", {}).get("PreToolUse", [])
count = sum(1 for e in pre for h in e.get("hooks", []) if h.get("command") == hook_path)
print(count)
PYEOF
)
  if [[ "$count" -eq 1 ]]; then
    pass "$label: hook present exactly once (count=$count)"
  else
    fail "$label: hook count wrong (expected 1, got $count)" "path=$hook_path"
  fi
}

assert_base_ref() {
  local file="$1" label="$2"
  local val
  val=$(python3 -c "import json; d=json.load(open('$file')); print(d.get('worktree',{}).get('baseRef','MISSING'))")
  if [[ "$val" == "head" ]]; then
    pass "$label: worktree.baseRef=head"
  else
    fail "$label: worktree.baseRef wrong" "got: $val"
  fi
}

assert_no_change() {
  local before="$1" after="$2" label="$3"
  if diff -q "$before" "$after" >/dev/null 2>&1; then
    pass "$label: idempotent (no change on re-run)"
  else
    fail "$label: not idempotent — second run changed the file" \
      "diff: $(diff "$before" "$after" | head -20)"
  fi
}

assert_key_preserved() {
  local file="$1" key="$2" expected="$3" label="$4"
  local val
  val=$(python3 -c "import json; d=json.load(open('$file')); print(d.get('$key', 'MISSING'))")
  if [[ "$val" == "$expected" ]]; then
    pass "$label: key '$key' preserved ($val)"
  else
    fail "$label: key '$key' wrong" "expected=$expected got=$val"
  fi
}

# ---------------------------------------------------------------------------
# Test 1: Empty {} settings
# ---------------------------------------------------------------------------

echo ""
echo "Test 1: empty settings {}"
T1="$TMPDIR_TEST/t1-settings.json"
echo '{}' > "$T1"

log "  Running merge..."
merge_guardrail_hooks "$T1"

assert_json_valid "$T1" "T1"
assert_hook_present_once "$T1" "$HOOK_ISOLATION" "T1"
assert_hook_present_once "$T1" "$HOOK_PLAN" "T1"
assert_base_ref "$T1" "T1"

# Idempotency: run again
cp "$T1" "$TMPDIR_TEST/t1-before-second.json"
log "  Running merge again (idempotency check)..."
merge_guardrail_hooks "$T1"
assert_no_change "$TMPDIR_TEST/t1-before-second.json" "$T1" "T1"

# ---------------------------------------------------------------------------
# Test 2: Realistic settings (mirrors ~/.claude/settings.json structure)
# ---------------------------------------------------------------------------

echo ""
echo "Test 2: realistic settings (existing keys preserved)"
T2="$TMPDIR_TEST/t2-settings.json"
cat > "$T2" <<'JSON'
{
  "model": "opus",
  "statusLine": {
    "type": "command",
    "command": "bash /Users/johnkoht/.claude/statusline-command.sh"
  },
  "enabledPlugins": {
    "typescript-lsp@claude-plugins-official": true,
    "paper-desktop@paper": true
  },
  "tui": "fullscreen",
  "skipDangerousModePermissionPrompt": true
}
JSON

log "  Running merge..."
merge_guardrail_hooks "$T2"

assert_json_valid "$T2" "T2"
assert_hook_present_once "$T2" "$HOOK_ISOLATION" "T2"
assert_hook_present_once "$T2" "$HOOK_PLAN" "T2"
assert_base_ref "$T2" "T2"

# Verify pre-existing keys are still there
assert_key_preserved "$T2" "model" "opus" "T2"
assert_key_preserved "$T2" "tui" "fullscreen" "T2"

# Idempotency
cp "$T2" "$TMPDIR_TEST/t2-before-second.json"
log "  Running merge again (idempotency check)..."
merge_guardrail_hooks "$T2"
assert_no_change "$TMPDIR_TEST/t2-before-second.json" "$T2" "T2"

# ---------------------------------------------------------------------------
# Test 3: Settings that already has worktree.baseRef (preserve it is head)
# ---------------------------------------------------------------------------

echo ""
echo "Test 3: settings with existing worktree.baseRef=head"
T3="$TMPDIR_TEST/t3-settings.json"
cat > "$T3" <<'JSON'
{
  "model": "sonnet",
  "worktree": {
    "baseRef": "head"
  }
}
JSON

log "  Running merge..."
merge_guardrail_hooks "$T3"

assert_json_valid "$T3" "T3"
assert_base_ref "$T3" "T3"
assert_hook_present_once "$T3" "$HOOK_ISOLATION" "T3"
assert_hook_present_once "$T3" "$HOOK_PLAN" "T3"

# Idempotency
cp "$T3" "$TMPDIR_TEST/t3-before-second.json"
merge_guardrail_hooks "$T3"
assert_no_change "$TMPDIR_TEST/t3-before-second.json" "$T3" "T3"

# ---------------------------------------------------------------------------
# Test 4: Settings that already has SOME hooks (should add only missing ones)
# ---------------------------------------------------------------------------

echo ""
echo "Test 4: settings with pre-existing hook (only missing ones added)"
T4="$TMPDIR_TEST/t4-settings.json"
cat > "$T4" <<JSON
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{"type": "command", "command": "/usr/local/bin/some-other-hook.sh"}]
      }
    ]
  }
}
JSON

log "  Running merge..."
merge_guardrail_hooks "$T4"

assert_json_valid "$T4" "T4"
assert_hook_present_once "$T4" "$HOOK_ISOLATION" "T4"
assert_hook_present_once "$T4" "$HOOK_PLAN" "T4"
assert_base_ref "$T4" "T4"

# Verify the pre-existing hook is still there
existing_count=$(python3 -c "
import json; d=json.load(open('$T4'))
pre=d.get('hooks',{}).get('PreToolUse',[])
count=sum(1 for e in pre for h in e.get('hooks',[]) if h.get('command')=='/usr/local/bin/some-other-hook.sh')
print(count)
")
if [[ "$existing_count" -eq 1 ]]; then
  pass "T4: pre-existing Bash hook preserved"
else
  fail "T4: pre-existing Bash hook lost" "count=$existing_count"
fi

# Idempotency
cp "$T4" "$TMPDIR_TEST/t4-before-second.json"
merge_guardrail_hooks "$T4"
assert_no_change "$TMPDIR_TEST/t4-before-second.json" "$T4" "T4"

# ---------------------------------------------------------------------------
# Test 5: Settings with hooks already fully installed (pure no-op after first write)
#
# The merge always writes pretty-printed JSON (json.dump). So the idempotency
# guarantee is: once merge has run once (normalizing formatting), a second run
# produces byte-identical output. T5 uses the post-merge output of T1 as its
# starting point to guarantee normalized input.
# ---------------------------------------------------------------------------

echo ""
echo "Test 5: hooks already fully installed — no-op on second run"
T5="$TMPDIR_TEST/t5-settings.json"
# Start from empty and run merge once (produces canonical pretty-printed JSON)
echo '{}' > "$T5"
merge_guardrail_hooks "$T5"  # first run — produces canonical form
cp "$T5" "$TMPDIR_TEST/t5-canonical.json"
log "  Running merge again on canonical output (should be pure no-op)..."
merge_guardrail_hooks "$T5"

assert_json_valid "$T5" "T5"
assert_no_change "$TMPDIR_TEST/t5-canonical.json" "$T5" "T5"
assert_hook_present_once "$T5" "$HOOK_ISOLATION" "T5"
assert_hook_present_once "$T5" "$HOOK_PLAN" "T5"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

echo ""
echo "─────────────────────────────────────────────"
echo "Results: $PASS passed, $FAIL failed"
echo "─────────────────────────────────────────────"
echo ""
echo "IMPORTANT: No writes to ~/.claude/settings.json (tested against copies only)."

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
