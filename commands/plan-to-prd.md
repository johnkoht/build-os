---
name: plan-to-prd
description: Convert an approved plan into prd.md + prd.json for autonomous execution.
bucket: planning
---

# Plan to PRD

Convert an approved plan into a PRD (`prd.md`) and structured task list (`prd.json`) — both in one pass.

## When to Use

- After a plan is approved: "Convert to PRD"
- Ship Phase 2.2: converting plan to execution-ready PRD

## Prerequisites

- An approved plan exists (in conversation or at `plans/{slug}/plan.md`)

---

## Workflow

### 1. Derive Feature Slug

From the plan title, derive a kebab-case slug (e.g. `user-auth`, `payment-integration`). Directory: `plans/{slug}/`.

### 2. Load Relevant Expertise

Before shaping technical scope, load any expertise profiles relevant to the plan's target files.

**a. Resolve target paths.** Extract `**File:**` values from each task in the plan's `## Tasks` section. Collect into a target-path list.

**b. Load profiles via AGENTS.md `auto_load`.** Pass the path list to the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`. Load matching profile bodies.

The PRD's task generation (next step) should respect loaded PROFILE.md architecture — task `**File:**` paths should align with existing architecture; ACs should respect documented invariants.

---

### 3. Create prd.md

Create `plans/{slug}/prd.md`:

- **Goal** — 1-2 sentences summarizing what this work achieves
- **Tasks** — One per plan step (group sub-steps where they naturally belong)
- **Acceptance Criteria** — Explicit, testable criteria per task. Flag inferred ACs: `<!-- inferred from plan -->`
- **Profile-respecting tasks** — task `**File:**` paths should align with loaded PROFILE.md architecture; ACs should respect documented invariants.

Each task must have: title, description, at least one acceptance criterion.

**AC quality check** — Every criterion must be:
- Testable: verifiable with code or observation
- Specific: "returns 200 on success" not "works properly"
- Bounded: clear scope, not open-ended

### 4. Generate prd.json

Immediately after creating prd.md, generate `plans/{slug}/prd.json` from the same internal representation — do NOT re-parse the markdown.

```json
{
  "name": "{slug}",
  "branchName": "feature/{slug}",
  "goal": "High-level goal from PRD",
  "userStories": [
    {
      "id": "task-1",
      "title": "Task title",
      "description": "Detailed description",
      "acceptanceCriteria": ["Criterion 1", "Criterion 2"],
      "status": "pending",
      "passes": false,
      "attemptCount": 0
    }
  ],
  "metadata": {
    "createdAt": "{ISO timestamp}",
    "totalTasks": N,
    "completedTasks": 0,
    "failedTasks": 0
  }
}
```

**Validation before writing**:
- [ ] All tasks have unique IDs (kebab-case: `task-1`, `add-auth-middleware`)
- [ ] All tasks have at least one acceptance criterion
- [ ] All tasks have `status: "pending"`, `attemptCount: 0`
- [ ] `metadata.totalTasks` matches array length
- [ ] `branchName` follows `feature/{slug}` convention

### 5. Initialize working-memory.md

Create `plans/{slug}/working-memory.md` — subagents share cross-task knowledge through this file:

```markdown
# Working Memory — {slug}

Cross-task knowledge. Every developer reads this before starting and updates it after completing.

## Discovered Patterns
*(Add: [Task N] pattern-name: description at file:line)*

## Active Gotchas
*(Add: [Task N] issue the next developer must know about)*

## Shared Utilities Created
*(Add: [Task N] functionName() in path/to/file)*

## Context Corrections
*(Add: [Task N] MISSING_CONTEXT: what was missing and where to find it)*
```

### 6. Present Summary

```
✅ PRD artifacts created

Feature: {slug}
Plan:     plans/{slug}/plan.md
PRD:      plans/{slug}/prd.md  ({N} tasks)
Tasks:    plans/{slug}/prd.json
Memory:   plans/{slug}/working-memory.md

Next: /ship for full automation, or /build to execute directly.
```
