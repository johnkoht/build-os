---
name: plan
description: Plan-mode replacement. Explores read-only first, discusses trade-offs, writes a draft plan under plans/, then presents keep-editing / approve options. Never auto-executes.
bucket: planning
---

# Plan

The plan-mode replacement for build-os projects. Explore first, discuss trade-offs, then write a saved draft. End every round with a clear decision point for the builder. Never implements — planning only.

## When to Use

- New feature or change with 3+ steps or architectural decisions
- Any time you would reach for native plan mode in a build-os project
- When the builder says "let's plan" or "plan this out"

## What This Skill Does NOT Do

- Does NOT implement anything
- Does NOT enter native plan mode (`/plan mode on` or similar)
- Does NOT auto-execute after presenting the plan
- Does NOT write to any file except `plans/{slug}/plan.md`

---

## Phase 1: Explore (Read-Only)

Before writing a single line of plan, explore and discuss.

1. **Read relevant code and context**
   - Scan affected files, existing patterns, interfaces, dependencies
   - Read `memory/MEMORY.md` and `~/.claude/build/memory/collaboration.md`
   - Load any relevant LEARNINGS.md files in scope

2. **Surface trade-offs with the builder**
   - What are the viable approaches?
   - What are the non-obvious constraints or risks?
   - What can be deferred vs. what must be right now?
   - Is there a simpler/lighter version that achieves the goal?

3. **Reach shape agreement**
   - Present options clearly. Let the builder decide.
   - Do not proceed to Phase 2 until the approach is agreed.

---

## Phase 2: Write the Plan

Once the shape is clear:

### Derive the slug

Slug = kebab-case of plan title. Examples: `user-auth`, `payment-integration`, `protocol-guardrails`.

### Write `plans/{slug}/plan.md`

```markdown
---
title: {Plan Title}
slug: {slug}
status: draft
created: {YYYY-MM-DD}
has_pre_mortem: false
has_review: false
has_prd: false
---

# {Plan Title}

## Problem

[What is broken or missing? Why does this matter?]

## Goal

[What does done look like? 1-3 sentences.]

## Approach

[High-level strategy. Why this approach over alternatives?]

## Tasks

1. [Task title] — [brief description]
2. [Task title] — [brief description]
...

## Risks

- [Risk]: [mitigation or acceptance]
- [Risk]: [mitigation or acceptance]

On approval → /approve → /ship {slug}
```

The final line `On approval → /approve → /ship {slug}` is required — do not omit it.

---

## Phase 3: Present and Wait

After writing (or updating) the plan, present it to the builder and end with exactly:

```
---
1. keep editing
2. /approve
```

Then STOP. Wait for the builder's response. Do not proceed to implementation. Do not suggest next steps beyond these two options.

---

## Iteration

If the builder chooses `1. keep editing` (or provides feedback without explicitly approving):

1. Apply the changes to `plans/{slug}/plan.md`
2. Re-present the updated plan
3. End again with the two options above

Re-invoking `/plan` on an existing draft updates it in place — frontmatter `status` stays `draft`, `created` date is preserved.

---

## What Happens After /approve

The builder types `/approve`. That skill:
1. Sets `status: approved` in `plans/{slug}/plan.md`
2. Prints the next-step menu: `/ship` | `/ship lite` | `/build`

Your job ends when you present the two options. You do not call `/approve`.
