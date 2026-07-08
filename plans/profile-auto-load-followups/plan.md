---
status: draft
has_pre_mortem: false
has_review: false
has_prd: false
parent_prd: profile-auto-load
---

# Profile Auto-Load Follow-Ups — Close the `/build` Path and Agent Framing

## Context

`profile-auto-load` shipped (commits `72af7a6..aa08247`, merged 2026-06-17). It wired `auto_load` into `[Expertise]`, `/hotfix`, `/pre-mortem`, `/plan-to-prd`, `/review`, and the new-project template.

The eng lead pre-merge review approved the merge but flagged four gaps that "should not rot past the next anchor work session":

1. **`/build` orchestrator path still uses old manual model.** `commands/build.md:99` says `[domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]` — passive "if available" inclusion with no `auto_load` call. `/build` is the highest-frequency execution path (invoked by `/ship`, direct PRD builds). The Orchestrator dispatches the developer without triggering the new procedure.
2. **Agent role files use passive framing.** `build/agents/orchestrator.md:30`, `developer.md:24`, `reviewer.md:24` all say "when loaded with an expertise profile" — as if profiles arrive by magic. After profile-auto-load, each agent is expected to self-trigger. The role docs still describe the old model.
3. **`commands/hotfix.md:38` parenthetical mis-attribution.** "Loads scope-matched PROFILE.md bodies **and any LEARNINGS.md in affected directories**" — the LEARNINGS.md part is not what `auto_load` does. Minor precision fix.
4. **Anchor `/build-os-retrofit` run needed.** Anchor's 4 profiles are still stale (May 11) and lack frontmatter. Without retrofit, the `auto_load` heuristic fallback fires end-of-session ⚠️ every anchor session but the profiles never get scope. This is the original motivating problem — not fixed until anchor is retrofitted.

## Scope

### 1. `/build` orchestrator path — explicit `auto_load` call

In `commands/build.md` Phase 2 Step 1 (Prepare Context), add: "For each task's target files, follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`. Attach loaded PROFILE.md bodies to the developer prompt."

Also update `build.md:99` (the subagent prompt template line): change `[domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]` to `[domain expertise profiles from auto_load — see Layer 4]` or similar. The `[Prepare Context]` step above populates these.

### 2. Agent role files — self-trigger semantics

Update three files to shift from passive "when loaded with a profile" to active "trigger `auto_load` yourself before context assembly":

- `build/agents/orchestrator.md:28-30`: "Layer 4 is optional... When they exist, include them for subagents..." → "Before dispatching a subagent, follow AGENTS.md `auto_load` for the task's target files; attach loaded profiles as Layer 4."
- `build/agents/developer.md:22-24`: "When loaded with an expertise profile..." → "Before touching code, follow AGENTS.md `auto_load` for the files you'll edit; follow loaded profiles' invariants."
- `build/agents/reviewer.md:22-24`: Same pattern — "Before reviewing, follow AGENTS.md `auto_load` for the diff's files; use loaded profiles to check invariants."
- `build/agents/product-manager.md:23-25`: Already references profiles for PRD shaping; align wording with the others.

### 3. `commands/hotfix.md:38` mis-attribution fix

Change:
> Resolve affected files from the bug report, then follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]` with those paths as targets. (Loads scope-matched PROFILE.md bodies and any LEARNINGS.md in affected directories.)

To:
> Resolve affected files from the bug report, then follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]` with those paths as targets. Loads scope-matched PROFILE.md bodies. Separately, read any LEARNINGS.md in affected directories.

### 4. Anchor retrofit run

Not a code change to this repo — a **process action**: run `/build-os-retrofit` in `~/code/anchor` before the next anchor work session. This adds `scope:` and `last_validated:` frontmatter to the 4 stale profiles, ends the mid-session heuristic-fallback dance, and validates the `auto_load` flow with real profiles.

Track this in the anchor project's own memory / backlog rather than as a code change here. Include a checklist item in this plan's success criteria.

## Tasks

### Task 1: build.md Phase 2 Step 1 + line 99
**File:** `commands/build.md`

- In Phase 2 Step 1 (Prepare Context), add a bullet before the "Read completed tasks" bullet: "Follow `auto_load` procedure in AGENTS.md `[Expertise]` for the task's target files; attach loaded PROFILE.md bodies as Layer 4."
- Update the subagent prompt template line 99: replace `[domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]` with `[domain expertise profiles loaded via auto_load — attached above]`.

**AC:**
- `grep "auto_load" commands/build.md` returns ≥ 2 lines.
- Phase 2 Step 1 explicitly lists profile loading as a Prepare Context step.
- Subagent prompt template no longer says "if available".

### Task 2: Agent role files — self-trigger framing
**Files:** `build/agents/orchestrator.md`, `build/agents/developer.md`, `build/agents/reviewer.md`, `build/agents/product-manager.md`

- Rewrite the Layer 4 / expertise mention in each file to active voice.
- Each should reference `auto_load` by name and describe the trigger (before subagent dispatch / before edit / before review).

**AC:**
- All four files reference `auto_load`.
- No file uses "when loaded with a profile" or similar passive phrasing.
- Each mentions its role-specific trigger point.

### Task 3: hotfix.md:38 precision fix
**File:** `commands/hotfix.md`

- Split the parenthetical at line 38 into two sentences: `auto_load` for profile bodies, separate LEARNINGS.md read step.

**AC:**
- `commands/hotfix.md` line ~38 no longer says "and any LEARNINGS.md in affected directories" inside the `auto_load` parenthetical.
- LEARNINGS.md read is called out as a distinct step.

### Task 4: Anchor retrofit — process checklist
**File:** none (this repo); action in `~/code/anchor`

- Success criterion: `~/code/anchor/.build/expertise/*/PROFILE.md` all have `scope:` and `last_validated:` frontmatter.
- Verify by: `grep -l "scope:" ~/code/anchor/.build/expertise/*/PROFILE.md | wc -l` returns 4.

**AC:**
- All 4 anchor profiles have `scope:` frontmatter.
- All 4 anchor profiles have `last_validated:` frontmatter dated ≥ 2026-06-17 (retrofit date).
- One anchor session confirms zero end-of-session ⚠️ from `auto_load` fallback (profiles now scoped).

## Out of Scope

- The hotfix `**Profile routing**:` format brittleness — flagged by eng lead as follow-up item 3, but a fix requires restructuring the output-line format. Defer to a separate plan if it proves problematic in practice.
- Adding profiles to build-os itself (the meta-repo has no `.build/expertise/`). Dogfooding this would require carving up build-os's own domains — a larger question about whether meta-systems should have profiles.
- Runtime enforcement of `auto_load` trigger. The eng lead noted "imminent" is still a self-enforcement contract. Fixing this requires a Claude Code hook or tool intercept — not a build-os change alone.

## Success Criteria

1. `/build` execution: dispatching a task with target files matching a profile's scope loads that profile into the developer's prompt (verified by mental trace of build.md Phase 2 Step 1).
2. All three agent role files (`orchestrator`, `developer`, `reviewer`) describe self-triggering `auto_load` rather than passive receipt.
3. `commands/hotfix.md:38` accurately describes what `auto_load` does vs what LEARNINGS.md reads separately.
4. Anchor's 4 profiles have frontmatter; one anchor session runs without the fallback warning.
