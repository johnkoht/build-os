# Protocol Guardrails — Learnings

Date: 2026-07-12
Slug: protocol-guardrails
Type: project

## Metrics

- 9 tasks, 9 complete, 0 rework rounds (all passed reviewer/holistic on first pass).
- 3 hooks/test harnesses: isolation-guard 13/13, plan-redirect 8/8, settings-merge 27/27 (48 assertions).
- Holistic review: READY, 0 must-fix blockers, 3 nice-to-haves (2 applied as polish, 1 backlogged).
- Diagnosis phase: 3 cross-model subagents (Sonnet/Opus/Fable) + 1 harness-facts (claude-code-guide) + 1 cross-model plan review.

## What this shipped

Harness-enforced guardrails so agents can't skip the /ship protocol:
- **Two PreToolUse hooks** (`build/hooks/`): `isolation-guard.sh` (ask-mode edit-guard, `.build/`-scoped,
  dir-allowlisted, fail-open) + `plan-redirect.sh` (deny native plan mode → /plan).
- **`/plan`** (plan-mode replacement — saves draft live, gates with /approve) + **`/approve`**
  (user-only via `disable-model-invocation: true`).
- **`/ship lite`** middle tier; native `EnterWorktree`/`ExitWorktree` (worktrees → `.claude/worktrees/`).
- Strengthened **`/hotfix`** (mandatory reviewer) + fix-routing steer; minimal doc corrections.

## Key learnings

- **Prose fixes for tool-use behavior have a failure track record — escalate to hooks.** The
  correction log showed 4+ dated "use the proper skill / don't hand-roll" corrections that didn't
  stick ("having context ≠ using it"). The durable fix is harness-executed (hooks + user-only skills),
  not another instruction. This is the core thesis and it held up in review.
- **The decision point is plan-APPROVAL, not the first edit.** Native plan mode's exit auto-jumps to
  execution and can't be reshaped/suppressed. Solution: replace it with a `/plan` skill (normal
  permission mode → can save the plan live, which native plan mode structurally cannot) + a user-only
  `/approve` gate. Trade-off: lose hard read-only + priming; mitigated by the edit-guard.
- **`~/.claude/commands` is MATERIALIZED (real dir), not a symlink, after `build-config sync`.** New/
  modified skills are DARK CODE until `build-config sync --global` re-materializes them. `~/.claude/build`
  IS still a symlink → AGENTS.md + hook scripts go live on merge without sync. This gotcha nearly made
  the whole feature inert; the dark-code audit caught and wired it.
- **Standardize worktrees on native `EnterWorktree`** → always `.claude/worktrees/`, killing the
  "sometimes a sibling dir outside the repo" inconsistency. Needs `worktree.baseRef: head` so the
  worktree includes plan/PRD artifacts committed on main pre-worktree.
- **Global hooks must be fail-open + self-gating.** They run on every edit in every repo; exit 0 on any
  ambiguity, early-exit fast for non-`.build/` repos. Allowlist by DIRECTORY, never extension
  (build-os's own source is markdown — an extension allowlist would be a no-op here).
- **macOS symlink canonicalization** bites hook path math: `mktemp -d` returns `/var/...` but
  `git rev-parse --show-toplevel` returns `/private/var/...`; canonicalize with `pwd -P` before
  prefix-stripping. (See `build/hooks/LEARNINGS.md`.)

## Recommendations

- **Continue:** multi-model diagnosis before building a systems change (Sonnet/Opus/Fable gave genuinely
  different angles; Fable surfaced the corrections-graveyard evidence that reframed the whole approach).
- **Continue:** dark-code audit as a gate — it caught the materialized-commands trap.
- **Start:** for framework changes, verify harness capabilities (hook API, tool schemas) with
  claude-code-guide BEFORE designing, not after.

## Follow-ups (in backlog.md)

`.build/.planning` read-only sentinel; live-verify EnterPlanMode hookability (manual, post-install);
SessionStart/UserPromptSubmit nudges; edit-guard ask→deny; statusline indicator; retrofit build-os itself.

## Post-merge steps (REQUIRED for the feature to take effect)

1. `./install.sh` — merges hooks into `~/.claude/settings.json` (idempotent, backs up, validates).
2. `build-config sync --global` — makes `/plan` + `/approve` invocable (materialized commands dir).
3. Dark-code check: type `/plan` → resolves as a command.
4. Manual EnterPlanMode check per `build/hooks/README.md` (confirms plan-redirect fires; else rely on
   the CLAUDE.md /plan callout).
