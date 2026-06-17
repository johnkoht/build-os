# Working Memory — profile-auto-load

Cross-task knowledge. Every developer reads this before starting and updates it after completing.

## Discovered Patterns
*(Add: [Task N] pattern-name: description at file:line)*
- [Task 1] auto_load compound-key style: Used multi-line `|auto_load:{` with each sub-key on its own `|  key:value` line (two-space indent inside the block), closed with `|}`. The existing `[Skills]` compound blocks are single-line `{key:val,key:val}` but those have short values; `auto_load` has 6 long sub-keys so multi-line is the only readable choice. Every line still starts with `|`, matching the pipe-delimited format. Located at build/AGENTS.md lines 40–48.
- [Task 2] hotfix routing structure: Phase 3 (reviewer subagent) DECIDES the routing — it appends a `**Profile routing**: PROFILE.md ({domain}) / LEARNINGS.md ({file}) / none` line using the same two-question test as post-mortem lines 93–98. Phase 4 step 1 APPLIES that decision mechanically (no re-judgment): updates PROFILE.md (bumping `last_validated:`) or LEARNINGS.md or both (step 2 "optional secondary route" allows both to fire). Phase 4 step 3 report surfaces both `**PROFILE.md**:` and `**LEARNINGS.md**:` for the builder. The key design: decision is in Phase 3 (the review gate), application is in Phase 4 (the close gate) — these must never be merged.

## Active Gotchas

- **[Task 1] AGENTS.md compact pipe-delimited format.** Every line starts with `|`; compound keys use `{` / `}` with indented sub-lines. Match the existing style (compare to existing `[Skills]|ship:{...}` block as a reference). Do not switch to bullet lists.
- **[Task 1] no_frontmatter heuristic** must use the literal mapping rule: `node-api/` profile → match paths containing `api/`; `react-native/` → `mobile/` or `app/`. Keep examples in the AGENTS.md text so future readers can extend.
- **[Task 2] Phase 3 vs Phase 4** — decision lives in Phase 3 (reviewer), application in Phase 4. Do not move the decision back to Phase 4.
- **[Task 2] hotfix.md routing wording** must match `commands/post-mortem.md` lines 93–98 exactly. Either copy verbatim or reference: "Use the routing test from commands/post-mortem.md."
- **[Task 3/4] path extraction is skill-local.** AGENTS.md auto_load assumes paths are already resolved. Pre-mortem and plan-to-prd both extract paths from plan tasks' `**File:**` fields locally before calling auto_load.

## Shared Utilities Created
*(Add: [Task N] functionName() in path/to/file)*

## Context Corrections

- **[Task 1] PRD AC #1 typo (orchestrator override).** AC #1's literal grep `grep "auto_load" build/AGENTS.md ≥ 7` is mis-authored — sub-keys correctly don't repeat the umbrella name, so the literal grep returns 3. The bottom-of-PRD verification block uses the correct grep (`grep -c "trigger:\|skip:\|..." ≥ 7`) and passes with 8. Implementation is faithful to the auto_load procedure; AC #1 grep string was wrong, not the code. Orchestrator approved on the bottom-of-PRD verification, not AC #1's literal text. Future PRDs: use the disjunctive grep form for nested-block ACs.

## Behavioral Walkthrough (Task 1 AC #7)

Document the auto_load mental walkthrough here after Task 1 lands:

1. **Single profile, scope match.** Project has `.build/expertise/api/PROFILE.md` with `scope: api/**`. Target path: `api/src/foo.ts`. Expected: `api` profile body loaded. End-of-session warnings: none.
   - Procedure trace: discovery → `.build/expertise/` exists; match → `scope: api/**` glob matches `api/src/foo.ts`; cap → only 1 profile, under limit; load → body loaded. ✓

2. **Single profile, scope no match.** Same project. Target path: `frontend/src/foo.ts`. Expected: not loaded. Warnings: none.
   - Procedure trace: discovery → exists; match → `scope: api/**` does NOT match `frontend/src/foo.ts`; load → skip body; no warning (profile has frontmatter, so no fallback heuristic triggers). ✓

3. **Anchor no-frontmatter heuristic.** Project has 4 profiles: `node-api`, `react-native`, `memory-system`, `tooling` — all without `scope:` frontmatter. Target path: `api/src/foo.ts`. Expected: only `node-api` body loaded (heuristic match: `api/` substring in path). End-of-session ⚠️ surfaced suggesting `/build-os-retrofit`.
   - Procedure trace: discovery → exists; match → no frontmatter on any profile → fall to `fallback:` heuristic; `node-api/` dir name → "api" substring present in `api/src/foo.ts` → load body; `react-native/` → no "mobile/" or "app/" in path → skip; `memory-system/` → no match → skip; `tooling/` → no match → skip. All 4 profiles lacked frontmatter → ONE end-of-session ⚠️ suggesting `/build-os-retrofit`. ✓

4. **Cap at 3.** Project has 5 profiles with overlapping scope globs all matching `api/src/routes/user.ts`. Expected: 3 profiles with longest scope-glob matches loaded; one-line note listing the other 2.
   - Procedure trace: discovery → exists; match → all 5 scope globs match; cap → rank by specificity (longest glob wins), load top 3; surface one-line note naming the other 2 profiles. ✓
