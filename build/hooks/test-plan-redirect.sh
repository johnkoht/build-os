#!/usr/bin/env bash
# test-plan-redirect.sh — Unit tests for plan-redirect.sh
#
# Uses synthetic stdin payloads and temp git repos to verify the hook's logic.
# All tests must pass (exit 0). Failing tests print an error and exit 1.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOK="${SCRIPT_DIR}/plan-redirect.sh"

# Locate jq
JQ=""
for candidate in jq /opt/homebrew/bin/jq /usr/local/bin/jq /usr/bin/jq; do
  if command -v "$candidate" &>/dev/null 2>&1; then
    JQ="$candidate"
    break
  fi
done

if [[ -z "$JQ" ]]; then
  echo "SKIP: jq not found — cannot run tests"
  exit 0
fi

# ---- Helpers ----------------------------------------------------------------

PASS=0
FAIL=0
TESTS_RUN=0

pass() {
  echo "  PASS: $1"
  PASS=$((PASS + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

fail() {
  echo "  FAIL: $1"
  echo "        $2"
  FAIL=$((FAIL + 1))
  TESTS_RUN=$((TESTS_RUN + 1))
}

# Run hook with given stdin; capture stdout and exit code.
# Usage: run_hook <stdin_json>
# Sets: HOOK_EXIT HOOK_OUTPUT
run_hook() {
  local input="$1"
  HOOK_OUTPUT="$(echo "$input" | bash "$HOOK" 2>/dev/null)" && HOOK_EXIT=0 || HOOK_EXIT=$?
}

# Assert that the hook exits 0 and produces no output (pass-through / fail-open).
assert_passthrough() {
  local name="$1"
  local input="$2"
  run_hook "$input"
  if [[ "$HOOK_EXIT" -ne 0 ]]; then
    fail "$name" "Expected exit 0, got exit $HOOK_EXIT"
  elif [[ -n "$HOOK_OUTPUT" ]]; then
    fail "$name" "Expected no output, got: $HOOK_OUTPUT"
  else
    pass "$name"
  fi
}

# Assert that the hook exits 0, produces valid JSON, and the JSON contains
# permissionDecision=="deny" and permissionDecisionReason mentions "/plan".
assert_deny() {
  local name="$1"
  local input="$2"
  run_hook "$input"
  if [[ "$HOOK_EXIT" -ne 0 ]]; then
    fail "$name" "Expected exit 0, got exit $HOOK_EXIT"
    return
  fi
  if [[ -z "$HOOK_OUTPUT" ]]; then
    fail "$name" "Expected JSON output, got empty"
    return
  fi
  # Validate JSON
  if ! echo "$HOOK_OUTPUT" | "$JQ" . >/dev/null 2>&1; then
    fail "$name" "Output is not valid JSON: $HOOK_OUTPUT"
    return
  fi
  # Check permissionDecision == "deny"
  local decision
  decision="$(echo "$HOOK_OUTPUT" | "$JQ" -r '.hookSpecificOutput.permissionDecision' 2>/dev/null)"
  if [[ "$decision" != "deny" ]]; then
    fail "$name" "Expected permissionDecision=deny, got: $decision"
    return
  fi
  # Check reason mentions /plan
  local reason
  reason="$(echo "$HOOK_OUTPUT" | "$JQ" -r '.hookSpecificOutput.permissionDecisionReason' 2>/dev/null)"
  if [[ "$reason" != */plan* ]]; then
    fail "$name" "Expected reason to mention /plan, got: $reason"
    return
  fi
  pass "$name"
}

# ---- Set up temporary repos --------------------------------------------------

TMPDIR_BASE="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# Repo A: has .build/ (build-os-managed project)
REPO_BUILD="${TMPDIR_BASE}/repo-with-build"
mkdir -p "${REPO_BUILD}/.build"
git -C "$REPO_BUILD" init -q
git -C "$REPO_BUILD" config user.email "test@test.com"
git -C "$REPO_BUILD" config user.name "Test"

# Repo B: no .build/ (regular git repo, not build-os-managed)
REPO_PLAIN="${TMPDIR_BASE}/repo-plain"
mkdir -p "$REPO_PLAIN"
git -C "$REPO_PLAIN" init -q
git -C "$REPO_PLAIN" config user.email "test@test.com"
git -C "$REPO_PLAIN" config user.name "Test"

# Dir C: not in any git repo
DIR_NOGIT="${TMPDIR_BASE}/no-git"
mkdir -p "$DIR_NOGIT"

echo "Running plan-redirect.sh tests..."
echo ""

# ---- Test 1: EnterPlanMode in a .build/ repo → deny + /plan mention ---------
echo "Test 1: EnterPlanMode inside a .build/ repo → deny"
assert_deny \
  "EnterPlanMode in .build repo emits deny with /plan in reason" \
  "{\"tool_name\":\"EnterPlanMode\",\"tool_input\":{},\"cwd\":\"${REPO_BUILD}\"}"

# ---- Test 2: EnterPlanMode in a non-.build/ git repo → pass-through ---------
echo "Test 2: EnterPlanMode inside a non-.build git repo → pass-through"
assert_passthrough \
  "EnterPlanMode in plain git repo passes through" \
  "{\"tool_name\":\"EnterPlanMode\",\"tool_input\":{},\"cwd\":\"${REPO_PLAIN}\"}"

# ---- Test 3: EnterPlanMode with cwd outside any git repo → fail-open --------
echo "Test 3: EnterPlanMode with cwd not in any git repo → fail-open"
assert_passthrough \
  "EnterPlanMode outside git repo fails open" \
  "{\"tool_name\":\"EnterPlanMode\",\"tool_input\":{},\"cwd\":\"${DIR_NOGIT}\"}"

# ---- Test 4: Malformed / empty stdin → fail-open ----------------------------
echo "Test 4: Malformed stdin → fail-open"
run_hook "not-json-at-all"
if [[ "$HOOK_EXIT" -ne 0 ]]; then
  fail "Malformed stdin exits non-zero" "Expected exit 0, got $HOOK_EXIT"
else
  pass "Malformed stdin fails open (exit 0)"
fi

echo "Test 4b: Empty stdin → fail-open"
run_hook ""
if [[ "$HOOK_EXIT" -ne 0 ]]; then
  fail "Empty stdin exits non-zero" "Expected exit 0, got $HOOK_EXIT"
else
  pass "Empty stdin fails open (exit 0)"
fi

# ---- Test 5: Non-EnterPlanMode tool in .build/ repo → pass-through ----------
echo "Test 5: Different tool_name in .build/ repo → pass-through (defensive guard)"
assert_passthrough \
  "Non-EnterPlanMode tool passes through even in .build repo" \
  "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"foo.ts\"},\"cwd\":\"${REPO_BUILD}\"}"

# ---- Test 6: EnterPlanMode with missing cwd → fail-open ---------------------
echo "Test 6: EnterPlanMode with missing cwd → fail-open"
assert_passthrough \
  "EnterPlanMode with missing cwd fails open" \
  "{\"tool_name\":\"EnterPlanMode\",\"tool_input\":{}}"

# ---- Test 7: EnterPlanMode output is valid JSON (belt-and-suspenders) -------
echo "Test 7: Deny output is valid JSON parseable by jq"
run_hook "{\"tool_name\":\"EnterPlanMode\",\"tool_input\":{},\"cwd\":\"${REPO_BUILD}\"}"
if [[ -n "$HOOK_OUTPUT" ]]; then
  if echo "$HOOK_OUTPUT" | "$JQ" . >/dev/null 2>&1; then
    pass "Deny output is valid JSON"
  else
    fail "Deny output is not valid JSON" "$HOOK_OUTPUT"
  fi
fi

# ---- Summary -----------------------------------------------------------------
echo ""
echo "Results: ${PASS}/${TESTS_RUN} passed, ${FAIL} failed."
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi

exit 0
