---
name: build
description: Execute an existing PRD autonomously with Orchestrator + Reviewer. Use when you have a PRD and worktree already set up.
---

# Build (Execute PRD)

Autonomously execute a PRD by dispatching subagents for each task, with two distinct roles: **Orchestrator** (senior engineering manager) and **Reviewer** (senior engineer).

**Relationship to /ship**: `/ship` calls this internally after PRD creation and worktree setup. Use `/build` directly when you have a PRD and worktree already set up.

## Prerequisites

- PRD exists at `plans/{slug}/prd.md`
- Task list exists at `plans/{slug}/prd.json`
- Working branch created (worktree recommended)

---

## Phase 0: Orient & Understand

**Read these first (MANDATORY)**:
1. `~/.claude/build/AGENTS.md` — skills index, agent roles
2. `memory/MEMORY.md` — recent decisions and learnings
3. `~/.claude/build/memory/collaboration.md` — personal preferences
4. `plans/{slug}/plan.md` — original plan
5. `plans/{slug}/prd.md` — problem statement, goal, tasks
6. `plans/{slug}/prd.json` — structured task list with dependencies
7. LEARNINGS.md in directories the PRD touches

**Recon Check (MANDATORY)**: For each task, verify it's not already done:
- Check if proposed output files already exist
- Grep for proposed function/class names
- Verify ACs aren't already met by existing code

Output a recon report:
```markdown
## Recon Report
| Task | Status | Evidence |
|------|--------|----------|
| task-1 | PHANTOM | already implemented at src/auth.ts:47 |
| task-2 | CONFIRMED | no existing implementation |
| task-3 | PARTIAL | exists but missing one feature |
```

PHANTOM/PARTIAL tasks → surface to builder before proceeding. Do NOT execute phantom tasks without builder decision.

---

## Phase 1: Pre-Mortem

Identify risks for THIS PRD before dispatching any subagent.

Risk categories:
1. **Context gaps** — What will subagents be missing? Which files/patterns must be in the prompt?
2. **Reimplementation risk** — Any task risks rebuilding something that exists?
3. **Backward compatibility** — Will changes break existing functionality?
4. **Test complexity** — Tricky scenarios to anticipate? Mocking challenges?
5. **Dependency ordering** — Task sequence correct? Any depends-on missing?
6. **Scope drift** — Any AC ambiguous enough to cause over/under-implementation?
7. **Integration risk** — Where do new components touch existing systems?
8. **Documentation debt** — What docs will become stale?

Present risks + mitigations to builder. Wait for approval before proceeding.

---

## Phase 2: Task Execution Loop

For each pending task (in dependency order):

### Step 1: Prepare Context (Orchestrator)

- **Follow AGENTS.md `auto_load` procedure** for the task's target files. Attach loaded PROFILE.md bodies to the developer prompt below (Layer 4).
- Read completed tasks: what's been built, patterns established
- Identify files the subagent should read first (exact paths)
- Check which pre-mortem mitigations apply
- Check LEARNINGS.md in directories the subagent will touch
- Read `plans/{slug}/working-memory.md` for cross-task knowledge

### Step 2: Craft Subagent Prompt

```markdown
You are implementing Task [ID] from the [plan-name] PRD.

**PRD Goal**: [1 sentence]
**Task ID**: [id]
**Title**: [title]
**Description**: [full description from prd.json]

**Acceptance Criteria**:
- [criterion 1]
- [criterion 2]

**Working Memory**: Before starting, read `plans/{slug}/working-memory.md`.
After completing, add entries to relevant sections. If nothing new: write NOTHING_NOVEL — Task N.

**Context - Read These Files First**:
1. `plans/{slug}/working-memory.md` — cross-task knowledge
2. [domain expertise profiles loaded via auto_load — attached above as Layer 4]
3. [specific files relevant to this task] — [why]

**Important Patterns**:
- [Pattern]: See [specific file]

**Reuse & Design**: Use existing services, helpers, and abstractions. Do not reimplement what exists.

**Pre-Mortem Mitigations Applied**:
- [Mitigation 1]

**Quality Gates**: [from project CLAUDE.md QUALITY_GATES]

After implementation:
1. Run quality gates (must pass)
2. Commit: "type(scope): description"
3. Update plans/{slug}/prd.json — set task status "complete", record commitSha

**Post-Task Signals**:
REUSE / MISSING_CONTEXT / NEW_PATTERN / BLOCKER_RESOLVED / NOTHING_NOVEL / OTHER
(at least one — NOTHING_NOVEL is the expected default)

Proceed.
```

### Step 3: Reviewer Pre-Work Sanity Check

Validate the task prompt: AC clear and testable? Context sufficient? Dependencies available?

If **NEEDS REFINEMENT** → refine prompt, then dispatch developer.

### Step 4: Dispatch Developer Subagent

Wait for completion report (Completed, Files Changed, Documentation Updated, Quality Checks, Commit, Signals).

### Step 5: Reviewer Code Review

Technical review, AC review, quality check (DRY/KISS), reuse check, documentation review, quality gates.

**If APPROVED** → proceed.
**If ITERATE** → dispatch developer with structured feedback. Repeat until APPROVED.

### Step 5.5: Documentation Synthesis

Before marking complete — did the developer's report reveal an undocumented pattern or first-use? If yes, send back with targeted note before marking complete.

### Step 6: Update Tracking

Mark task complete in `plans/{slug}/prd.json`.
Output `[DONE:N]` after each task.

---

## Phase 3: Holistic Review & Close

### Holistic Review

1. Does this solve the PRD's problem statement?
2. Anything missing that the task-level ACs didn't cover?
3. Any docs now stale?

### Memory Entry (MANDATORY before final report)

Create `memory/entries/YYYY-MM-DD_{slug}-learnings.md`:
1. Metrics (tasks, success rate, iterations, tests added)
2. Pre-mortem effectiveness (risks materialized?)
3. What worked / what didn't (+/-)
4. Recommendations (continue/stop/start)
5. Follow-ups (refactor items, doc gaps)

Add index line to `memory/MEMORY.md`.

### Final Report

```markdown
# PRD Complete: {slug}

**Status**: ✅ N/N tasks complete
**Quality**: N% first-attempt | N iterations
**Tests**: N passing (+N added)

## Deliverables
- [Feature] — description

## Key Learnings
1. [Learning] — [Evidence]

## Recommendations
- **Continue**: [patterns that worked]
- **Stop**: [patterns to change]
- **Start**: [new practices]

## Refactor Items
- plans/refactor-[name]/plan.md — [summary]
```
