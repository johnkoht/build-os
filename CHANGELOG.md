# Changelog

Notable changes to build-os. Newest first.

## 2026-07-12 — protocol-guardrails

Make routing through the build protocol structurally hard to skip (hooks + skills, not just docs).

### Added
- **`/plan`** skill — plan-mode replacement: explores read-only, discusses, saves a draft to
  `plans/{slug}/plan.md`, ends with a keep-editing / `/approve` gate. Never auto-executes.
- **`/approve`** skill — user-only gate (`disable-model-invocation`) that marks a plan approved and
  prints the next-step menu.
- **`/ship lite`** — lighter `/ship` mode for 3-5 step, low-risk plans (skips pre-mortem + review).
- **Guardrail hooks** (`build/hooks/`): `isolation-guard` (PreToolUse `ask` on source edits to a
  `.build/` project's main checkout → routes to `/ship`/`/hotfix`) and `plan-redirect` (native plan
  mode → `/plan`). Fail-open, `.build/`-scoped, with test harnesses.
- `CHANGELOG.md` (this file).

### Changed
- **Worktrees** standardized to `.claude/worktrees/` via native `EnterWorktree`/`ExitWorktree`
  (replaces hand-rolled `git worktree add`); `worktree.baseRef: head`.
- **`/hotfix`** — reviewer subagent is now mandatory; explicit test gate before review.
- **Docs steer** — `AGENTS.md` `isolation_gate` (guards editing source on main, not branch-switching)
  and `small_tasks` (explicit boundary); `CLAUDE.md` `plan_first`/`zero_context_switching` point to
  `/plan` and `/hotfix`. Fix requests route to `/hotfix`, never ad-hoc.
- **`install.sh`** — now merges the guardrail hooks into `~/.claude/settings.json` (idempotent, backs
  up, validates) and sets `worktree.baseRef`. `new-project` and `/build-os-retrofit` opt projects in
  (create `.build/`, gitignore `.claude/worktrees/`, verify hooks).

### Notes
- build-os itself is intentionally not given a `.build/` marker (so the guards don't fire during
  framework development).
- Deferred ideas tracked in `plans/protocol-guardrails/backlog.md`.
- The `plan-redirect` hook's live firing depends on `EnterPlanMode` being hook-matchable in your
  Claude Code version — verify once per install (see `build/hooks/README.md`); the `CLAUDE.md`
  `/plan` callout is the fallback.
