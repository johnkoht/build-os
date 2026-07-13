---
title: Build OS Protocol Guardrails
slug: protocol-guardrails
branchName: feature/protocol-guardrails
status: ready
---

# PRD: Build OS Protocol Guardrails

## Problem

Agents skip the `/ship` / `/build` protocols — after a plan is approved they edit source on main
directly instead of routing through the workflow. Root cause: nothing *forces* the protocol; the
only hard gate lives inside `/ship`. Prose fixes have failed 4+ times (per `collaboration.md`).

## Goal

Install harness-enforced guardrails (hooks + skills) + minimal corrective doc steering so the
routed flow is the path of least resistance and structurally hard to skip:

**`/plan` → (iterate) → `/approve` → `/ship` | `/ship lite` | `/build`**, edit-guard as backstop,
`/hotfix` for fixes, worktrees standardized to `.claude/worktrees/`.

## Key environment facts (verified — all task prompts must respect)

- `~/.claude/build` is a **symlink** to `build-os/build/` → AGENTS.md + `build/hooks/` edits are live.
- `~/.claude/commands` is a **materialized real directory** (post `build-config sync`) → new/modified
  skills are DARK CODE until `build-config sync` runs. `install.sh` errors on a real commands dir.
- `~/.claude/settings.json` currently has **no `hooks` key** (additive change).
- `jq` 1.8.1 + `python3` 3.14.5 present (homebrew). Hook uses `jq`, must fail-open if absent.
- Hook command paths must be **absolute** (`/Users/johnkoht/.claude/build/hooks/...`), not `~`.
- build-os itself has **no `.build/`** → intentionally exempt from the guards (bootstrap safety).

## Global build rules

- Sequential subagent execution only (no parallel on the same codebase).
- Every subagent prompt gets an explicit file-reading list.
- Embed the relevant pre-mortem mitigation in each task prompt.
- Fail-open is mandatory for anything in the global hook path.
- Dark-code audit before merge: every new skill/hook must be invocable/wired, not just present.

## Tasks (see prd.json for structured detail + ACs)

1. **Edit-guard hook** — `build/hooks/isolation-guard.sh`, PreToolUse `Edit|Write|MultiEdit|NotebookEdit`,
   `ask` mode, `.build/`-scoped, dir-allowlist, resolve rel paths vs `cwd`, fail-open. + unit tests.
2. **Plan-mode redirect** — empirical `EnterPlanMode` hookability test FIRST, then PreToolUse deny→`/plan`.
3. **`/plan` skill** — our plan-mode replacement; saves `plan.md` live; ends with pre-commitment line.
4. **`/approve` skill** — user-only gate; flips status → approved; prints next step.
5. **Strengthen `/hotfix`** — mandatory reviewer subagent + tests.
6. **`ship.md` overhaul** — `/ship lite` mode + native `EnterWorktree`/`ExitWorktree` + fix-routing note
   + `.gitignore` `.claude/worktrees/` + `worktree.baseRef: head`.
7. **Doc steer + routing** — AGENTS.md (`plan_first`→`/plan`, `isolation_gate`, `small_tasks`,
   `zero_context_switching`) + CLAUDE.md callout + `build.md` fix-routing note.
8. **install + sync wiring** — idempotent `settings.json` hooks merge (absolute path, JSON-validated,
   backup), `build-config sync`, `new-project` + `build-os-retrofit` ensure `.build/` + hooks + gitignore.
9. **Backlog** — `plans/protocol-guardrails/backlog.md` with deferred items.

## Out of scope (backlog)

SessionStart injection, UserPromptSubmit nudge, `.build/.planning` read-only sentinel, statusline
indicator, edit-guard `ask`→`deny` escalation, separate `/fix` skill, retrofitting build-os itself.

## Definition of done

- All 9 tasks complete with ACs met.
- Hook scripts unit-tested (fail-open verified on a non-build repo; allowlist tested both directions).
- `EnterPlanMode` hookability empirically determined; redirect works OR fallback documented.
- Quality gates pass; dark-code audit confirms `/plan`, `/approve`, `/ship lite` invocable after sync.
- Memory entry + LEARNINGS updated; backlog captured.
