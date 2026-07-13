---
name: ship
description: Full plan-to-merge workflow. Pre-mortem → review → PRD → worktree → build → wrap → merge. Say /ship after approving a plan.
bucket: execution
---

# Ship

Automate the complete build workflow from approved plan to merged code. Say `/ship` and walk away. Pauses only at intelligent gates when human judgment is truly needed.

**Relationship to /build**: Ship is end-to-end (plan → merge). It calls `/plan-to-prd` and `/build` internally. Use `/build` directly when you have a PRD and worktree already set up.

## When to Use

- After approving a plan: say `/ship`
- Medium plans (3-5 steps): `/ship` or `/build` directly
- Large plans (6+ steps): `/ship` (mandatory full workflow)
- **3-5 step, low-risk plans**: `/ship lite {slug}` — skips pre-mortem and cross-model review; keeps PRD, worktree, build, wrap, and merge. Use when the plan is simple enough that risk analysis adds no value.

## Prerequisites

- Plan at `plans/{slug}/plan.md` with `status: approved` (or plan is in conversation)

---

## Worktree Guard (MANDATORY before Phase 4.1)

```bash
git_dir=$(git rev-parse --git-dir 2>/dev/null)
if [[ "$git_dir" == ".git" ]]; then
  echo "❌ In main repo. Create worktree first (Phase 3.1)."
  exit 1
fi
echo "✅ Worktree: $(git branch --show-current)"
```

> Note: This guard passes correctly from `.claude/worktrees/` paths — `git rev-parse --git-dir` returns an absolute `.../.git/worktrees/<name>` there, never the literal string `.git`.

---

## Pre-Flight Check

Read plan frontmatter and detect invocation mode:
- `status: idea/draft` → **HALT**: "Approve the plan first."
- `status: planned/approved` → proceed
- **`/ship lite {slug}` detected** → set `lite=true`; bypass Phase 1.2 AND Phase 1.3 regardless of frontmatter flags
- `has_pre_mortem: true` → skip Phase 1.2 (only checked when `lite=false`)
- `has_review: true` → skip Phase 1.3 (only checked when `lite=false`)
- `has_prd: true` → skip Phase 2.2

**Lite detection**: inspect the invocation args. If the first arg is the literal keyword `lite`, set `lite=true` and treat the second arg as `{slug}`. The `lite` signal is a separate pre-flight condition — it is NOT a frontmatter flag and cannot be set by the model.

---

## Workflow

```
[PHASE 0] Initialize Build Log         → plans/{slug}/build-log.md
[PHASE 1] Pre-Build (main branch)
  1.1 Save Plan
  1.2 Run Pre-Mortem                   → GATE: CRITICAL risks      [skipped in lite mode]
  1.3 Run Cross-Model Review           → GATE: Structural blockers [skipped in lite mode]
[PHASE 2] Memory & PRD (main branch)
  2.1 Memory Review
  2.2 Convert to PRD                   → /plan-to-prd
  2.3 Commit Artifacts
[PHASE 3] Worktree Setup
  3.1 Create Worktree                  → EnterWorktree
  3.2 Switch to Worktree
[PHASE 4] Build (worktree branch)
  4.1 Execute PRD                      → GATE: Task failures
  4.2 Final Review                     → GATE: Major rework needed
[PHASE 5] Wrap & Report
  5.1 Create Memory Entry
  5.2 Update LEARNINGS.md
  5.3 Commit Implementation
  5.4 Verify with /wrap
  5.5 Generate Ship Report
  5.6 Merge Gate (via Gitboss)         → INTERACTIVE
[PHASE 6] Cleanup
  6.1 Remove Worktree & Branch         → ExitWorktree
```

---

## Phase 0: Build Log

Check for `plans/{slug}/build-log.md`:
- **No file** → create with slug + timestamp
- **Exists, incomplete** → append session marker, resume
- **Exists, COMPLETE** → confirm re-run before proceeding

Update at every phase start and complete.

---

## Phase 1: Pre-Build

