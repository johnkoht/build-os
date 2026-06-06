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

### 5. Route Learnings

The split between PROFILE.md and LEARNINGS.md is about **when** the information is needed, not what type it is:

- **`.build/expertise/{domain}/PROFILE.md`** — needed by a subagent *before* touching the domain (context assembly time)
- **`LEARNINGS.md`** (component-local) — needed *while editing this specific file* (working-memory time)

**Routing test:** "If I delegate a subagent to a task in this domain tomorrow, would it fail without this loaded up-front?" → PROFILE.md. "Would the subagent be fine working on the domain in general but mess up *this specific file* without the note?" → LEARNINGS.md co-located with that file.

**Worked examples:**

| Learning | Routes to | Why |
|---|---|---|
| "IBKR client ids 1 and 2 must differ across receiver and strategy" | PROFILE.md (receiver + strategy) | A subagent picking a client id for new code must know this before writing. |
| "The `account_summary` call hangs on connection reset — wrap in 5s timeout" | LEARNINGS.md next to `ibkr.py` | Only matters when editing that file. A subagent doing strategy work doesn't need it. |
| "`get_order_status` returns `not_found` for missing GTC; `None` for unreachable IBKR — these mean different things" | PROFILE.md (strategy) | Invariant. Subagents adding exit conditions must know before writing. |
| "Pytest fixture `ibkr_stub` requires `IB_ENABLED=false` env var" | LEARNINGS.md in `tests/` | Test-file-local gotcha. |

**After routing**, bump `last_validated:` to today's date on any PROFILE.md you updated.

If nothing routes either way: verify and note "No new learnings — verified".

### 6. Report

```markdown
## Post-Mortem: {slug}

**Memory entry**: ✅ created
**PROFILE.md updates**: [domains touched / none]
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
