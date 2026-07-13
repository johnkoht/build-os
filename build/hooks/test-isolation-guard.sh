#!/usr/bin/env bash
# test-isolation-guard.sh — Test harness for isolation-guard.sh
#
# Uses temp git repos to test all required cases:
#  (a) .ts edit in a NON-build-os git repo (no .build/) → passes through (no `ask`)
#  (b) source edit on MAIN checkout of a repo WITH .build/ → emits `ask`
#  (c) plans/foo.md edit on main of a .build/ repo → passes through
#  (d) edit inside a path whose git-dir contains /worktrees/ → passes through
#  (e) missing file_path / malformed JSON → exit 0 (fail-open)

set -euo pipefail

HOOK_SCRIPT="$(dirname "$0")/isolation-guard.sh"

# Verify the hook script exists
if [[ ! -f "$HOOK_SCRIPT" ]]; then
  echo "ERROR: Hook script not found at $HOOK_SCRIPT" >&2
  exit 1
fi

PASS=0
FAIL=0
ERRORS=()

# --- Helpers -----------------------------------------------------------------

pass() {
  local name="$1"
  echo "  PASS: $name"
  PASS=$((PASS + 1))
}

fail() {
  local name="$1"
  local msg="$2"
  echo "  FAIL: $name — $msg"
  FAIL=$((FAIL + 1))
  ERRORS+=("$name: $msg")
}

# Build synthetic tool-call JSON
make_json() {
  local file_path="$1"
  local cwd="$2"
  local tool="${3:-Edit}"
  # Use python3 to safely build JSON (avoids jq dependency in the test itself)
  python3 -c "
import json, sys
obj = {
  'tool_name': '$tool',
  'tool_input': {'file_path': '$file_path'},
  'cwd': '$cwd'
}
print(json.dumps(obj))
"
}

# Build JSON with notebook_path instead of file_path (for NotebookEdit)
make_notebook_json() {
  local notebook_path="$1"
  local cwd="$2"
  python3 -c "
import json, sys
obj = {
  'tool_name': 'NotebookEdit',
  'tool_input': {'notebook_path': '$notebook_path'},
  'cwd': '$cwd'
}
print(json.dumps(obj))
"
}

# Run the hook and check whether output contains "ask"
run_hook() {
  local json_input="$1"
  local output
  output="$(echo "$json_input" | bash "$HOOK_SCRIPT" 2>/dev/null)"
  echo "$output"
}

should_ask() {
  local output="$1"
  echo "$output" | python3 -c "
import json, sys
data = sys.stdin.read().strip()
if not data:
  sys.exit(1)
try:
  obj = json.loads(data)
  decision = obj.get('hookSpecificOutput', {}).get('permissionDecision', '')
  sys.exit(0 if decision == 'ask' else 1)
except Exception:
  sys.exit(1)
" 2>/dev/null
}

should_pass() {
  local output="$1"
  # Pass-through means no output (exit 0 with no JSON)
  [[ -z "$output" ]]
}

# --- Setup temp repos --------------------------------------------------------

TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

echo ""
echo "isolation-guard.sh test harness"
echo "================================"
echo ""

# --- Case (a): .ts edit in a NON-build-os git repo (no .build/) --------------
echo "Case (a): .ts edit in a NON-build-os git repo → should pass through"

REPO_A="${TMPDIR_BASE}/repo-no-build"
mkdir -p "$REPO_A/src"
git -C "$REPO_A" init -q
touch "$REPO_A/src/index.ts"
git -C "$REPO_A" add . && git -C "$REPO_A" commit -q -m "init"

JSON_A="$(make_json "${REPO_A}/src/index.ts" "${REPO_A}/src")"
OUTPUT_A="$(run_hook "$JSON_A")"

if should_pass "$OUTPUT_A"; then
  pass "(a) non-build-os .ts edit passes through"
else
  fail "(a) non-build-os .ts edit passes through" "expected no output, got: $OUTPUT_A"
fi

# --- Case (b): source edit on MAIN checkout of a .build/ repo → should ask --
echo "Case (b): source edit on MAIN checkout of a .build/ repo → should emit ask"

