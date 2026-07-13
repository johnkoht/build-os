#!/usr/bin/env bash
# plan-redirect.sh — PreToolUse hook for build-os-managed projects
#
# Intercepts EnterPlanMode in build-os-managed projects (.build/ marker present)
# and denies it, redirecting the agent to /plan instead.
#
# Native plan mode auto-jumps to execution and bypasses the /plan → /approve gate.
# In build-os-managed projects, /plan is the correct entry point.
#
# FAIL-OPEN: exit 0 on ANY ambiguity or error. This hook must NEVER block operation.
#
# Wired via settings.json (task-8) to match: EnterPlanMode
# Receives tool-call JSON on stdin with fields: tool_name, tool_input, cwd

set -euo pipefail

# --- Step 1: Locate jq (fail-open if absent) ---------------------------------
JQ=""
for candidate in jq /opt/homebrew/bin/jq /usr/local/bin/jq /usr/bin/jq; do
  if command -v "$candidate" &>/dev/null 2>&1; then
    JQ="$candidate"
    break
  fi
done

if [[ -z "$JQ" ]]; then
  # jq not found — fail-open
  exit 0
fi

# --- Step 2: Read stdin into a variable (fail-open on empty) -----------------
STDIN_JSON="$(cat)"
if [[ -z "$STDIN_JSON" ]]; then
  exit 0
fi

# --- Step 3: Parse tool_name and cwd from stdin (fail-open on parse error) ---
TOOL_NAME=""
CWD=""

TOOL_NAME="$("$JQ" -r '.tool_name // ""' <<< "$STDIN_JSON" 2>/dev/null)" || { exit 0; }
CWD="$("$JQ" -r '.cwd // ""' <<< "$STDIN_JSON" 2>/dev/null)" || { exit 0; }

# Defensive guard: only act on EnterPlanMode (the settings.json matcher should
# already filter, but guard here too in case this script is invoked otherwise).
if [[ "$TOOL_NAME" != "EnterPlanMode" ]]; then
  exit 0
fi

# --- Step 4: Resolve cwd to a real directory (fail-open if missing) ----------
# EnterPlanMode has no file_path; we derive the repo from cwd instead.
if [[ -z "$CWD" ]]; then
  # No cwd in payload — fail-open
  exit 0
fi

if [[ ! -d "$CWD" ]]; then
  # cwd does not exist on disk — fail-open
  exit 0
fi

# --- Step 5: Check if cwd is inside a git repo (fail-open) ------------------
GIT_DIR="$(git -C "$CWD" rev-parse --git-dir 2>/dev/null)" || { exit 0; }
if [[ -z "$GIT_DIR" ]]; then
  exit 0
fi

# --- Step 6: Get the git repo toplevel (fail-open) ---------------------------
GIT_TOPLEVEL="$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)" || { exit 0; }
if [[ -z "$GIT_TOPLEVEL" ]]; then
  exit 0
fi

# --- Step 7: Fast early-exit — check for .build/ marker ---------------------
if [[ ! -d "${GIT_TOPLEVEL}/.build" ]]; then
  # Not a build-os-managed project — leave native plan mode untouched
  exit 0
fi

# --- Step 8: Emit `deny` to redirect to /plan --------------------------------
# We are in a build-os-managed project. Native plan mode is off here because
# it auto-jumps to execution and bypasses the /plan → /approve gate.

REASON="Native plan mode is disabled in build-os-managed projects. \
Please use \`/plan\` instead: it saves the plan to plans/ in the repo, \
ends with a keep-editing/approve prompt, and requires explicit \`/approve\` \
before any execution begins. \
Native plan mode auto-jumps to execution and cannot host the /approve gate. \
Workflow: \`/plan\` → review → \`/approve\` → \`/ship\`."

printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"${REASON}\"}}"
