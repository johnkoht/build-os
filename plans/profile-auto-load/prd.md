---
status: ready
slug: profile-auto-load
branchName: feature/profile-auto-load
---

# PRD: Profile Auto-Load — Close the Expertise Lifecycle Gaps

## Goal

Make expertise profile loading automatic for the main agent (not just skill-gated subagents), and add PROFILE.md routing to `/hotfix`, `/pre-mortem`, `/plan-to-prd`, and `/review` Quick mode — closing the read/write asymmetry surfaced by the anchor project's May-11-stale profiles.

## Embedded Memory Guidance (apply to every task)

1. **Explicit file reading list in every subagent prompt** — paths with line numbers when known. Single highest-impact practice across 50+ PRDs.
2. **Pre-mortem mitigations + reviewer concerns are embedded in each task prompt below** — not just referenced. Apply them directly while implementing.
3. **Phantom task detection** — before writing to a target file, `grep` for the key strings you're about to add (`auto_load`, `last_validated`, "Profile routing", "Step 0") to confirm you're not duplicating existing content.
4. **Sequential execution only** — never run developer subagents in parallel on the same codebase.
5. **Direct reviewers, not diplomatic** — reviewer subagents should give candid engineering judgment on AGENTS.md's compact format, not hedge.

## Embedded Pre-Mortem Mitigations (apply to every task)

- **Risk 1 (token bloat):** trigger is mechanical (target paths known + Edit/Write imminent), not subjective. Reflected in Task 1 sub-key wording.
- **Risk 2 (no .build/expertise/ dir):** silent skip. Reflected in `discovery:` sub-key.
- **Risk 3 (no-frontmatter profiles):** heuristic directory-name match, end-of-session warning (not mid-task). Reflected in `fallback:` sub-key.
- **Risk 4 (skill-AGENTS.md drift):** all skills DEFER to `auto_load`. Path resolution is local; matching/loading is delegated.
- **Risk 5 (hotfix routing wording drift):** verbatim from `commands/post-mortem.md` lines 93–98 (or direct reference).
- **Risk 7 (profile load timing):** "when target file paths are known" — captured in `trigger:` sub-key.

## Embedded Reviewer Structural Changes (apply to every task)

- **Trigger is mechanical** (Reviewer Change 1) → Task 1 `trigger:` sub-key.
- **No-frontmatter heuristic + end-of-session warning** (Reviewer Change 2) → Task 1 `fallback:` sub-key.
- **3-profile cap** (Reviewer Change 3) → Task 1 `cap:` sub-key.
- **Hotfix routing decision in Phase 3, application in Phase 4** (Reviewer Change 4) → Task 2 structure.
- **Pre-mortem extracts paths from plan tasks' `**File:**` fields** (Reviewer Change 5) → Task 3 Step 0a.

---

## Tasks

### Task 1: AGENTS.md — `auto_load` procedure

