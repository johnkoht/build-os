---
status: approved
has_pre_mortem: true
has_review: true
has_prd: true
---

# Profile Auto-Load — Close the Expertise Lifecycle Gaps

## Context

The expertise profile lifecycle (commit `fc4504c`) landed three weeks ago: `.build/expertise/{domain}/PROFILE.md` files declare `scope` (git-pathspec globs) and `last_validated:` date, `/wrap` flags drift before merge, `/post-mortem` routes learnings between PROFILE.md and LEARNINGS.md. That closed the **update** side for skills that explicitly end work.

But two gaps remain, surfaced by the anchor project: its four profiles (`memory-system`, `node-api`, `react-native`, `tooling`) are dated May 11, despite months of shipped work (wiki-memory P0–P3, school-reports-overhaul, document-library).

**Gap 1 — Loading is skill-gated.** Profiles are only loaded by `/build` (orchestrator → developer Layer 4), `/hotfix` Phase 1, and `/review` Full Review mode. AGENTS.md line 36 explicitly says profiles are "Attached to subagent context as Layer 4 when task touches that domain." Ad-hoc work in a fresh conversation — "fix this bug", "add a route" without invoking a skill — never auto-loads them. The main agent operates without Layer 4.

**Gap 2 — `/hotfix` never updates profiles.** It READS them in Phase 1 (Diagnose) but Phase 4 (Close) only mentions LEARNINGS.md. Hotfixes are exactly when you discover invariant violations and new anti-patterns — losing that signal to LEARNINGS.md only is wasted. `/pre-mortem` and `/plan-to-prd` also don't load profiles, which weakens domain-specific risk analysis and PRD shaping.

## Scope

### 1. Main-agent auto-load (AGENTS.md)
Move profile loading from subagent-only Layer 4 to default behavior. Before non-trivial code work, the main agent scans `.build/expertise/*/PROFILE.md` frontmatter for `scope:` globs matching files about to be touched. Matching profiles get loaded into context.

### 2. `/hotfix` Phase 4 profile routing
Mirror `/post-mortem`'s routing test. If the fix exposed a new invariant or anti-pattern that would block future subagents from working in the domain, write to PROFILE.md and bump `last_validated:`. Otherwise route to LEARNINGS.md as today.

### 3. `/pre-mortem` profile load
Add a step before risk listing: load profiles whose scope matches the plan's intended files. Use them to surface domain-specific risks (invariants the plan might violate, anti-patterns it might reintroduce).

### 4. `/plan-to-prd` profile load
Same pattern as pre-mortem — load relevant profiles before converting plan to PRD so the PM agent can shape technical scope against real architecture.

### 5. `/review` Quick mode profile load
Currently only `/review` Full Review loads profiles. Quick mode should too — at minimum the scope-matched ones, since reviewers need invariants to catch violations.

### 6. `templates/project-claude.md` scan-on-start
Add a line under "Domain Expertise" telling new projects: "Before any non-trivial code work in this project, scan `.build/expertise/*/PROFILE.md` frontmatter `scope:` globs and load matching profiles." So scaffolded projects inherit the behavior from day one.

## Tasks

### Task 1: AGENTS.md — main-agent auto-load
**File:** `build/AGENTS.md`

AGENTS.md is the **matcher**: each call-site (main agent, skills) supplies target paths; AGENTS.md `auto_load` matches them against profile `scope:` globs and decides what to load. AGENTS.md does NOT resolve paths.

- Update `[Expertise]|when:` line: change from "Attached to subagent context as Layer 4 when task touches that domain" to "Loaded as Layer 4 by main agent and subagents before code-modifying work — see `auto_load` for the procedure."
- Update `[Context Stack]|layer_4:` to make explicit this is for both main agent and subagents.
- Add a new compound key `auto_load:` under `[Expertise]` with sub-keys:
  - `trigger:` Load when (a) caller has resolved target file paths AND (b) at least one Edit/Write/code-modifying Bash call is imminent. Mechanical — not based on "behavioral change" or "familiarity."
  - `skip:` (a) single-token change the user named explicitly, (b) documentation-only edits (`*.md`, `docs/**`), (c) test-only changes with no domain-logic files in scope.
  - `discovery:` if `.build/expertise/` doesn't exist or is empty, skip silently. No warning.
  - `match:` for each `PROFILE.md`, read frontmatter `scope:` globs; compare to target paths. Specificity = longest glob match wins.
  - `cap:` load at most 3 profile bodies per task. If more match, load the 3 with longest scope-glob matches; surface a one-line note listing the rest.
  - `fallback:` if `PROFILE.md` has no frontmatter at all, load body ONLY if any target path contains a substring matching the profile's directory name (heuristic scope). Examples: `node-api/` profile matches paths containing `api/`; `react-native/` matches `mobile/` or `app/`. If no heuristic match, skip body and surface one end-of-session ⚠️ suggesting `/build-os-retrofit` (not mid-task — avoid noise).
  - `load:` only scope-matched (or heuristic-matched) bodies are loaded; non-matches stay on disk.

