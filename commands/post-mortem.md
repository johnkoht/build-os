---
name: post-mortem
description: Structured reflection after PRD completion. Extracts learnings, creates memory entry, synthesizes collaboration profile.
---

# Post-Mortem

Systematic reflection after completing a PRD or significant piece of work. Creates a memory entry, updates LEARNINGS.md, and synthesizes patterns.

## When to Use

- After a PRD is complete (called automatically by /build at close-out)
- After a hotfix that revealed significant patterns
- When explicitly requested: "Create the post-mortem"

---

## Workflow

### 1. Gather Materials

Read:
- `dev/work/plans/{slug}/prd.md` — original goals and ACs
- `dev/executions/{slug}/progress.md` — task-by-task log
- `dev/executions/{slug}/prd.json` — final status, attempt counts
- `dev/work/plans/{slug}/pre-mortem.md` — if exists, for risk retrospective
- Developer completion reports from progress.md

### 2. Pre-Mortem Retrospective

For each risk in the pre-mortem (if one exists):

| Risk | Materialized? | Mitigation Applied? | Effective? |
|------|---------------|---------------------|------------|

**Surprises** (not in pre-mortem):
- Positive: What went better than expected?
- Negative: What issues arose that weren't anticipated?

### 3. Extract Learnings

Synthesize:
- **What worked well** — patterns and approaches to repeat
- **What didn't work** — patterns to avoid or change
- **Collaboration patterns** — how did the builder engage? what did they prefer?
- **Context assembly quality** — did subagents have what they needed? what was missing?
- **Reuse vs reimplementation** — were existing abstractions used effectively?

### 4. Create Memory Entry

Create `memory/entries/YYYY-MM-DD_{slug}-learnings.md`:

```markdown
# {slug} — Post-Mortem

Date: {date}
PRD: dev/work/plans/{slug}/prd.md

## Metrics

- Tasks: N total, N complete, N iterations required
- First-attempt success rate: N%
- Tests added: N
- Duration: approximately N hours

## Pre-Mortem Effectiveness

| Risk | Materialized | Mitigation Effective |
|------|-------------|---------------------|
| [risk] | Yes/No | Yes/No/Partial/N/A |

## What Worked

- [+] [Pattern or approach that worked well]
- [+] [Another win]

## What Didn't Work

- [-] [Pattern or approach that caused friction]
- [-] [Another issue]

## Surprises

- [Positive: something that went better than expected]
- [Negative: something unexpected that came up]

## Recommendations

**Continue**: [patterns to keep doing]
**Stop**: [patterns to change or drop]
**Start**: [new practices to adopt]

## Follow-ups

- [ ] [Refactor item: dev/work/plans/refactor-X/plan.md]
- [ ] [Doc gap: update X]
- [ ] [Other action item]
```

Add index line to `memory/MEMORY.md`:
```
- [YYYY-MM-DD] [{slug}](entries/YYYY-MM-DD_{slug}-learnings.md) — [one-line summary]
```

### 5. Update LEARNINGS.md

Based on progress.md and developer signals:
- Were regressions fixed? → LEARNINGS.md entry in affected directory
- First-use patterns discovered? → LEARNINGS.md entry
- Non-obvious design decisions made? → LEARNINGS.md entry

If none: verify and note "No new learnings — verified (reasons: [list])".

### 6. Check Collaboration Profile

If 5+ new learnings about builder preferences were captured, consider updating `~/.claude/build/memory/collaboration.md`:
- New preferences confirmed
- Corrections made
- Patterns in how builder prefers to engage

### 7. Report

```markdown
## Post-Mortem: {slug}

**Memory entry**: memory/entries/YYYY-MM-DD_{slug}-learnings.md ✅
**LEARNINGS.md**: [N files updated / none needed — reason]
**Collaboration profile**: [updated / no changes]

## Key Takeaways

1. [Most important learning]
2. [Second most important]
3. [Third]

## Recommendations
- **Continue**: [top 2-3]
- **Stop**: [top 1-2]
- **Start**: [top 1-2]

## Follow-ups
- [ ] [Action items]
```
