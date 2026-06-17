# profile-auto-load — Learnings

**Slug:** profile-auto-load
**Date:** 2026-06-17
**Branch:** feature/profile-auto-load
**Commits:** 76547ab → 6fb5a51 (8 commits)
**Tasks:** 6/6 complete, 0 iterations
**Files touched:** build/AGENTS.md, commands/{hotfix,pre-mortem,plan-to-prd,review}.md, templates/project-claude.md

## What we built

Closed the read/write asymmetry in the expertise profile lifecycle. Before: profiles were skill-gated for loading (only `/build`, `/hotfix` Phase 1, `/review` Full Review) and skill-gated for updating (only `/wrap`, `/post-mortem`). Ad-hoc work in fresh conversations never auto-loaded profiles; `/hotfix` never updated them. Surfaced by anchor's May-11-stale profiles despite months of shipped work.

After: AGENTS.md `[Expertise]|auto_load:{...}` defines a mechanical procedure (trigger, skip, discovery, match, cap, fallback, load) that the main agent and all skills call. Each skill resolves its own target paths and defers matching/loading to `auto_load`. `/hotfix` Phase 3 now decides routing (PROFILE.md vs LEARNINGS.md vs none) using the same test as `/post-mortem`; Phase 4 mechanically applies it.

## Pre-mortem effectiveness

7 risks identified pre-build. **0 materialized** — all were folded into task ACs before dev work:
- Risk 1 (token bloat from vague trigger) → mechanical trigger ("target paths known + Edit/Write imminent")
- Risk 3 (no-frontmatter profiles burning every session) → directory-name heuristic + end-of-session warning (not mid-task)
- Risk 4 (skill/AGENTS.md drift) → skills DEFER to auto_load; path resolution stays skill-local
- Risk 7 (load timing) → explicit "when target file paths are known"

Cross-model review (Sonnet) caught 5 more structural issues — most importantly that the original trigger wording ("changes behavior", "unfamiliar code") was not mechanically evaluable. Folded into Task 1 spec before dev. **The two-stage gate (pre-mortem → cross-model review → fold into PRD) caught issues that would have shipped otherwise.**

## What worked (+)

- **PRD pre-mortem + cross-model review folded directly into task ACs.** Not "see pre-mortem.md" — actual literal text in PRD task descriptions. Devs implemented mitigations without ever looking at pre-mortem.md. 0 risks materialized.
- **Phantom-task greps required before every Write.** All 6 tasks had a literal grep command devs ran before editing; all returned 0 lines. No accidental duplication.
- **Verbatim text in PRD spec for compact-format files (AGENTS.md).** Task 1's `auto_load:{...}` block was prescribed verbatim. Devs copied it. Zero wording drift, zero pre-mortem-mitigated language lost.
- **Sequential subagent execution.** Per memory guidance. 0 lock contention, 0 race conditions across 6 task commits.
- **Direct/candid reviewers, not diplomatic.** Cross-model review caught the trigger ambiguity; Task 1 reviewer caught the PRD's mis-authored AC #1 grep. Hedging reviewers would have missed both.
- **Skill defer-to-AGENTS.md pattern.** Instead of copy-pasting scan procedure into 5 files (hotfix, pre-mortem, plan-to-prd, review, template), each skill resolves paths locally and calls `auto_load`. One source of truth, no drift risk.

## What didn't work (-)

- **AC #1 in Task 1 was mis-authored.** PRD asked `grep "auto_load" build/AGENTS.md ≥ 7` — but sub-keys correctly don't repeat the umbrella name, so the literal grep returns 3. The bottom-of-PRD verification block had the correct grep. Reviewer caught the contradiction. **Lesson:** for nested-block ACs, use disjunctive grep (`grep -c "key1:\|key2:\|..."`) not literal-string grep on the umbrella name.
- **prd.json em-dash unicode escaping** on Python `json.dump` default. First task-status update wrote `—` instead of `—`. Fixed by adding `ensure_ascii=False`. Cosmetic only.
- **Pre-existing `/build` orchestrator gap discovered late.** Holistic review surfaced that build.md:99 still says `[domain expertise profile if available: ...]` — the old manual model. PRD scope didn't include build.md; left as backlog follow-up.

## Recommendations

### Continue

- **Embed pre-mortem mitigations literally in PRD task ACs.** Not references — actual text. Devs apply them without reading pre-mortem.md.
- **Two-gate review pattern (pre-mortem → cross-model review → fold into PRD).** Both gates caught material issues. Either alone wouldn't have.
- **Verbatim text in PRD for compact-format edits.** When the spec wording is itself the deliverable (compact pipe-delimited keys, routing test wording), give the dev the literal text.
- **Skill defer-to-spec pattern.** When N skills need the same procedure, put it in one place (AGENTS.md or a sibling skill) and have all callers defer. Path resolution can stay skill-local.
- **Phantom-task grep as a per-task gate.** Cheap, fast, catches phantoms.

### Stop

- **Literal-string grep ACs on umbrella keys for nested blocks.** Use disjunctive form on sub-keys.

### Start

- **For meta-system changes (build-os itself), include `/build` and orchestrator/developer/reviewer agent files in the scope.** This PRD touched skills + AGENTS.md but left the agent role files passive. They still say "when loaded with a profile" rather than "trigger auto_load yourself." Future build-os PRDs should sweep agent files too.

## Follow-ups (backlog candidates)

1. **`/build` orchestrator auto_load wiring.** build.md:99 still uses manual "if available" inclusion. Add explicit `auto_load` call in Phase 2 Step 1 (Prepare Context). Highest-impact pre-existing gap.
2. **Agent file framing updates.** orchestrator.md:30, developer.md:24, reviewer.md:24 use passive "when loaded with" language. Update each to point at `auto_load` and acknowledge self-trigger semantics.
3. **hotfix.md:102 line-number citation drift risk.** Cites `post-mortem.md lines 93–98` but routing test is at line 98. Anchor by name (`"Routing test:"` heading) for robustness.
4. **Existing projects (anchor) need `/build-os-retrofit`** to add scan-on-start to their own CLAUDE.md. Out of scope for this PRD; necessary for anchor's stale profiles to actually benefit.
5. **hotfix.md:38 parenthetical mis-attribution.** Says auto_load loads LEARNINGS.md too; it doesn't. Trim to "Loads scope-matched PROFILE.md bodies; separately, read LEARNINGS.md in affected directories."

## Metrics

- Pre-mortem risks: 7 identified, 0 materialized (100% mitigation rate via PRD embedding).
- Cross-model review changes: 5 structural, all folded pre-build.
- Task iterations: 0 across 6 tasks. Per-task review caught one PRD typo (overridden by orchestrator).
- Tests added: N/A (markdown/config edits only).
- Verification greps: 8/2/3/2/2/1 — all exceed thresholds.
