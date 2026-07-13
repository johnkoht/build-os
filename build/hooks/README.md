# build/hooks — PreToolUse Hooks

These hooks fire via the Claude Code `PreToolUse` event (wired in `~/.claude/settings.json` by `install.sh`, task-8). Both hooks are **fail-open**: any ambiguity, parse error, or missing dependency results in `exit 0` and the tool call proceeds normally.

---

## isolation-guard.sh

**Purpose:** Catches ad-hoc source edits on the MAIN checkout of build-os-managed projects and surfaces an `ask` prompt routing to `/ship` or `/hotfix`.

**Matcher (settings.json):** `Edit | Write | MultiEdit | NotebookEdit`

**Logic:**
1. Reads `tool_input.file_path` (or `notebook_path`) from stdin JSON.
2. Resolves relative paths against `cwd`.
3. Finds the git toplevel from the file's directory.
4. **Early-exit** if no `.build/` dir at toplevel (not a build-os-managed project).
5. Exits if inside a linked worktree (`--git-dir` contains `/worktrees/`).
6. Checks repo-relative path against the allowlist: `plans/`, `memory/`, `.build/`, `LEARNINGS.md`.
7. On block: emits `permissionDecision: "ask"` with a reason routing to `/ship` (features) or `/hotfix` (bugs).

**Test harness:** `test-isolation-guard.sh`

---

## plan-redirect.sh

**Purpose:** Intercepts `EnterPlanMode` in build-os-managed projects and denies it, redirecting the agent to `/plan` instead. Native plan mode auto-jumps to execution and cannot host the `/plan → /approve` gate.

**Matcher (settings.json):** `EnterPlanMode`

**Logic:**
1. Reads `tool_name` and `cwd` from stdin JSON.
2. Defensive guard: exits 0 if `tool_name != "EnterPlanMode"`.
3. Resolves `cwd` (EnterPlanMode has no `file_path`).
4. Finds the git toplevel from `cwd`.
5. **Early-exit** if no `.build/` dir at toplevel (not a build-os-managed project — native plan mode is left untouched in non-build repos).
6. On redirect: emits `permissionDecision: "deny"` with a reason explaining `/plan` is the correct entry point, saves to `plans/`, and gates with `/approve`.

**Test harness:** `test-plan-redirect.sh`

### Manual Verification Procedure

After `install.sh` has merged the hooks into `~/.claude/settings.json` (task-8):

1. Open a project that has a `.build/` directory at its git root.
2. In a Claude Code session inside that project, ask the agent to do something that would trigger plan mode — for example: *"Plan how to add a new feature X"* or use the keyboard shortcut to enter plan mode.
3. **Expected (hook working):** The agent is redirected and responds that native plan mode is disabled here, instructing you to use `/plan` instead.
4. **If NOT redirected** (agent enters native plan mode): `EnterPlanMode` is not matchable as a `PreToolUse` event in this version of Claude Code. In that case, rely on the `CLAUDE.md` `/plan` callout (task-7) as the fallback. Note the Claude Code version in the build-log.

**Note on live verifiability:** Empirical verification that `EnterPlanMode` fires a `PreToolUse` hook cannot be automated from a subagent (mid-session settings edits may not reload; subagents cannot drive interactive plan mode). The hook is built **defensively** — it is harmless and fail-open if the matcher never fires, and helpful if it does. Treat live firing as unverified until the manual check above is completed.