**Files to READ first:**
- `/Users/johnkoht/code/build-os/build/AGENTS.md` (full file, ~70 lines)
- `/Users/johnkoht/code/build-os/build/AGENTS.md` lines 30–40 specifically (current `[Expertise]` block)
- `/Users/johnkoht/code/build-os/build/AGENTS.md` lines 56–65 (current `[Context Stack]` block — Layer 4)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/build/AGENTS.md`

**What to do:**

Update two existing lines, add one new compound key. Preserve the pipe-delimited compact format.

1. Update existing `[Expertise]|when:` line. Change FROM:
   ```
   |when:Attached to subagent context as Layer 4 when task touches that domain
   ```
   TO:
   ```
   |when:Loaded as Layer 4 by main agent and subagents before code-modifying work — see `auto_load` for the procedure
   ```

2. Update existing `[Context Stack]|layer_4:` line. Change FROM:
   ```
   |layer_4:Domain expertise — project-local .build/expertise/{domain}/PROFILE.md (when available)
   ```
   TO:
   ```
   |layer_4:Domain expertise — project-local .build/expertise/{domain}/PROFILE.md (when available; loaded by main agent AND subagents via `auto_load`)
   ```

3. Add a new compound key `auto_load:` under `[Expertise]` (insert after the existing `bootstrap:` line). Format follows compact convention with sub-keys on indented lines. Use this exact content:
   ```
   |auto_load:{
   |  trigger:Load when (a) caller has resolved target file paths AND (b) at least one Edit/Write/code-modifying Bash call is imminent. Mechanical — not based on "behavioral change" or "familiarity."
   |  skip:(a) single-token change the user named explicitly, (b) documentation-only edits (`*.md`, `docs/**`), (c) test-only changes with no domain-logic files in scope
   |  discovery:If `.build/expertise/` doesn't exist or is empty, skip silently. No warning.
   |  match:For each PROFILE.md, read frontmatter `scope:` globs; compare to target paths. Specificity = longest glob match wins.
   |  cap:Load at most 3 profile bodies per task. If more match, load 3 with longest scope-glob matches; surface a one-line note listing the rest.
   |  fallback:If PROFILE.md has no frontmatter, load body ONLY if any target path contains a substring matching the profile's directory name. Examples: `node-api/` matches paths containing `api/`; `react-native/` matches `mobile/` or `app/`. If no heuristic match, skip body and surface ONE end-of-session ⚠️ suggesting `/build-os-retrofit` — not mid-task.
   |  load:Only scope-matched (or heuristic-matched) bodies are loaded; non-matches stay on disk.
   |}
   ```
   (Match the actual compact-key indentation/format used elsewhere in AGENTS.md after reading the file. The key insight is: each sub-key on its own line, all under the `auto_load:` umbrella.)

**Phantom-task grep before writing:**
```bash
grep -n "auto_load" /Users/johnkoht/code/build-os/build/AGENTS.md
```
Must return zero lines. If it returns anything, STOP — the work is already done or in progress.

**Acceptance Criteria:**
1. `grep "auto_load" build/AGENTS.md` returns at least 7 lines (the umbrella + 6 sub-keys).
2. `grep "trigger:" build/AGENTS.md` returns a line containing "target file paths" and "Edit/Write".
3. `grep "fallback:" build/AGENTS.md` returns a line referencing "directory name" and "end-of-session".
4. `grep "cap:" build/AGENTS.md` returns a line containing "3 profile bodies".
5. The `[Expertise]|when:` line no longer contains "subagent context" alone.
6. The `[Context Stack]|layer_4:` line mentions "main agent AND subagents" (or equivalent).
7. **Behavioral walkthrough** (document in working-memory.md):
   - One profile with `scope: api/**`, target `api/src/foo.ts` → body loaded. ✓
   - Same project, target `frontend/src/foo.ts` → not loaded. ✓
   - Anchor (4 no-frontmatter profiles), target `api/src/foo.ts` → `node-api` only via heuristic; one end-of-session ⚠️. ✓
   - 5 scope-matched profiles → 3 most-specific loaded; one note about the other 2. ✓
8. AGENTS.md still parses as the same compact pipe-delimited format — no broken keys.

---

### Task 2: hotfix.md — Phase 3 routing decision + Phase 4 PROFILE.md write

**Files to READ first:**
- `/Users/johnkoht/code/build-os/commands/hotfix.md` (full file)
- `/Users/johnkoht/code/build-os/commands/post-mortem.md` lines 91–112 (the routing test wording to mirror)
- `/Users/johnkoht/code/build-os/commands/hotfix.md` Phase 1 (~lines 25–50, current profile load), Phase 3 (reviewer prompt), Phase 4 (~lines 108–130, current LEARNINGS.md step)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/commands/hotfix.md`

**What to do:**

Three edits:

1. **Phase 1 — Diagnose, step 2 ("Load relevant expertise"):** Add a reference to AGENTS.md `auto_load`. Change the current bullet from "Check `.build/expertise/{domain}/PROFILE.md` for relevant domains" to:
   ```
   - Resolve affected files from the bug report, then follow AGENTS.md `auto_load` procedure with those paths as targets. (Loads scope-matched PROFILE.md bodies and any LEARNINGS.md in affected directories.)
   ```

2. **Phase 3 — Review reviewer prompt:** Add the routing-decision question. The reviewer subagent currently answers APPROVED or ITERATE. Add a third output line: **Profile routing**. Insert after the existing reviewer prompt body, before the APPROVED/ITERATE decision:
   ```
   Additionally, decide profile routing using the test from `commands/post-mortem.md` lines 93–98:
   "If I delegate a subagent to a task in this domain tomorrow, would it fail without this loaded up-front?" → PROFILE.md.
   "Would the subagent be fine working on the domain in general but mess up *this specific file* without the note?" → LEARNINGS.md.

   Reviewer output adds one line:
   **Profile routing**: PROFILE.md ({domain}) / LEARNINGS.md ({file}) / none
   ```

3. **Phase 4 — Close, replace step 1 ("Update LEARNINGS.md"):** Split into two routing-applying steps:
   ```
   1. **Apply Phase 3 routing decision.**
      - If `PROFILE.md ({domain})`: update `.build/expertise/{domain}/PROFILE.md` with the new invariant or anti-pattern. Bump `last_validated:` to today's date.
      - If `LEARNINGS.md ({file})`: update the nearest LEARNINGS.md to that file.
      - If `none`: skip.

   2. **Optional secondary route.** Both can fire: a fix may produce both an architectural invariant (PROFILE.md) and a file-local gotcha (LEARNINGS.md). Apply both if Phase 3 flagged both.
   ```

4. **Phase 4 report template:** Add a `**PROFILE.md**:` line alongside the existing `**LEARNINGS.md**:` line:
   ```
   **LEARNINGS.md**: [updated / not applicable — reason]
   **PROFILE.md**: [domains touched / none]
   ```

**Phantom-task grep before writing:**
```bash
grep -n "Profile routing\|last_validated" /Users/johnkoht/code/build-os/commands/hotfix.md
```
Must return zero lines. If non-zero, STOP.

**Acceptance Criteria:**
1. Phase 3 reviewer prompt contains the routing question with wording referencing `commands/post-mortem.md` lines 93–98.
2. Phase 3 reviewer output line `**Profile routing**:` is documented.
3. Phase 4 step 1 explicitly says "Apply Phase 3 routing decision" — no re-judging in Phase 4.
4. Phase 4 report template has both `**PROFILE.md**:` and `**LEARNINGS.md**:` lines.
5. `grep "last_validated" commands/hotfix.md` returns at least one line, in the Phase 4 routing block.
6. Phase 1 step 2 references AGENTS.md `auto_load`.
7. No prior LEARNINGS.md behavior is REMOVED — the routing is additive.

---

### Task 3: pre-mortem.md — Step 0 path extraction + auto_load

**Files to READ first:**
- `/Users/johnkoht/code/build-os/commands/pre-mortem.md` (full file, ~127 lines)
- Specifically lines 19–53 (current Workflow with Risk Categories)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/commands/pre-mortem.md`

**What to do:**

Insert a new "Step 0: Load relevant expertise" before "Step 1: Work Through Risk Categories" (current line 21). Add references in three of the existing risk categories.

1. **Insert Step 0** before Step 1:
   ```markdown
   ### 0. Load Relevant Expertise

   Pre-mortem runs before execution — `Edit`/`Write` is not yet imminent. So path resolution happens HERE, then we hand paths to `auto_load`.

   **0a. Resolve target paths.** Extract `**File:**` values from each task in the plan's `## Tasks` section. Collect into a target-path list. If a task has no `**File:**` field, infer from the task description (last resort).

   **0b. Load profiles via AGENTS.md `auto_load`.** Pass the path list to the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`. Load matching profile bodies — at minimum the Invariants and Anti-Patterns sections.

   The loaded profiles inform the risk analysis below. Reference them by domain name in the risks they relate to.
   ```

2. **Update risk category 6 (Scope drift)** to reference loaded profiles. Add to the end of that bullet:
   ```
   Cross-check against loaded PROFILE.md invariants — does any AC violate or extend them?
   ```

3. **Update risk category 7 (Integration risk)** to reference loaded profiles. Add to the end of that bullet:
   ```
   Check loaded PROFILE.md Architecture Map — are seams accounted for?
   ```

4. **Update risk category 8 (Documentation debt)** — explicitly mention PROFILE.md updates. The existing bullet already mentions "expertise profiles" — extend it:
   ```
   8. **Documentation debt** — What docs will become stale after this work? README, LEARNINGS.md, expertise profiles? If loaded PROFILE.md invariants are being changed, does the profile itself need an update + `last_validated:` bump?
   ```

**Phantom-task grep before writing:**
```bash
grep -n "Step 0\|0a. Resolve\|auto_load" /Users/johnkoht/code/build-os/commands/pre-mortem.md
```
Must return zero lines. If non-zero, STOP.

**Acceptance Criteria:**
1. pre-mortem.md has a "Step 0" or "### 0." section before "Step 1" / "### 1.".
2. Step 0 has explicitly numbered sub-steps `0a` (path extraction) and `0b` (call `auto_load`).
3. Step 0b references `AGENTS.md` `auto_load` (not redefining the procedure).
4. At least one of risk categories 6, 7, or 8 explicitly references "loaded profiles" or "PROFILE.md invariants" or "PROFILE.md Architecture Map".
5. Risk category 8 mentions `last_validated:` bump.
6. `grep "auto_load" commands/pre-mortem.md` returns at least one line.

---

### Task 4: plan-to-prd.md — load profiles for PM

**Files to READ first:**
- `/Users/johnkoht/code/build-os/commands/plan-to-prd.md` (full file, ~112 lines)
- Specifically the Workflow section (lines 21–69) — note Step 2 (prd.md creation)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/commands/plan-to-prd.md`

**What to do:**

Insert a "Step 1.5" (or rename to keep the numbering clean) between "1. Derive Feature Slug" and "2. Create prd.md". This step extracts paths and calls `auto_load` before the PM agent shapes technical scope.

1. **Insert new step** between current Step 1 and Step 2 (current line 27):
   ```markdown
   ### 2. Load Relevant Expertise

   Before shaping technical scope, load any expertise profiles relevant to the plan's target files.

   **a. Resolve target paths.** Extract `**File:**` values from each task in the plan's `## Tasks` section. Collect into a target-path list.

   **b. Load profiles via AGENTS.md `auto_load`.** Pass the path list to the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`. Load matching profile bodies.

   The PRD's task generation (next step) should respect loaded PROFILE.md architecture — task `**File:**` paths should align with existing architecture; ACs should respect documented invariants.

   ---
   ```

2. **Renumber subsequent steps**: current Step 2 (Create prd.md) → Step 3, Step 3 (Generate prd.json) → Step 4, Step 4 (Initialize working-memory.md) → Step 5, Step 5 (Present Summary) → Step 6.

3. **In the new Step 3 (Create prd.md), add a bullet about profile awareness:**
   Add to the existing list of what prd.md should contain (after the "Acceptance Criteria" bullet):
   ```
   - **Profile-respecting tasks** — task `**File:**` paths should align with loaded PROFILE.md architecture; ACs should respect documented invariants.
   ```

**Phantom-task grep before writing:**
```bash
grep -n "Load Relevant Expertise\|auto_load" /Users/johnkoht/code/build-os/commands/plan-to-prd.md
```
Must return zero lines.

**Acceptance Criteria:**
1. plan-to-prd.md has an explicit "Load Relevant Expertise" step BEFORE the PRD creation step.
2. The new step has sub-steps for path extraction and `auto_load` call.
3. `grep "auto_load" commands/plan-to-prd.md` returns at least one line.
4. The PRD-creation step references loaded PROFILE.md / loaded profiles.
5. Step numbering remains coherent (no duplicate numbers, no gaps).

---

### Task 5: review.md — Quick mode profile + LEARNINGS load

**Files to READ first:**
- `/Users/johnkoht/code/build-os/commands/review.md` (full file, ~210 lines)
- Specifically Step 2 (lines 41–43, current "Full Review only" gate)
- Step 3 (lines 47–49, current "Full Review only" gate)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/commands/review.md`

**What to do:**

Update both Step 2 and Step 3 to have explicit Quick and Full branches instead of being gated to Full only.

1. **Replace Step 2** (current header: "Step 2: Load Expertise Profiles (Full Review only)") with:
   ```markdown
   ## Step 2: Load Expertise Profiles

   **Quick mode:**
   - Resolve target paths from the artifact under review: plan `**File:**` fields, PRD task files, or implementation diff.
   - Call AGENTS.md `auto_load` with those paths. Loads scope-matched PROFILE.md bodies (with the 3-profile cap and no-frontmatter fallback).

   **Full Review:**
   - Same as Quick (call `auto_load`), PLUS load adjacent profiles whose Architecture Map references files in scope. These give cross-domain context that scope-only matching misses.
   ```

2. **Replace Step 3** (current header: "Step 3: Scan LEARNINGS.md (Full Review only)") with:
   ```markdown
   ## Step 3: Scan LEARNINGS.md

   **Quick mode:**
   - Scan LEARNINGS.md files ONLY in directories matching target paths. Confirm the plan/PRD/implementation respects documented invariants and avoids documented pitfalls.

   **Full Review:**
   - Scan LEARNINGS.md in target-path directories PLUS adjacent directories where related code lives.
   ```

**Phantom-task grep before writing:**
```bash
grep -n "Quick mode:\|Full Review:" /Users/johnkoht/code/build-os/commands/review.md
```
Should return zero lines initially (current file gates by `(Full Review only)` suffix, not by explicit Quick/Full branches).

**Acceptance Criteria:**
1. Step 2 header no longer says "(Full Review only)".
2. Step 3 header no longer says "(Full Review only)".
3. Both Step 2 and Step 3 have explicit "Quick mode:" and "Full Review:" branches.
4. Step 2 Quick branch references AGENTS.md `auto_load`.
5. Full Review branches add "adjacent" / "Architecture Map" / cross-domain context language.
6. `grep "Quick mode:" commands/review.md` returns at least 2 lines (one in Step 2, one in Step 3).

---

### Task 6: project-claude.md template — scan-on-start instruction

**Files to READ first:**
- `/Users/johnkoht/code/build-os/templates/project-claude.md` (full file)
- Specifically lines 71–80 (current "Domain Expertise" section)

**Files to WRITE:**
- `/Users/johnkoht/code/build-os/templates/project-claude.md`

**What to do:**

Add a scan-on-start instruction at the top of the "Domain Expertise" section. The existing section explains where profiles live; this addition tells builders/Claude to actually use them.

1. **Insert at the top of the "## Domain Expertise" section** (just after the heading, before the existing comment-block guidance):
   ```markdown
   **Before non-trivial code work in this project, follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`** — scan `.build/expertise/*/PROFILE.md` `scope:` frontmatter and load profiles whose globs match the files you're about to touch. This is reinforcement of AGENTS.md's auto_load (the actual behavior is driven there); the explicit hint here helps builders reading the project's own CLAUDE.md understand the loading model.

   ```

