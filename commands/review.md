---
name: review
description: Structured second-opinion review for plans, PRDs, or implementations. Tiered checklists, devil's advocate, actionable feedback.
---

# Review

Provide a rigorous quality gate for plans, PRDs, or completed work. Applies tiered checklists, validates acceptance criteria, and outputs actionable refinements.

## When to Use

- "Review this plan"
- "Give me a second opinion"
- "Critique this PRD"
- Before `/approve` on medium+ plans
- When one agent creates work and another should evaluate it

---

## Step 1: Assess Complexity

```
Is this a Plan or PRD?
  ├── No (Implementation) → Full Review
  └── Yes → Check complexity:
       ├── Steps ≤ 3 AND files ≤ 2 AND no architectural decisions? → Quick Review
       └── Otherwise → Full Review
```

| Tier | Steps | Files |
|------|-------|-------|
| Tiny | 1-2 | 1 |
| Small | 3 | 2 |
| Medium | 4-6 | 3+ |
| Large | 7+ | 5+ |

Output: `**Review Path**: Quick / Full` + reason.

---

## Step 2: Load Expertise Profiles

**Quick mode:**
- Resolve target paths from the artifact under review: plan `**File:**` fields, PRD task files, or implementation diff.
- Call AGENTS.md `auto_load` with those paths. Loads scope-matched PROFILE.md bodies (with the 3-profile cap and no-frontmatter fallback).

**Full Review:**
- Same as Quick (call `auto_load`), PLUS load adjacent profiles whose Architecture Map references files in scope. These give cross-domain context that scope-only matching misses.

---

## Step 3: Scan LEARNINGS.md

**Quick mode:**
- Scan LEARNINGS.md files ONLY in directories matching target paths. Confirm the plan/PRD/implementation respects documented invariants and avoids documented pitfalls.

**Full Review:**
- Scan LEARNINGS.md in target-path directories PLUS adjacent directories where related code lives.

---

## Step 4: Identify Review Type

- **Plan** — Proposed approach before execution
- **PRD** — Requirements document before implementation
- **Implementation** — Completed work after execution

---

## Step 5: Apply Checklist

### Plan Review Checklist

| Concern | Question |
|---------|----------|
| Scope | Appropriate? Over-engineered or under-scoped? |
| Risks | Unidentified risks? |
| Dependencies | Task dependencies clear and correctly ordered? |
| Patterns | Follows existing patterns or introduces unnecessary novelty? |
| Backward compatibility | Will this break existing functionality? |
| Completeness | Missing steps or implicit assumptions? |
| Test coverage | Does each code-touching task have test expectations? |
| Quality gates | Does the plan include verification steps? |

### PRD Review Checklist

| Concern | Question |
|---------|----------|
| Problem clarity | Is the problem well-defined? |
| Acceptance criteria | Do ALL criteria pass the AC Validation Rubric? |
| Edge cases | Are edge cases and error states covered? |
| Scope boundaries | Is out-of-scope clearly defined? |
| Test coverage | Are test requirements explicit for each task? |

### Implementation Review Checklist

| Concern | Question |
|---------|----------|
| Intent match | Does the work match the original plan/PRD intent? |
| Acceptance criteria | Are all criteria met? |
| Code quality | Patterns followed, proper error handling? |
| Test coverage | Happy path and edge cases tested? |
| Backward compatibility | Did existing functionality survive? |
| Documentation | LEARNINGS.md updated where needed? |

### AC Validation Rubric

For every acceptance criterion, check:
- **Testable** — Can it be verified with code or observation?
- **Specific** — Not "works properly" but "returns 200 on success, 400 on invalid input"
- **Bounded** — Clear scope, not open-ended

Anti-patterns to flag:
- "Works correctly" (what does correct mean?)
- "Handles errors" (which errors? how?)
- "Is performant" (by what measure?)
- "Is well-tested" (how many? what coverage?)

### Test Coverage Gaps

Flag if a code-touching task has no test expectation:
```
**Test Coverage Gap**: Task 3 modifies `services/payment.ts` but has no test expectation.
Suggestion: Add AC "Unit tests cover successful charge, declined card, and network timeout"
```

---

## Step 6: Devil's Advocate (Mandatory)

After the checklist, actively argue against the work:

- **"If this fails, it will be because..."** — The most likely failure mode. What assumption is wrong?
- **"The worst outcome would be..."** — The highest-stakes risk.

This adversarial thinking surfaces what checklists miss. Do not skip this.

---

## Step 7: Determine Verdict

| Verdict | When |
|---------|------|
| **Approve** | No concerns, all checks pass |
| **Approve with suggestions** | Minor improvements, not blocking |
| **Approve pending pre-mortem** | Medium+ plan without pre-mortem |
| **Revise** | Significant concerns that must be addressed |

**Pre-mortem gating:**
- Tiny/Small: Optional
- Medium: Recommend "Approve pending pre-mortem" if not done
- Large: REQUIRED — cannot Approve without pre-mortem

**Recommended execution track:**
| Complexity | Track |
|------------|-------|
| Tiny/Small | `express` — developer + reviewer, no worktree |
| Medium | `standard` — full /ship flow |
| Large | `full` — /ship with multi-phase if needed |

---

## Step 8: Output

```markdown
## Review: [Artifact Name]

**Type**: Plan / PRD / Implementation
**Review Path**: Quick / Full
**Complexity**: Tiny / Small / Medium / Large
**Recommended Track**: express / standard / full

### Concerns

1. **[Category]**: [Specific concern]
   - Suggestion: [How to address]

### AC Validation Issues (if any)

| Task | AC | Issue | Suggested Fix |
|------|-----|-------|---------------|

### Test Coverage Gaps (if any)

- Task N: [what's missing]

### Strengths

- [What's good about this work]

### Devil's Advocate

**If this fails, it will be because...** [Most likely failure mode]
**The worst outcome would be...** [Highest-stakes risk]

### Verdict

- [ ] Approve
- [ ] Approve with suggestions
- [ ] Approve pending pre-mortem
- [ ] Revise

### Suggested Changes (if Revise or suggestions)

**Change 1**: [Category]
- **What's wrong**: [Specific finding]
- **What to do**: [Concrete instruction]
- **Where to fix**: [File/section]
```

---

## Step 9: Save and Discuss

If in plan mode with a saved plan:
- Save to `dev/work/plans/{slug}/review.md`

Present to builder, discuss concerns, specify what must change before approval.