**AC:**
- `grep -A 10 "auto_load" build/AGENTS.md` returns all six sub-keys (`trigger`, `skip`, `discovery`, `match`, `cap`, `fallback`, `load`).
- Behavioral smoke test (mental walkthrough documented in build-log):
  - Project with one `PROFILE.md` containing `scope: api/**`, target path `api/src/foo.ts` → body loaded.
  - Same project, target path `frontend/src/foo.ts` → not loaded.
  - Anchor (4 no-frontmatter profiles), target path `api/src/foo.ts` → only `node-api` loaded via heuristic; one end-of-session ⚠️ surfaced.
  - Project with 5 scope-matched profiles for one path → 3 most-specific loaded; one note listing the other 2.
- The `when:` line no longer says "subagent context" only.

### Task 2: hotfix.md — Phase 3 routing decision + Phase 4 PROFILE.md routing
**File:** `commands/hotfix.md`

The routing **decision** lives in Phase 3 (Review), where the reviewer subagent is already reading the diff cold — the best vantage point for the "would a subagent fail without this?" call. Phase 4 just applies what Phase 3 decided. This avoids the "one more thing after merge" trap.

- **Phase 1 (Diagnose) profile load:** keep current behavior, add reference: "Resolve affected files from the bug report, then follow AGENTS.md `auto_load` procedure with those paths as targets."
- **Phase 3 (Review) — add routing-decision step in the reviewer prompt:**
  - Reviewer asks (in addition to APPROVED/ITERATE): "Did this fix expose a new invariant, anti-pattern, or architectural rule a subagent would need *before* touching this domain?"
  - Routing test wording mirrors `commands/post-mortem.md` lines 93–98 verbatim. If divergence is needed, reference it: "Use the routing test from `commands/post-mortem.md`."
  - Reviewer output adds: `**Profile routing**: PROFILE.md ({domain}) / LEARNINGS.md ({file}) / none`.
- **Phase 4 (Close) — split the existing "Update LEARNINGS.md" step into two:**
  1. **Apply Phase 3 routing decision.** If `PROFILE.md`, update the domain's PROFILE.md (add invariant/anti-pattern, bump `last_validated:` to today). If `LEARNINGS.md`, update as today. If `none`, skip.
  2. **Optional secondary route:** if PROFILE.md got the architectural rule, LEARNINGS.md may still get a file-local gotcha — both can fire.
- Update Phase 4 report template to include `**PROFILE.md**: [domains touched / none]` alongside `**LEARNINGS.md**:`.

**AC:**
- Phase 3 reviewer prompt includes the routing question, with wording matching `commands/post-mortem.md` lines 93–98 (verbatim or by reference).
- Phase 4 step 1 explicitly applies the Phase 3 decision (no re-judging in Phase 4).
- Report template includes both `**PROFILE.md**:` and `**LEARNINGS.md**:` lines.
- `grep "last_validated" commands/hotfix.md` returns at least one line in the PROFILE.md routing block (not in a comment or unrelated section).
- Phase 1 references AGENTS.md `auto_load`.

### Task 3: pre-mortem.md — load profiles before risks
**File:** `commands/pre-mortem.md`

Pre-mortem runs before execution — there are no Edit/Write calls imminent. Path resolution is pre-mortem-specific: extract `**File:**` values from each plan task in the plan's `## Tasks` section. Pass those paths to `auto_load`.

- Add a new "Step 0: Load relevant expertise" section before "Step 1: Work Through Risk Categories":
  - **0a. Resolve target paths.** Extract `**File:**` values from each task in the plan's `## Tasks` section. Collect into a target-path list.
  - **0b. Load profiles.** Pass the path list to AGENTS.md `auto_load`. Load matching profile bodies (Invariants and Anti-Patterns sections at minimum).
- Reference the loaded profiles in the existing risk categories — specifically risk category 6 (Scope drift), risk category 7 (Integration risk), and a new line in risk category 8 (Documentation debt) calling out PROFILE.md invariants the plan might violate.

