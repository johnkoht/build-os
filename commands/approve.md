---
name: approve
description: User-only gate. Marks the pending plan approved and prints the next-step menu. Claude cannot invoke this — only the builder typing /approve triggers it.
bucket: planning
disable-model-invocation: true
---

# Approve

Mark the current draft plan as approved and surface the next-step menu. This skill is user-only: it cannot be invoked by Claude automatically. Only the builder explicitly typing `/approve` triggers it.

## Behavior

### 1. Find the plan

Look for `plans/{slug}/plan.md` — the most recently written or discussed plan.

- **Plan exists on disk** → proceed to step 2.
- **Plan exists only in conversation** → save it to `plans/{slug}/plan.md` first using the template from `/plan` (frontmatter: title, slug, status: draft, created: today, has_pre_mortem/has_review/has_prd: false; body: Problem, Goal, Approach, Tasks, Risks; closing line: `On approval → /approve → /ship {slug}`), then proceed to step 2.
- **No plan found** → say: "No pending plan found. Run `/plan` to create one first."

### 2. Check current status

- `status: approved` already → skip to step 4 (idempotent path).
- `status: draft` or `status: planned` → proceed to step 3.

### 3. Approve the plan

Update `plans/{slug}/plan.md` frontmatter: set `status: approved`.

Do not change any other frontmatter fields. Do not modify the plan body.

### 4. Print the next-step menu

```
Plan approved: {slug}

Next steps — pick one:

  /ship            Full workflow (pre-mortem → review → PRD → worktree → build → wrap → merge)
  /ship lite       Lightweight (3-5 steps, low-risk — skips pre-mortem + review)
  /build           Execute directly (use when PRD + worktree already exist)
```

If the plan was already approved (idempotent path), prepend:

```
Plan {slug} is already approved.
```

then print the menu above.

---

## What This Skill Does NOT Do

- Does not implement anything
- Does not invoke `/ship`, `/build`, or any other skill automatically
- Does not modify the plan body, tasks, or any file other than the plan frontmatter
- Does not run if invoked by Claude — only fires when the builder types `/approve`
