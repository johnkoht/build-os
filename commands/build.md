---
name: build
description: Execute an existing PRD autonomously with Orchestrator + Reviewer. Use when you have a PRD and worktree already set up.
---

# Build (Execute PRD)

Autonomously execute a PRD by dispatching subagents for each task, with two distinct roles: **Orchestrator** (senior engineering manager) and **Reviewer** (senior engineer).

**Relationship to /ship**: `/ship` calls this internally after PRD creation and worktree setup. Use `/build` directly when you have a PRD and worktree already set up.

## Prerequisites

- PRD exists at `dev/work/plans/{slug}/prd.md`
- Task list exists at `dev/work/plans/{slug}/prd.json`
- Working branch created (worktree recommended)

---

## Phase 0: Orient & Understand the PRD

**Read these first (MANDATORY)**:
1. `~/.claude/build/AGENTS.md` — skills index, conventions
2. `memory/MEMORY.md` — recent decisions and learnings
3. `~/.claude/build/memory/collaboration.md` — personal preferences
4. LEARNINGS.md in directories the PRD touches

**Then read the PRD**:
- `dev/work/plans/{slug}/prd.md` — problem statement, goal, tasks
- `dev/work/plans/{slug}/prd.json` — structured task list with dependencies

**Recon Check (MANDATORY)**: For each task, verify it's not already done:
```bash
# Check if proposed output files exist
# Grep for proposed function/class names
# Verify ACs are not already met
```

Output a recon report:
```markdown
## Recon Report
| Task | Status | Evidence |
|------|--------|----------|
| task-1 | PHANTOM | already implemented at src/auth.ts:47 |
| task-2 | CONFIRMED | no existing implementation |
| task-3 | PARTIAL | exists but missing --flag option |
```

PHANTOM/PARTIAL tasks → surface to builder before proceeding.

**Initialize execution state**:
- `dev/executions/{slug}/status.json` — tracking state
- `dev/executions/{slug}/progress.md` — task log
- `dev/executions/{slug}/working-memory.md` — cross-task knowledge

---

## Phase 1: Pre-Mortem

Before dispatching any subagent, identify risks for THIS PRD.

Risk categories to work through:
1. **Context gaps** — What will subagents be missing that they need?
2. **Reimplementation risk** — Does any task risk rebuilding something that exists?
3. **Backward compatibility** — Will changes break existing functionality?
4. **Test complexity** — Are there tricky test scenarios to anticipate?
5. **Dependency ordering** — Are task dependencies correctly sequenced?
6. **Scope drift** — Is any AC ambiguous enough to cause over/under-implementation?
7. **Integration risk** — Where do new components touch existing systems?
8. **Documentation debt** — What docs will become stale?

Present risks + mitigations to builder. Wait for approval before proceeding.

---

## Phase 2: Task Execution Loop

For each pending task (in dependency order):

### Step 1: Prepare Context (Orchestrator)

- Read prior completed tasks: what's been built, patterns established
- Identify files the subagent should read first (exact paths)
- Check which pre-mortem mitigations apply to this task
- Check LEARNINGS.md in directories the subagent will touch
- Read `working-memory.md` for cross-task knowledge

### Step 2: Craft Subagent Prompt

Use this template:

```markdown
You are implementing Task [ID] from the [plan-name] PRD.

**PRD Goal**: [1 sentence from PRD]
**Task ID**: [id]
**Title**: [title]
**Description**: [full description from prd.json]

**Acceptance Criteria**:
- [criterion 1]
- [criterion 2]

**Execution State Path**: dev/executions/{slug}/

**Working Memory**: Before starting, read `dev/executions/{slug}/working-memory.md`.
After completing, add entries to relevant sections (Discovered Patterns, Active Gotchas,
Shared Utilities Created, Context Corrections). If nothing new: write NOTHING_NOVEL — Task N.

**Context - Read These Files First**:
1. `dev/executions/{slug}/working-memory.md` — cross-task knowledge from prior tasks
2. [domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]
3. [file] — [why it's relevant]
...

**Important Patterns**:
- [Pattern]: Reference [specific file that shows this pattern]

**Reuse & Design**:
- Use existing services, helpers, and abstractions. Do not reimplement what already exists.
- Apply DRY and KISS. Prefer existing modules over new ones when they fit.

**Pre-Mortem Mitigations Applied**:
- [Mitigation 1 from pre-mortem]

**Quality Gates**: [from project CLAUDE.md QUALITY_GATES]

After implementation:
1. Run quality gates (must pass)
2. Commit: "[type]([scope]): [description]"
3. Update dev/executions/{slug}/prd.json — set status "complete", record commitSha
4. Append to dev/executions/{slug}/progress.md

**Post-Task Signals** (include in completion report):
REUSE: [what you reused]
MISSING_CONTEXT: [what you had to discover]
NEW_PATTERN: [pattern you created]
BLOCKER_RESOLVED: [decision that unblocked you]
NOTHING_NOVEL: [no surprises]
OTHER: [anything else]

Proceed with implementation.
```

### Step 3: Reviewer Pre-Work Sanity Check

Dispatch reviewer to validate the task prompt before developer starts:
- Task description and AC are clear and unambiguous
- Context is sufficient (files listed, patterns pointed to)
- Dependencies from prior tasks are available

If **NEEDS REFINEMENT**, refine prompt before dispatching developer.

### Step 4: Dispatch Developer

Wait for completion report (Completed, Files Changed, Documentation Updated, Quality Checks, Commit, Signals).

### Step 5: Reviewer Code Review

After developer completes, dispatch reviewer:
- Technical review (no `any`, error handling, tests, backward compat)
- AC review (meets criteria, no scope drift)
- Quality check (DRY, KISS, best solution)
- Reuse check (no reimplementation of existing code)
- Documentation review (LEARNINGS.md updated if regression/first-use/non-obvious decision)
- Quality gates passing

**If APPROVED** → proceed to step 6.
**If ITERATE** → dispatch developer again with structured feedback. Repeat until APPROVED.

### Step 5.5: Documentation Synthesis

Before marking complete, scan developer's report for doc gaps:
- Did they mention a new pattern in reflection but not in Documentation Updated?
- First use of something that isn't documented?

If gap found, send back: "Your reflection mentioned X. Add it to [LEARNINGS.md path] before I mark complete."

### Step 6: Update Tracking

Mark task complete in `dev/executions/{slug}/prd.json` (`status: "complete"`).
Update `dev/executions/{slug}/status.json`.
Report `[DONE:N]` after each task.

---

## Phase 3: Holistic Review & Close

After all tasks complete, the Orchestrator reviews the whole:

1. **Does this solve the problem?** Re-read the PRD problem statement and success criteria.
2. **Is anything missing?** Gaps the task-level AC didn't cover but the PRD implies?
3. **Documentation check**: Are any docs now stale?
4. **Learnings**: What should be captured for future work?

### Memory Entry (MANDATORY before final report)

Create `memory/entries/YYYY-MM-DD_{slug}-learnings.md`:
1. Metrics (tasks, success rate, iterations, tests added)
2. Pre-mortem effectiveness (risks materialized? mitigations effective?)
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
**Pre-mortem**: N/N risks materialized

## Deliverables
- [Feature 1] — description
- [Feature 2] — description

## Key Learnings
1. [Learning] — [Evidence]

## Pre-Mortem Review
[Risk | Materialized | Effective]

## Recommendations
- **Continue**: [patterns that worked]
- **Stop**: [patterns to change]
- **Start**: [new practices to adopt]

## Refactor Items
- dev/work/plans/refactor-[name]/plan.md — [summary]
```
