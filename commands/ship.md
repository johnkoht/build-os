---
name: ship
description: Full plan-to-merge workflow. Pre-mortem → review → PRD → worktree → build → wrap → merge. Say /ship after approving a plan.
---

# Ship

Automate the complete build workflow from approved plan to merged code. Say `/ship` and walk away. Pauses only at intelligent gates when human judgment is truly needed.

**Relationship to /build**: Ship is end-to-end (plan → merge). It calls `/plan-to-prd` and `/build` internally. Use `/build` directly when you have a PRD and worktree already set up.

## When to Use

- After approving a plan: say `/ship`
- Medium plans (3-5 steps): `/ship` or `/build` directly
- Large plans (6+ steps): `/ship` (mandatory full workflow)

## Prerequisites

- Plan exists at `dev/work/plans/{slug}/plan.md` with `status: approved`
- Git worktrees available (`git worktree` command)

---

## Worktree Guard (MANDATORY)

Planning phases may run from the main repo. Code execution MUST run from a worktree.

Before Phase 4.1, verify:

```bash
git_dir=$(git rev-parse --git-dir 2>/dev/null)
if [[ "$git_dir" == ".git" ]]; then
  echo "❌ You're in the main repo. Code execution blocked."
  echo "   Complete Phase 3.1 (create worktree) first."
  exit 1
fi
branch=$(git branch --show-current)
echo "✅ Worktree confirmed | Branch: $branch"
```

---

## Pre-Flight Check (MANDATORY)

Read `dev/work/plans/{slug}/plan.md` frontmatter:
- `status: idea` or `draft` → **HALT**: "Approve the plan first."
- `status: planned` or `approved` → proceed
- `has_pre_mortem: true` → skip Phase 1.2
- `has_review: true` → skip Phase 1.3
- `has_prd: true` → skip Phase 2.2

---

## Workflow

```
[PHASE 0] Initialize Build Log
[PHASE 1] Pre-Build (main branch)
  1.1 Save Plan
  1.2 Run Pre-Mortem              → GATE: CRITICAL risks
  1.3 Run Cross-Model Review      → GATE: Structural blockers
[PHASE 2] Memory & PRD (main branch)
  2.1 Memory Review
  2.2 Convert to PRD
  2.3 Commit Artifacts
[PHASE 3] Worktree Setup
  3.1 Create Worktree
  3.2 Switch to Worktree
[PHASE 4] Build (worktree branch)
  4.1 Execute PRD                 → GATE: Task failures
  4.2 Final Review                → GATE: Major rework needed
[PHASE 5] Wrap & Report (worktree branch)
  5.1 Create Memory Entry
  5.2 Update LEARNINGS.md
  5.3 Commit Implementation
  5.4 Verify with /wrap
  5.5 Generate Ship Report
  5.6 Merge Gate (via Gitboss)    → INTERACTIVE
[PHASE 6] Cleanup (after merge)
  6.1 Remove Worktree & Branch
```

---

## Phase 0: Initialize Build Log

1. Check for `dev/executions/{slug}/build-log.md`
2. **No file** → create it with: slug, timestamp, phase tracker
3. **Exists, incomplete** → append session marker, resume from last phase
4. **Exists, COMPLETE** → confirm re-run before proceeding

Update build-log at every phase start and complete.

---

## Phase 1: Pre-Build (main branch)

### 1.1 Save Plan
If plan is only in conversation, save it to `dev/work/plans/{slug}/plan.md`. Derive slug from plan title (kebab-case).

### 1.2 Run Pre-Mortem
Load `/pre-mortem` against `dev/work/plans/{slug}/plan.md`. Save output to `pre-mortem.md`.

**Gate:**
| Condition | Action |
|-----------|--------|
| No CRITICAL risks | → Proceed to 1.3 |
| Any CRITICAL risk | → **PAUSE**: report to builder |

### 1.3 Run Cross-Model Review
Load `/review` against plan + pre-mortem. Save output to `review.md`.

**Gate:**
| Condition | Action |
|-----------|--------|
| No structural blockers | → Proceed to 2.1 |
| Structural blockers | → **PAUSE**: report to builder |

---

## Phase 2: Memory & PRD