**AC:**
- pre-mortem.md has Step 0 split into 0a (path extraction) and 0b (call auto_load).
- At least one risk category in the existing list explicitly references "loaded profiles" or "PROFILE.md invariants."
- Skill defers to AGENTS.md `auto_load` for matching/loading — only path resolution is local.

### Task 4: plan-to-prd.md — load profiles for PM
**File:** `commands/plan-to-prd.md`

Same pattern as Task 3 (pre-mortem): paths come from the plan's `**File:**` values; matching/loading delegates to `auto_load`.

- Add a step before the PM agent shapes technical scope:
  - **Resolve target paths** from `**File:**` fields in the plan's `## Tasks` section.
  - **Call AGENTS.md `auto_load`** with those paths.
- In the PRD task-generation step, reference loaded profiles: "Task files should respect architecture from loaded PROFILE.md; ACs should respect documented invariants."

**AC:**
- plan-to-prd.md has explicit path-extraction step before `auto_load` call.
- PRD task generation step references loaded profiles.
- Skill defers to AGENTS.md `auto_load` for matching/loading.

### Task 5: review.md — Quick mode profile + LEARNINGS load
**File:** `commands/review.md`

Today Step 2 (Load Expertise Profiles) and Step 3 (Scan LEARNINGS.md) are both gated to "Full Review only." Quick mode currently has no domain context — defeating its second-opinion value. Unlock both for Quick mode, scoped to matched paths.

- **Step 2 update:** "Quick mode: resolve target paths from the artifact under review (plan `**File:**` fields, PRD task files, or implementation diff). Call AGENTS.md `auto_load` with those paths. Full Review: same, plus load adjacent profiles whose Architecture Map references files in scope."
- **Step 3 update:** "Quick mode: scan LEARNINGS.md in directories matching target paths only. Full Review: scan LEARNINGS.md in target paths + adjacent directories."
- Document the distinction at the top of each step so future readers see Quick vs Full at a glance.

**AC:**
- Step 2 no longer says "Full Review only" — it has explicit Quick and Full branches.
- Step 3 no longer says "Full Review only" — it has explicit Quick and Full branches.
- Quick branch in Step 2 calls AGENTS.md `auto_load`.
- Distinction between Quick (target-scoped) and Full (target + adjacent) is explicit in both steps.

### Task 6: project-claude.md template — scan-on-start
**File:** `templates/project-claude.md`

- Add a sentence under the "Domain Expertise" section pointing builders to the AGENTS.md auto_load procedure: "**Before non-trivial code work, follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` [Expertise] — scan `.build/expertise/*/PROFILE.md` `scope:` frontmatter and load matching profiles.**"
- This is reinforcement; the actual behavior is driven by AGENTS.md (which all projects read), so existing projects without the template change still get auto-load. Note this division of responsibility.
- Ensure new projects scaffolded via `/new-project` inherit the explicit hint.

**AC:** Template has the scan-on-start instruction in the Domain Expertise section, pointing at AGENTS.md auto_load. New projects scaffolded post-merge include the hint.

## Out of Scope

- Auto-writing profile updates (still builder's call — same as today's `/wrap` ⚠️ warnings).
- Cross-project profile sharing (each project owns its own profiles).
- Profile linting / schema validation tool.
- Changes to `/build-os-retrofit` — it already handles bootstrap and migration.
- `/wrap` interaction with auto-loaded profiles. `/wrap` always re-reads from disk for drift detection, regardless of whether `auto_load` already loaded the profile mid-session. Documented here so no future ambiguity claims this as a bug.
- Token cost telemetry. The 3-profile cap is a heuristic limit; no instrumentation to measure actual load behavior. If it proves wrong in practice, adjust the cap value.

## Success Criteria

1. Opening a fresh conversation in any build-os project and typing "fix the bug in `api/src/routes/foo.ts`" causes the main agent to scan `.build/expertise/*/PROFILE.md` and load any profile whose `scope:` matches `api/src/routes/`.
2. Running `/hotfix` end-to-end produces a Phase 4 report that includes both `**LEARNINGS.md**:` and `**PROFILE.md**:` lines, with at least the option of writing to either.
3. Running `/pre-mortem` and `/plan-to-prd` against a plan whose files match a profile's scope loads that profile and references its invariants in the output.
4. Running `/review` in Quick mode loads scope-matched profiles.
5. A new project scaffolded via `/new-project` has CLAUDE.md with the scan-on-start instruction baked in.
