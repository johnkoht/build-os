---
title: Build OS Protocol Guardrails
slug: protocol-guardrails
status: approved
created: 2026-07-12
has_pre_mortem: true
has_review: true
has_prd: true
---

# Build OS Protocol Guardrails

## Problem

Agents skip the `/ship` / `/build` protocols. After a plan is shaped and approved in
conversation, the agent frequently begins implementing directly — editing source on the
main branch — instead of routing through the workflow (plan → approve → ship → worktree →
build → wrap → merge). Three concrete leaks:

1. **Ad-hoc builds on main** after plan approval.
2. **Native plan mode auto-jumps to execution** — its exit prompt hands off to implementation,
   and it can't be reshaped or hooked to insert a manual approval gate.
3. **Ad-hoc fixes during/after execution** — fix requests get hand-rolled patches instead of a
   structured fix → review → test loop.

Root cause (validated by multi-agent analysis + the correction log in
`build/memory/collaboration.md`): **nothing forces the protocol.** The only hard gate (the
worktree guard) lives *inside* `/ship` — behind the door the agent isn't opening. Prose fixes
have failed 4+ times ("having context ≠ using it"). Therefore the fix must be **harness-enforced
mechanisms (hooks + skills) + minimal corrective doc steering**, not resident instruction bloat.

## Goal

Make the routed flow the path of least resistance and structurally hard to skip:

**`/plan` → (iterate) → `/approve` → `/ship` | `/ship lite` | `/build`**, with an edit-guard
hook as backstop, `/hotfix` for fixes, and all worktrees standardized to `.claude/worktrees/`.

## Design decisions (locked)

- Enforcement = **hooks + skills**, not walls of text. Doc changes are corrective/minimal.
- **Edit-guard**: PreToolUse on `Edit|Write|MultiEdit|NotebookEdit`, `ask` mode, scoped to repos
  with a `.build/` marker, allowlisted by **directory** (`plans/`, `memory/`, `.build/`,
  `LEARNINGS.md`) — never by extension (build-os source is markdown). Fail-open, fast.
- **Plan-mode redirect**: PreToolUse on `EnterPlanMode`, `deny` + redirect to `/plan`,
  `.build/`-scoped. (Empirically verify `EnterPlanMode` is hookable during the build; if not,
  fall back to a CLAUDE.md callout and accept the residual gap.)
- **`/plan`** is our own skill (not native plan mode): normal permission mode, so it can save
  `plan.md` live without the read-only/exit problem. Model- and user-invocable.
- **`/approve`** is user-only (`disable-model-invocation: true`).
- **Worktrees** standardize on native `EnterWorktree` → `.claude/worktrees/`, `worktree.baseRef: head`.
- **Fixes** route to a strengthened `/hotfix` (mandatory reviewer); no new `/fix` skill.
- One comprehensive build.

## Tasks

1. **Edit-guard hook** — `build/hooks/isolation-guard.sh` + `settings.json` wiring. PreToolUse
   `Edit|Write|MultiEdit|NotebookEdit`; self-gate to main-checkout of `.build/` repos; dir-allowlist;
   `permissionDecision: ask` with reason routing to `/ship` | `/hotfix`. Fail-open, fast.
   Message must NOT say "just make a worktree" (that teaches the false-compliance bypass).
2. **Plan-mode redirect hook** — PreToolUse `EnterPlanMode` → `deny` + redirect to `/plan`,
   `.build/`-scoped. Verify hookability empirically; CLAUDE.md-callout fallback if it doesn't fire.
3. **`/plan` skill** (new, model+user invocable) — explore read-only, discuss trade-offs first,
   write `plans/{slug}/plan.md` (`status: draft`), end each round with "keep editing / `/approve`".
   Never auto-executes. Ends the plan with the pre-commitment line (Task 9).
4. **`/approve` skill** (new, `disable-model-invocation: true`) — flip plan `status: approved`,
   save conversation plan if needed, print next step (`/ship` | `/ship lite` | `/build`).
5. **Doc steer** (minimal, corrective) — `plan_first` → point to `/plan`, steer away from native
   plan mode; fix `isolation_gate` (guards *code-writing on main*, not branch-switching);
   add `small_tasks` boundary (≤2 files, no new files/deps, no written plan → else route);
   soften `zero_context_switching` (bugs only). Both `CLAUDE.md` + `build/AGENTS.md`. Add a
   short CLAUDE.md callout to use `/plan`.
6. **`/ship lite`** — new mode/arg in `ship.md`: skip pre-mortem (1.2) + cross-model review (1.3),
   condensed inline PRD, keep worktree + build + wrap + merge. Update "When to Use".
7. **Strengthen `/hotfix` + routing** — make the reviewer subagent **mandatory** (not self-review
   fallback); ensure tests run; add "fix requests → `/hotfix`, never ad-hoc" steer in `build.md`
   + `ship.md`.
8. **Modernize worktree** — adopt native `EnterWorktree` everywhere (replace hand-rolled
   `git worktree add`); worktrees in `.claude/worktrees/`; set `worktree.baseRef: head`;
   `ExitWorktree` for cleanup (ship.md Phase 6); ensure `.claude/worktrees/` gitignored.
9. **Plan pre-commitment line** — `/plan` and the plan template end plans with the literal
   `On approval → /approve → /ship {slug}`.
10. **install + retrofit wiring** — `install.sh`: idempotent `settings.json` hooks merge +
    `build/hooks/` reachable via the existing `build/` symlink; `new-project` + `build-os-retrofit`
    ensure `.build/` exists + hooks installed + `.claude/worktrees/` gitignored.
11. **Backlog + wrap** — create `plans/protocol-guardrails/backlog.md` (deferred items below);
    memory entry; LEARNINGS.md.

## Deferred to backlog (explicitly NOT in this build)

- SessionStart resident protocol injection (rejected — resident bloat).
- UserPromptSubmit approval-language nudge.
- `.build/.planning` read-only sentinel (recovers plan mode's hard read-only inside `/plan`).
- Statusline `⚠ MAIN` vs `⎇ worktree` indicator.
- Escalate edit-guard from `ask` → `deny`.
- Separate `/fix` mini-build (using strengthened `/hotfix` instead).

## Risks

- **A.** `.build/`-scoping means existing projects are unprotected until retrofitted — Task 10 handles it.
- **B.** Global hook runs on every edit — must be fast and fail-open (exit 0 on any ambiguity).
- **C.** `EnterPlanMode` hookability is unverified (harness-facts agent gave contradictory info) —
  empirical test in the build; callout fallback.
- **D.** Steering away from native plan mode loses hard total read-only + priming + Ultraplan —
  mitigated by the edit-guard; `.planning` sentinel in backlog if the priming loss bites.

## On approval → /approve → /ship protocol-guardrails