REPO_B="${TMPDIR_BASE}/repo-with-build"
mkdir -p "$REPO_B/src" "$REPO_B/.build"
git -C "$REPO_B" init -q
touch "$REPO_B/src/main.sh" "$REPO_B/.build/config"
git -C "$REPO_B" add . && git -C "$REPO_B" commit -q -m "init"

JSON_B="$(make_json "${REPO_B}/src/main.sh" "${REPO_B}/src")"
OUTPUT_B="$(run_hook "$JSON_B")"

if should_ask "$OUTPUT_B"; then
  pass "(b) main-checkout source edit emits ask"
else
  fail "(b) main-checkout source edit emits ask" "expected ask, got: '$OUTPUT_B'"
fi

# Verify the reason routes to /ship or /hotfix and does NOT say "just create a worktree"
REASON_B="$(echo "$OUTPUT_B" | python3 -c "
import json, sys
obj = json.loads(sys.stdin.read())
print(obj.get('hookSpecificOutput', {}).get('permissionDecisionReason', ''))
" 2>/dev/null)"

if echo "$REASON_B" | grep -qi "just create a worktree"; then
  fail "(b) reason must NOT say 'just create a worktree'" "reason contains forbidden phrase: $REASON_B"
else
  pass "(b) reason does not say 'just create a worktree'"
fi

if echo "$REASON_B" | grep -qi "/ship\|/hotfix"; then
  pass "(b) reason routes to /ship or /hotfix"
else
  fail "(b) reason routes to /ship or /hotfix" "reason does not mention /ship or /hotfix: $REASON_B"
fi

# --- Case (c): plans/ edit on main of a .build/ repo → should pass through --
echo "Case (c): plans/ edit on main of a .build/ repo → should pass through"

REPO_C="${REPO_B}"  # reuse the .build/ repo
mkdir -p "$REPO_C/plans"
touch "$REPO_C/plans/my-plan.md"
git -C "$REPO_C" add . && git -C "$REPO_C" commit -q -m "add plan"

JSON_C="$(make_json "${REPO_C}/plans/my-plan.md" "${REPO_C}/plans")"
OUTPUT_C="$(run_hook "$JSON_C")"

if should_pass "$OUTPUT_C"; then
  pass "(c) plans/ edit passes through"
else
  fail "(c) plans/ edit passes through" "expected no output, got: $OUTPUT_C"
fi

# Also test memory/ allowlist
JSON_C2="$(make_json "${REPO_C}/memory/entries/test.md" "${REPO_C}/memory/entries")"
# (file doesn't need to exist for hook logic, but dir should for git)
mkdir -p "$REPO_C/memory/entries"
touch "$REPO_C/memory/entries/test.md"
OUTPUT_C2="$(run_hook "$JSON_C2")"
if should_pass "$OUTPUT_C2"; then
  pass "(c) memory/ edit passes through"
else
  fail "(c) memory/ edit passes through" "expected no output, got: $OUTPUT_C2"
fi

# Test LEARNINGS.md anywhere
JSON_C3="$(make_json "${REPO_C}/src/LEARNINGS.md" "${REPO_C}/src")"
OUTPUT_C3="$(run_hook "$JSON_C3")"
if should_pass "$OUTPUT_C3"; then
  pass "(c) LEARNINGS.md anywhere passes through"
else
  fail "(c) LEARNINGS.md anywhere passes through" "expected no output, got: $OUTPUT_C3"
fi

# --- Case (d): edit inside a worktree path → should pass through -------------
echo "Case (d): edit inside a worktree → should pass through"

REPO_D="${TMPDIR_BASE}/repo-main-for-worktree"
WORKTREE_D="${TMPDIR_BASE}/wt-branch"
mkdir -p "$REPO_D/src" "$REPO_D/.build"
git -C "$REPO_D" init -q
touch "$REPO_D/src/app.sh" "$REPO_D/.build/config"
git -C "$REPO_D" add . && git -C "$REPO_D" commit -q -m "init"

