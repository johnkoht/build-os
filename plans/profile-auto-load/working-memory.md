# Working Memory — profile-auto-load

Cross-task knowledge. Every developer reads this before starting and updates it after completing.

## Discovered Patterns
*(Add: [Task N] pattern-name: description at file:line)*

## Active Gotchas

- **[Task 1] AGENTS.md compact pipe-delimited format.** Every line starts with `|`; compound keys use `{` / `}` with indented sub-lines. Match the existing style (compare to existing `[Skills]|ship:{...}` block as a reference). Do not switch to bullet lists.
- **[Task 1] no_frontmatter heuristic** must use the literal mapping rule: `node-api/` profile → match paths containing `api/`; `react-native/` → `mobile/` or `app/`. Keep examples in the AGENTS.md text so future readers can extend.
- **[Task 2] Phase 3 vs Phase 4** — decision lives in Phase 3 (reviewer), application in Phase 4. Do not move the decision back to Phase 4.
- **[Task 2] hotfix.md routing wording** must match `commands/post-mortem.md` lines 93–98 exactly. Either copy verbatim or reference: "Use the routing test from commands/post-mortem.md."
- **[Task 3/4] path extraction is skill-local.** AGENTS.md auto_load assumes paths are already resolved. Pre-mortem and plan-to-prd both extract paths from plan tasks' `**File:**` fields locally before calling auto_load.

## Shared Utilities Created
*(Add: [Task N] functionName() in path/to/file)*

## Context Corrections
*(Add: [Task N] MISSING_CONTEXT: what was missing and where to find it)*

## Behavioral Walkthrough (Task 1 AC #7)

Document the auto_load mental walkthrough here after Task 1 lands:

1. **Single profile, scope match.** Project has `.build/expertise/api/PROFILE.md` with `scope: api/**`. Target path: `api/src/foo.ts`. Expected: `api` profile body loaded. End-of-session warnings: none.
2. **Single profile, scope no match.** Same project. Target path: `frontend/src/foo.ts`. Expected: not loaded. Warnings: none.
3. **Anchor no-frontmatter heuristic.** Project has 4 profiles: `node-api`, `react-native`, `memory-system`, `tooling` — all without `scope:` frontmatter. Target path: `api/src/foo.ts`. Expected: only `node-api` body loaded (heuristic match: `api/` substring in path). End-of-session ⚠️ surfaced suggesting `/build-os-retrofit`.
4. **Cap at 3.** Project has 5 profiles with overlapping scope globs all matching `api/src/routes/user.ts`. Expected: 3 profiles with longest scope-glob matches loaded; one-line note listing the other 2.