### 2.1 Memory Review
Search `memory/entries/` for entries from last 14 days and entries matching plan keywords. Check LEARNINGS.md in directories the plan touches. Check `~/.claude/build/memory/collaboration.md` for personal preferences. Synthesize into 3-5 actionable bullets.

### 2.2 Convert to PRD
Load `/plan-to-prd` with memory synthesis from 2.1 in the task prompt. Generates both `prd.md` and `prd.json`. Validate prd.json has: name, branchName, tasks array with all required fields.

### 2.3 Commit Artifacts
Stage and commit plan.md, pre-mortem.md, review.md, prd.md, prd.json. Message: `plan: {slug} - artifacts`.

---

## Phase 3: Worktree Setup

### 3.1 Create Worktree
```bash
git worktree add ../{repo}-worktrees/{slug} -b feature/{slug}
```

### 3.2 Switch to Worktree
Change CWD to the worktree. Verify: `.git` is a file (not directory), branch is `feature/{slug}`.

---

## Phase 4: Build (worktree)

### 4.1 Execute PRD
Load `/build` skill. Pass PRD at `dev/work/plans/{slug}/prd.md` and execution state at `dev/executions/{slug}/`. The skill handles task dispatch, reviewer checks, quality gates, and progress tracking.

**Gate:**
| Condition | Action |
|-----------|--------|
| All tasks pass quality gates | → Proceed to 4.2 |
| Task fails quality gates (2 attempts) | → **PAUSE**: report task, error, options |

### 4.2 Final Review
Dispatch orchestrator subagent for holistic review: Does implementation match PRD intent? All ACs met? Code quality adequate?

**Gate:**
| Condition | Action |
|-----------|--------|
| READY | → Proceed to Phase 5 |
| NEEDS_REWORK | → **PAUSE**: report issues, offer fix/override/abort |

---

## Phase 5: Wrap & Report

### 5.1 Create Memory Entry
Synthesize `memory/entries/YYYY-MM-DD_{slug}-learnings.md` with 5 sections:
1. Metrics (tasks, success rate, iterations, tests added)
2. Pre-mortem effectiveness (risk table)
3. What worked / what didn't (+/- format)
4. Recommendations (continue/stop/start)
5. Follow-ups (refactor items, doc gaps)

Add index line to `memory/MEMORY.md`.

### 5.2 Update LEARNINGS.md
Review `dev/executions/{slug}/progress.md` for regressions, first-use patterns, non-obvious decisions. Update relevant LEARNINGS.md files. If genuinely none, verify and note "No new learnings — verified".

### 5.3 Commit Implementation
Stage all implementation files, memory entry, LEARNINGS.md updates. Message: `feat: {slug} - implementation`.

### 5.4 Verify with /wrap
Run `/wrap`. Warnings (⚠️) → note in report, proceed. Failures (✗) → fix before proceeding.

### 5.5 Generate Ship Report
```markdown
# Ship Complete: {slug}

| Metric | Value |
|--------|-------|
| Phases Completed | 5/5 |
| Tasks Executed | N/N |
| Quality Gates | ✓ All passed |
| Gate Pauses | N |
| Commits | N |

## Next Steps
1. Review changes in worktree
2. Create PR or merge directly
```

### 5.6 Merge Gate
Dispatch gitboss for: pre-merge checks → diff review → builder prompt (M/R/L) → merge with --no-ff → version decision.

---

## Phase 6: Cleanup

After successful merge:
```bash
git worktree remove ../{repo}-worktrees/{slug}
git branch -D feature/{slug}
git push origin --delete feature/{slug}  # if pushed
```

---

## Recovery

| Phase | Failure | Recovery |
|-------|---------|----------|
| 1.2 | Gate PAUSE (CRITICAL risk) | Address risk → `/ship resume` |
| 1.3 | Gate PAUSE (blockers) | Address blockers → `/ship resume` |
| 2.2 | PRD creation fails | Run `/plan-to-prd` manually |
| 4.1 | Task fails quality gates | Resume via `/build` |
| 5.6 | Merge conflicts | Resolve or create PR |
| Any | Stall | Re-run `/ship {slug}` — build-log detects state, resumes |
