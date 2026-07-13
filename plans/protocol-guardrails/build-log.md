# Build Log: protocol-guardrails

Started: 2026-07-12

## Phases

- [x] Phase 0: Build log initialized — 2026-07-12
- [ ] Phase 1: Pre-Build (plan saved, pre-mortem, review)
  - [x] 1.1 Save plan → plans/protocol-guardrails/plan.md (status: approved)
  - [ ] 1.2 Pre-Mortem
  - [ ] 1.3 Cross-Model Review
- [ ] Phase 2: Memory & PRD
- [ ] Phase 3: Worktree Setup (native EnterWorktree → .claude/worktrees/)
- [ ] Phase 4: Build
- [ ] Phase 5: Wrap & Report
- [ ] Phase 6: Cleanup

## Notes

- Self-referential build: modifies build-os itself. build-os has no `.build/` marker, so the
  edit-guard being built won't fire here. Using native `EnterWorktree` (the new standard) for
  Phase 3 instead of ship.md's current hand-rolled `git worktree add`.
- Plan approved verbally (bootstrap: `/approve` skill doesn't exist yet).

## Memory synthesis (for PRD)

- **R9 / CRITICAL integration gotcha:** `~/.claude/commands` is a MATERIALIZED real dir (post
  `build-config sync`), NOT a symlink. New/modified skills in repo `commands/` will NOT reach the
  live location automatically → they'd be dark code. Task 10 MUST run `build-config sync` (or copy)
  and VERIFY `/plan`, `/approve`, `/ship lite` are actually invocable. `~/.claude/build` IS still a
  symlink → AGENTS.md + `build/hooks/` edits propagate live.
- Embed pre-mortem mitigations (esp. R1 fail-open, R2 don't-touch-live-settings) in each task prompt.
- Explicit file-reading lists in every subagent prompt (highest-impact practice).
- Sequential subagent execution only — no parallel on the same codebase.
- Dark-code audit before merge: every new skill/hook must be invocable/wired, not just present.
- `jq` (1.8.1) + `python3` (3.14.5) both present via homebrew; hook uses `jq`, fail-open if absent.
