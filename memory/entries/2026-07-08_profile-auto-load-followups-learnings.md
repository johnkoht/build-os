# profile-auto-load-followups — Learnings

**Slug:** profile-auto-load-followups
**Date:** 2026-07-08
**Branch:** feature/profile-auto-load-followups
**Parent PRD:** profile-auto-load (merged 2026-06-17)
**Tasks:** 3/3 complete, 0 iterations
**Files touched:** commands/build.md, commands/hotfix.md, build/agents/{orchestrator,developer,reviewer,product-manager}.md

## What we built

Closed the 3 eng-lead-flagged follow-ups from `profile-auto-load`:
1. `/build` orchestrator now explicitly calls `auto_load` in Phase 2 Step 1; developer subagent prompt template references attached profiles.
2. All 4 agent role files (orchestrator, developer, reviewer, product-manager) flipped from passive "when loaded with a profile" to active self-trigger framing, each with a role-specific trigger point ("Before dispatching a subagent" / "Before touching code" / "Before reviewing" / "Before shaping technical scope").
3. `commands/hotfix.md` Phase 1 step 2 parenthetical split — `auto_load` loads PROFILE.md bodies; LEARNINGS.md is a separate read step.

## What worked (+)

- **Prescribed exact old→new strings for compact edits.** Building on parent PRD's learning: for 4 agent files with slightly different Layer 4 lines, prescribing verbatim replacements per file (not "rewrite in active voice") prevented paraphrasing drift and scope creep. 0 iterations across 3 tasks.
- **Anchor-string grep for line-drift risk.** Task 3 (hotfix.md:38) used anchor-string search instead of line number. Turned out line 38 hadn't drifted — but the discipline is right: parent-PRD edits could have shifted it.
- **Atomicity discipline surfaced pre-mortem.** Task 1 required both build.md edits in ONE commit — pre-mortem Risk 2 caught the risk that splitting them would leave the developer prompt template referencing something the orchestrator never did.
- **Copy-paste class error mitigation via per-file greps.** Task 2 AC required 8 grep checks (4 old-string-absent + 4 new-string-present), not 2 aggregate checks. Would have caught a silent typo on one of the 4 files.
- **Verified-fresh check at recon.** Ran phantom-task greps before dispatch to confirm all 3 target strings existed at expected locations. Line 38 was still line 38. Line 30/24/24/25 in agent files matched.

## What didn't work (-)

- **Skipped cross-model review for small PRD.** Ship.md doesn't require it for small plans, and I skipped it. Nothing bit, but for future small-but-architectural PRDs (like this one — it touches the meta-system's role docs), a lightweight cross-model would still be worth ~10 min.
- **Made "same day" assumption on parent-PRD line stability.** Line 38 in hotfix.md was fine, but the pre-mortem correctly flagged this could have drifted. Next time: run the anchor-string grep during pre-mortem, not just as recon.

## Recommendations

### Continue

- **Prescribing exact old→new strings** for compact-format PRDs (agent role files, AGENTS.md, etc.). This is now a two-PRD pattern.
- **Anchor-string grep** over line-number reference when the file was recently edited.
- **Per-file AC greps** for copy-paste-class multi-file tasks (Risk 4).
- **Atomicity discipline** — enforce single-commit for interdependent edits via AC.

### Stop

- **Nothing new** — the parent PRD's stops (literal-string grep on umbrella keys for nested blocks) still apply.

### Start

- **Include lightweight cross-model review even for small PRDs that touch the meta-system.** ~10 min budget for a Sonnet pass on the plan; catches issues even small PRDs can introduce.

## Follow-ups

1. **`commands/review.md` framing alignment.** Reviewer noted `review.md` doesn't have a "Before reviewing…" active-framing sentence like `build/agents/reviewer.md` now does. Not a bug — different files (skill vs. agent role) — but next reviewer.md edit should align registers.
2. **No other framing sweep needed.** ship.md/wrap.md/other command files have zero `auto_load` mentions; nothing else to update.

## Metrics

- Pre-mortem risks: 5 identified, 0 materialized (100% mitigation rate).
- Task iterations: 0 across 3 tasks.
- Verification greps: all 7 passed on first check.
- Cross-model review: skipped (small PRD scope + parent PRD already validated architectural direction).
