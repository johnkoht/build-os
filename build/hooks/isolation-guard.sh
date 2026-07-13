#!/usr/bin/env bash
# isolation-guard.sh — PreToolUse hook for build-os-managed projects
#
# Catches ad-hoc source edits on the MAIN checkout of build-os-managed projects
# (.build/ marker present) and surfaces an `ask` prompt routing to /ship or /hotfix.
#
# FAIL-OPEN: exit 0 on ANY ambiguity or error. This hook must NEVER block editing.
#
# Wired via settings.json (task-8) to match: Edit|Write|MultiEdit|NotebookEdit
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

# --- Step 3: Parse file_path from stdin (fail-open on parse error) -----------
# Edit/Write use tool_input.file_path; NotebookEdit uses tool_input.notebook_path
FILE_PATH=""
CWD=""

FILE_PATH="$("$JQ" -r '
  (.tool_input.file_path // .tool_input.notebook_path // "") | select(. != null)
' <<< "$STDIN_JSON" 2>/dev/null)" || { exit 0; }

CWD="$("$JQ" -r '.cwd // ""' <<< "$STDIN_JSON" 2>/dev/null)" || { exit 0; }

# If file_path is empty, fail-open
if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# --- Step 4: Resolve relative file_path against cwd (review note 5) ----------
if [[ "$FILE_PATH" != /* ]]; then
  if [[ -z "$CWD" ]]; then
    exit 0
  fi
  FILE_PATH="${CWD%/}/${FILE_PATH}"
fi

# --- Step 5: Determine the file's directory ----------------------------------
FILE_DIR="$(dirname "$FILE_PATH")"

# --- Step 6: Check if the file's directory is inside a git repo (fail-open) --
GIT_DIR="$(git -C "$FILE_DIR" rev-parse --git-dir 2>/dev/null)" || { exit 0; }
if [[ -z "$GIT_DIR" ]]; then
  exit 0
fi

# --- Step 7: Get the git repo toplevel (fail-open) ---------------------------
GIT_TOPLEVEL="$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null)" || { exit 0; }
if [[ -z "$GIT_TOPLEVEL" ]]; then
  exit 0
fi

# --- Step 8: Fast early-exit — check for .build/ marker BEFORE expensive work
if [[ ! -d "${GIT_TOPLEVEL}/.build" ]]; then
  # Not a build-os-managed project — pass through immediately
  exit 0
fi

# --- Step 9: Check if we are in a WORKTREE (fail-open on ambiguity) ----------
# In a linked worktree, --git-dir returns an absolute path containing /worktrees/
# In the main checkout, it returns ".git" or an absolute path ending in /.git

# Resolve GIT_DIR to absolute if relative (it may be ".git" in main checkout)
if [[ "$GIT_DIR" != /* ]]; then
  GIT_DIR_ABS="$(cd "$FILE_DIR" && cd "$GIT_DIR" && pwd -P 2>/dev/null)" || { exit 0; }
else
  GIT_DIR_ABS="$GIT_DIR"
fi

if [[ "$GIT_DIR_ABS" == */worktrees/* ]]; then
  # We are in a linked worktree — pass through
  exit 0
fi

# --- Step 10: Compute repo-relative path for allowlist matching --------------
# On macOS, FILE_PATH may be a non-canonical symlink path (e.g. /var/folders/...)
# while GIT_TOPLEVEL from git is canonical (e.g. /private/var/folders/...).
# Canonicalize FILE_PATH by resolving the directory portion (the file need not exist).
FILE_PATH_DIR_CANONICAL="$(cd "$FILE_DIR" 2>/dev/null && pwd -P 2>/dev/null)" || { exit 0; }
FILE_PATH_CANONICAL="${FILE_PATH_DIR_CANONICAL}/$(basename "$FILE_PATH")"

# Strip the git toplevel prefix to get the repo-relative path
REPO_REL_PATH="${FILE_PATH_CANONICAL#${GIT_TOPLEVEL}/}"

# If stripping didn't work (file is outside toplevel somehow), fail-open
if [[ "$REPO_REL_PATH" == "$FILE_PATH_CANONICAL" ]]; then
  exit 0
fi

# --- Step 11: Allowlist check (directory prefix and special filenames) --------
# Allowlisted paths — never block writes to these:
#   plans/       — plan artifacts written by /ship and /plan
#   memory/      — memory entries written by post-mortem
#   .build/      — build-os config and metadata
#   LEARNINGS.md — any-dir LEARNINGS.md
#
# Note: NEVER allowlist by file extension (build-os source is .md)
BASENAME="$(basename "$REPO_REL_PATH")"

if [[ "$REPO_REL_PATH" == plans/* ]] || \
   [[ "$REPO_REL_PATH" == memory/* ]] || \
   [[ "$REPO_REL_PATH" == .build/* ]] || \
   [[ "$BASENAME" == "LEARNINGS.md" ]]; then
  exit 0
fi

# --- Step 12: Emit `ask` prompt to route the agent --------------------------
# We are in the MAIN checkout of a build-os-managed project and the file is not
# allowlisted. Surface an ask prompt to route to /ship or /hotfix.

REASON="You are editing source on the MAIN checkout of a build-os-managed project. \
Direct edits to main bypass review and the PRD workflow. \
Please route through the appropriate command instead: \
for non-trivial work (3+ steps, new files, schema changes, or features) → use \`/ship\` or \`/ship lite\`; \
for a focused bug fix → use \`/hotfix\`. \
Do not manually create a worktree — that skips the required /plan → /approve gate and the reviewer subagent."

printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"ask\",\"permissionDecisionReason\":\"${REASON}\"}}"
