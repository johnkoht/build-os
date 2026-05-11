---
name: post-mortem
description: Structured reflection after PRD completion. Extracts learnings, creates memory entry, synthesizes collaboration patterns.
---

# Post-Mortem

Systematic reflection after completing a PRD or significant piece of work.

## When to Use

- After a PRD is complete (called automatically by /build at close-out)
- After a hotfix that revealed significant patterns
- Explicitly: "Create the post-mortem" or "Extract learnings"

---

## Workflow

### 1. Gather Materials

Read:
- `plans/{slug}/prd.md` — original goals and ACs
- `plans/{slug}/prd.json` — final status, attempt counts
- `plans/{slug}/working-memory.md` — cross-task discoveries
- `plans/{slug}/pre-mortem.md` — if exists, for risk retrospective
- Developer completion signals from working-memory.md

### 2. Pre-Mortem Retrospective

| Risk | Materialized? | Mitigation Applied? | Effective? |
|------|---------------|---------------------|------------|

**Surprises** (not in pre-mortem):
- Positive: What went better than expected?
- Negative: What issues arose unexpectedly?

### 3. Extract Learnings

- **What worked** — patterns to repeat
- **What didn't** — patterns to avoid
- **Context assembly quality** — did subagents have what they needed?
- **Reuse vs reimplementation** — were existing abstractions used effectively?

### 4. Create Memory Entry

Create `memory/entries/YYYY-MM-DD_{slug}-learnings.md`:

```markdown
# {slug} — Post-Mortem

Date: {date}

## Metrics

- Tasks: N total, N complete, N iterations
- First-attempt success: N%
- Tests added: N

## Pre-Mortem Effectiveness

| Risk | Materialized | Mitigation Effective |
|------|-------------|---------------------|

## What Worked / Didn't

- [+] [Pattern that worked]
- [-] [Pattern that caused friction]

## Surprises

- [Positive or negative surprise]

## Recommendations

**Continue**: [patterns to keep]
**Stop**: [patterns to drop]
**Start**: [new practices]

## Follow-ups

- [ ] [Refactor item: plans/refactor-X/plan.md]
- [ ] [Doc gap]
```

Add to `memory/MEMORY.md`:
```
- [YYYY-MM-DD] [{slug}](entries/YYYY-MM-DD_{slug}-learnings.md) — [one-line summary]
```

### 5. Update LEARNINGS.md

Based on working-memory.md and developer signals:
- Regressions fixed → LEARNINGS.md in affected directory
- First-use patterns → LEARNINGS.md entry
- Non-obvious decisions → LEARNINGS.md entry

If none: verify and note "No new learnings — verified".

### 6. Report

```markdown
## Post-Mortem: {slug}

**Memory entry**: ✅ created
**LEARNINGS.md**: [N files updated / none needed]

## Key Takeaways
1. [Most important learning]
2. [Second]

## Recommendations
- **Continue**: [top 2-3]
- **Stop**: [top 1-2]
- **Start**: [top 1-2]

## Follow-ups
- [ ] [Action items]
```
