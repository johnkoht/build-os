# Cross-Model Review: protocol-guardrails

Reviewer: Sonnet (cross-model). Date: 2026-07-12.

## Verdict

**No structural blockers.** Build executes as `/ship`→`/build` internally; neither needs `/plan`
or `/approve` to exist (bootstrap OK). Artifacts write to allowlisted paths. Worktree sequence is
sound under `baseRef: head`. Edit-guard is inactive during this build (build-os has no `.build/`) —
self-consistent. **Proceed.**

## Task-level requirements (embed as acceptance criteria)

1. **Task 10 — `build-config sync` required.** `~/.claude/commands` is a real dir; `install.sh`
   errors on a real dir (lines 13–15). New/modified skills are dark code until synced. AC: after
   sync, `/plan` and `/approve` are invocable as slash commands.
2. **Task 1 + 10 — absolute hook path.** Use `/Users/johnkoht/.claude/build/hooks/isolation-guard.sh`
   in settings.json; do NOT rely on `~` expansion (undocumented).
3. **Task 8 — verify Worktree Guard from `.claude/worktrees/`.** `git rev-parse --git-dir` returns
   an absolute `.../.git/worktrees/name` there (never literal `.git`), so the guard passes. Add a
   verification step; no code change needed.
4. **Task 8 — gitignore ordering.** Add `.claude/worktrees/` to `.gitignore` as part of Task 8 so
   worktree content isn't shown as untracked noise.
5. **Task 1 — resolve relative `file_path` against `cwd`.** `tool_input.file_path` may be relative;
   join with stdin `cwd` before matching allowlist prefixes, else false negatives.
6. **Task 10 / decision — build-os self-protection.** build-os has no `.build/`, so it's never
   guarded. DECISION: **defer** (adding `.build/` would make the guard + plan-mode redirect fire
   during framework development). Backlog item.
7. **Task 6 — `/ship lite` pre-flight threading.** Specify invocation (arg/keyword) and modify the
   pre-flight gate to bypass 1.2/1.3 on the lite signal even when frontmatter flags are false.
8. **Task 2 — empirical `EnterPlanMode` test first.** Write the test/verify step before the hook
   code; explicit fallback (CLAUDE.md callout) if the matcher never fires.

## Gate

Phase 1.3 PASSED. No structural blockers. Notes above are task-prompt requirements, not plan changes.
