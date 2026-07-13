# Pre-Mortem: protocol-guardrails

Date: 2026-07-12

Imagine it's shipped and something went wrong. What failed?

## Risks (severity → mitigation, to embed in task prompts)

### R1. Global edit-guard hook breaks editing everywhere — **CRITICAL (mitigated)**
The edit-guard runs on **every** `Edit`/`Write` across **all** repos on the machine, not just
build-os projects. If it is slow, errors non-open, or has a logic bug, it can block or delay all
file editing in every Claude Code session.
- **Mitigation (mandatory in task prompt):** fail-open — `exit 0` on ANY ambiguity/error (no git,
  no file_path, parse failure, unknown state). Early-exit fast for the common case (not a git repo,
  or no `.build/` marker) BEFORE any expensive work. Depend only on tools confirmed present.
  Test explicitly: edit a file in a NON-build-os repo → must pass through instantly.

### R2. Broken write to the LIVE global `~/.claude/settings.json` — **CRITICAL (mitigated)**
`install.sh` merges the hooks block into `~/.claude/settings.json`, which is **outside the worktree**
(global, shared with the running session). A malformed merge could corrupt settings and break
Claude Code for the current + future sessions.
- **Mitigation (mandatory):** do NOT run the live merge during the build. Develop + unit-test the
  merge against a COPY/temp file. Validate JSON parses after merge. Idempotent (re-run = no-op).
  Back up settings.json before first real install. The actual live install happens only after merge,
  deliberately, by John.

### R3. JSON-parsing dependency in the hook — **HIGH**
The hook reads tool-call JSON on stdin. `jq` may not be installed on macOS by default; `python3`
usually is (with Xcode CLT). A missing interpreter = hook errors.
- **Mitigation:** verify which is present on this machine during the build; prefer the confirmed one,
  and fail-open if absent. Keep parsing to a single field (`tool_input.file_path`) so a minimal
  extraction works.

### R4. `EnterPlanMode` not actually hookable — **MEDIUM (fallback exists)**
The harness-facts agent claimed plan-mode tools aren't hookable, contradicting their presence as
live tools. If the PreToolUse matcher never fires on `EnterPlanMode`, the redirect silently no-ops.
- **Mitigation:** empirical test FIRST (install matcher, trigger plan mode, confirm it fires). If it
  doesn't, fall back to the CLAUDE.md `/plan` callout and record the residual gap. Not a blocker.

### R5. `permissionDecision: ask` stalls a non-interactive session — **LOW**
`ask` prompts a human. During autonomous `/ship`, the build runs in a worktree, and the guard only
fires on the MAIN checkout — so autonomous builds don't trip it. Residual: a human running an
autonomous agent directly on main in a `.build/` repo.
- **Mitigation:** accepted; documented. The guard is designed for the interactive main-repo moment.

### R6. Allowlist too broad (no-op) or too narrow (blocks legit artifact writes) — **MEDIUM**
`/ship` writes `plans/`, `memory/`, PRD commits on main by design. Wrong allowlist either lets source
edits through or blocks the workflow's own writes.
- **Mitigation:** allowlist exact dir prefixes (`plans/`, `memory/`, `.build/`, `LEARNINGS.md`);
  never by extension (build-os source is `.md`). Test both: source edit on main → `ask`; `plans/`
  edit on main → pass.

### R7. Worktree base ref wrong → worktree missing the just-made PRD — **MEDIUM**
`/ship` commits plan/PRD artifacts on main, THEN creates the worktree. With `worktree.baseRef: fresh`
the worktree branches from `origin/main` and won't contain the local artifact commits.
- **Mitigation:** set `worktree.baseRef: head`. Verify the worktree contains `plans/{slug}/prd.md`.

### R8. Scope — 11 interdependent tasks in one build — **MEDIUM**
Large surface; risk of half-integrated pieces.
- **Mitigation:** clear task boundaries, dependency ordering (hooks + skills before wiring),
  reviewer per task, holistic review at the end.

## Gate decision

No **unmitigated** CRITICAL risk. R1 and R2 are CRITICAL but have concrete, mandatory mitigations
that will be embedded in the relevant task prompts. **Proceed.**