### 1.1 Save Plan
If plan is only in conversation, save to `plans/{slug}/plan.md` (slug = kebab-case of title).

### 1.2 Pre-Mortem
**Skipped in lite mode.**

Run `/pre-mortem` against `plans/{slug}/plan.md`. Save to `plans/{slug}/pre-mortem.md`.

| Condition | Action |
|-----------|--------|
| No CRITICAL risks | → Proceed |
| Any CRITICAL risk | → **PAUSE** |

### 1.3 Cross-Model Review
**Skipped in lite mode.**

Run `/review` against plan + pre-mortem. Save to `plans/{slug}/review.md`.

| Condition | Action |
|-----------|--------|
| No structural blockers | → Proceed |
| Structural blockers | → **PAUSE** |

---

## Phase 2: Memory & PRD

### 2.1 Memory Review
Search `memory/entries/` (last 14 days + plan keywords). Check `~/.claude/build/memory/collaboration.md`. Synthesize 3-5 actionable bullets for the PRD prompt.

### 2.2 Convert to PRD
Run `/plan-to-prd` with memory synthesis. Validates prd.json has name, branchName, tasks array.

### 2.3 Commit Artifacts
```bash
git add plans/{slug}/ && git commit -m "plan: {slug} - artifacts"
```

---

## Phase 3: Worktree Setup

### 3.1 Create Worktree
Use the native `EnterWorktree` tool. The worktree lands in `.claude/worktrees/{slug}` on a new branch.

```
EnterWorktree(name: "{slug}")
```

> Requires `worktree.baseRef: head` in settings.json (set by install.sh / task-8) so the worktree branches from local HEAD and includes the Phase 2.3 artifact commit — not from `origin/main`.

### 3.2 Switch
`EnterWorktree` changes the working context to the new worktree. Verify the worktree is active and the branch is correct before proceeding to Phase 4.

---

## Phase 4: Build

> **Fix-routing:** Fix requests that arise during or after execution → use `/hotfix` (mandatory reviewer + tests). Never apply ad-hoc patches mid-build.

### 4.1 Execute PRD
Run `/build` with PRD at `plans/{slug}/prd.md`.

| Condition | Action |
|-----------|--------|
| All tasks pass | → Proceed |
| Task fails (2 attempts) | → **PAUSE** |

### 4.2 Final Review
Dispatch orchestrator: Does implementation match PRD intent? All ACs met?

| Condition | Action |
|-----------|--------|
| READY | → Proceed |
| NEEDS_REWORK | → **PAUSE** |

---

## Phase 5: Wrap & Report

### 5.1 Memory Entry
Create `memory/entries/YYYY-MM-DD_{slug}-learnings.md`. Add index to `memory/MEMORY.md`.

### 5.2 LEARNINGS.md
Review completion reports for regressions, first-use patterns, non-obvious decisions. Update relevant files.

### 5.3 Commit
```bash
git add -p && git commit -m "feat: {slug} - implementation"
```

### 5.4 /wrap
Run `/wrap`. Warnings → note and proceed. Failures → fix first.

### 5.5 Ship Report
```markdown
# Ship Complete: {slug}

| Tasks | Quality Gates | Iterations | Commits |
|-------|--------------|------------|---------|
| N/N   | ✓ All passed | N          | N       |
```

### 5.6 Merge Gate
Dispatch gitboss for: pre-merge checks → diff review → builder prompt → merge → version decision.

---

## Phase 6: Cleanup

Use the native `ExitWorktree` tool to remove the worktree and its branch:

```
ExitWorktree(action: "remove")
```

---

## Recovery

| Phase | Failure | Recovery |
|-------|---------|----------|
| 1.2 | CRITICAL risk | Address → `/ship resume` |
| 1.3 | Blockers | Address → `/ship resume` |
| 2.2 | PRD fails | Run `/plan-to-prd` manually |
| 4.1 | Task fails | Resume via `/build` |
| 5.6 | Merge conflicts | Resolve or create PR |
| Any stall | Re-run `/ship {slug}` — build-log detects state |