**Phantom-task grep before writing:**
```bash
grep -n "auto_load\|scan-on-start" /Users/johnkoht/code/build-os/templates/project-claude.md
```
Must return zero lines.

**Acceptance Criteria:**
1. `templates/project-claude.md` "Domain Expertise" section starts with a paragraph pointing at `~/.claude/build/AGENTS.md` `auto_load`.
2. `grep "auto_load" templates/project-claude.md` returns at least one line.
3. The added paragraph mentions both `scope:` frontmatter and "files you're about to touch".
4. Existing profile-list example bullets (`api:`, `models:`) remain intact below the new paragraph.

---

## Out of Scope (do not change)

- Auto-writing profile updates — still builder's call.
- Cross-project profile sharing.
- Profile linting / schema validation.
- `/build-os-retrofit` skill — already handles bootstrap/migration.
- `/wrap` interaction with auto-loaded profiles — `/wrap` always re-reads from disk.
- Token telemetry on the 3-profile cap.

## Verification (post-build, before /wrap)

Run all of these from the repo root after all 6 tasks complete:
```bash
# All sub-keys present in AGENTS.md
grep -c "trigger:\|skip:\|discovery:\|match:\|cap:\|fallback:\|load:" build/AGENTS.md  # ≥ 7

# Hotfix routing wired
grep -c "Profile routing\|last_validated" commands/hotfix.md  # ≥ 2

# Pre-mortem Step 0
grep -c "Step 0\|0a. Resolve\|auto_load" commands/pre-mortem.md  # ≥ 2

# Plan-to-prd auto_load
grep -c "Load Relevant Expertise\|auto_load" commands/plan-to-prd.md  # ≥ 2

# Review unlocked for Quick mode
grep -c "Quick mode:" commands/review.md  # ≥ 2

# Template scan-on-start
grep -c "auto_load" templates/project-claude.md  # ≥ 1
```
