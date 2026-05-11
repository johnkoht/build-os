---
name: plan-to-prd
description: Convert an approved plan into prd.md + prd.json for autonomous execution.
---

# Plan to PRD

Convert an approved plan into a PRD (`prd.md`) and structured task list (`prd.json`) — both in one pass.

## When to Use

- After a plan is approved and you chose "Convert to PRD"
- Ship Phase 2.2: converting plan artifacts to execution-ready PRD

## Prerequisites

- An approved plan is in context or at `dev/work/plans/{slug}/plan.md`

---

## Workflow

### 1. Derive Feature Slug

From the plan title, derive a kebab-case slug (e.g. `user-auth`, `payment-integration`). Use as the directory name under `dev/work/plans/`.

### 2. Create prd.md

Create `dev/work/plans/{slug}/prd.md`:

- **Goal** — 1-2 sentences summarizing what this work achieves
- **Tasks** — One per plan step (group sub-steps where they naturally belong together)
- **Acceptance Criteria** — Explicit, testable criteria per task. If inferred from plan, flag: `<!-- inferred from plan -->`

Each task must have: clear title, description, at least one acceptance criterion.

**AC quality check** — Every criterion must be:
- Testable: verifiable with code or observation
- Specific: "returns 200 on success" not "works properly"
- Bounded: clear scope

### 3. Generate prd.json

Immediately after creating prd.md, generate `dev/work/plans/{slug}/prd.json` from the same internal representation — do NOT re-parse the markdown.

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

### 4. Present Summary

```
✅ PRD artifacts created

Feature: {slug}
PRD:      dev/work/plans/{slug}/prd.md  ({N} tasks)
Tasks:    dev/work/plans/{slug}/prd.json

Next: /ship for full automation, or /build to execute directly.
```