# Create a real git worktree
git -C "$REPO_D" worktree add "$WORKTREE_D" -b wt-test-branch -q

# Verify the worktree git-dir contains /worktrees/
WT_GIT_DIR="$(git -C "$WORKTREE_D" rev-parse --git-dir 2>/dev/null)"
if [[ "$WT_GIT_DIR" == */worktrees/* ]]; then
  pass "(d) git-dir check — worktree path contains /worktrees/ as expected"
else
  # If relative, resolve
  WT_GIT_DIR_ABS="$(cd "$WORKTREE_D" && cd "$WT_GIT_DIR" 2>/dev/null && pwd -P)" || true
  if [[ "$WT_GIT_DIR_ABS" == */worktrees/* ]]; then
    pass "(d) git-dir check — resolved worktree path contains /worktrees/"
  else
    fail "(d) git-dir check" "expected /worktrees/ in git-dir, got: $WT_GIT_DIR (abs: $WT_GIT_DIR_ABS)"
  fi
fi

JSON_D="$(make_json "${WORKTREE_D}/src/app.sh" "${WORKTREE_D}/src")"
OUTPUT_D="$(run_hook "$JSON_D")"

if should_pass "$OUTPUT_D"; then
  pass "(d) worktree edit passes through"
else
  fail "(d) worktree edit passes through" "expected no output, got: $OUTPUT_D"
fi

# Clean up worktree
git -C "$REPO_D" worktree remove "$WORKTREE_D" 2>/dev/null || true

# --- Case (e): missing file_path / malformed JSON → exit 0 (fail-open) ------
echo "Case (e): missing file_path / malformed JSON → fail-open"

# (e1) Malformed JSON
EXIT_E1=0
OUTPUT_E1="$(echo 'not json at all {{{' | bash "$HOOK_SCRIPT" 2>/dev/null)" || EXIT_E1=$?
if [[ -z "$OUTPUT_E1" ]] && [[ $EXIT_E1 -eq 0 ]]; then
  pass "(e1) malformed JSON → fail-open (exit 0, no output)"
else
  fail "(e1) malformed JSON → fail-open" "exit=$EXIT_E1, output=$OUTPUT_E1"
fi

# (e2) Valid JSON but missing file_path
EXIT_E2=0
OUTPUT_E2="$(echo '{"tool_name":"Edit","tool_input":{},"cwd":"/tmp"}' | bash "$HOOK_SCRIPT" 2>/dev/null)" || EXIT_E2=$?
if [[ -z "$OUTPUT_E2" ]] && [[ $EXIT_E2 -eq 0 ]]; then
  pass "(e2) missing file_path → fail-open (exit 0, no output)"
else
  fail "(e2) missing file_path → fail-open" "exit=$EXIT_E2, output=$OUTPUT_E2"
fi

# (e3) Empty stdin
EXIT_E3=0
OUTPUT_E3="$(echo '' | bash "$HOOK_SCRIPT" 2>/dev/null)" || EXIT_E3=$?
if [[ -z "$OUTPUT_E3" ]] && [[ $EXIT_E3 -eq 0 ]]; then
  pass "(e3) empty stdin → fail-open (exit 0, no output)"
else
  fail "(e3) empty stdin → fail-open" "exit=$EXIT_E3, output=$OUTPUT_E3"
fi

# (e4) NotebookEdit with notebook_path
echo "Case (extra): NotebookEdit notebook_path in main .build/ repo → should ask"
JSON_NB="$(make_notebook_json "${REPO_B}/notebooks/analysis.ipynb" "${REPO_B}")"
mkdir -p "$REPO_B/notebooks"
OUTPUT_NB="$(run_hook "$JSON_NB")"
if should_ask "$OUTPUT_NB"; then
  pass "(extra) NotebookEdit on main with .build/ emits ask"
else
  fail "(extra) NotebookEdit on main with .build/ emits ask" "expected ask, got: '$OUTPUT_NB'"
fi

# --- Results -----------------------------------------------------------------
echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
  exit 1
else
  echo "All tests passed."
  echo ""
  exit 0
fi
