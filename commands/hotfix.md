---
name: hotfix
description: Structured bug fix process with diagnosis, implementation, review, and documentation. Lighter than PRD but ensures quality.
triggers:
  - bug
  - fix
  - broken
  - not working
  - "fix this"
  - regression
---

# Hotfix

A structured process for fixing bugs that prevents "quick fixes" from creating more problems.

## When to Use

- ✅ User reports a bug and asks you to fix it
- ✅ You discover a bug while working
- ✅ Test failures reveal unexpected behavior
- ❌ Feature requests (use plan mode)
- ❌ Refactoring (use plan mode)
- ❌ Multiple unrelated bugs (triage first, then one hotfix per bug)

---

## Phase 1: Diagnose

Before writing any code, understand the problem deeply.

1. **Read the bug report**
   - What's the expected behavior?
   - What's the actual behavior?
   - What are the reproduction steps?

2. **Load relevant expertise** (if available)
   - Check `.build/expertise/{domain}/PROFILE.md` for relevant domains
   - Check LEARNINGS.md in affected directories

3. **Identify**:
   - Root cause hypothesis
   - Affected files
   - Risk areas (what else might break?)
   - Existing test coverage

4. **Present analysis to builder**:
   ```
   ## Bug Analysis

   **Issue**: [one sentence summary]
   **Root cause**: [hypothesis]

   **Affected files**:
   - path/to/file — [why]

   **Risk**: [what else might be affected]
   **Test coverage**: [existing tests? need new ones?]

   **Game plan**:
   1. [step 1]
   2. [step 2]

   Ready to proceed?
   ```

5. **Wait for builder approval** before Phase 2.

---

## Phase 2: Implement

1. **Apply the fix** following your game plan
   - Minimal change that fixes the bug
   - No "while I'm here" scope creep

2. **Add/update tests**
   - Regression test that would have caught this bug
   - Verify fix with quality gates (see project CLAUDE.md for `QUALITY_GATES`)

3. **Commit**: `fix(scope): description`

---

## Phase 3: Review

Dispatch reviewer subagent:

```
Code review for hotfix: [bug summary]

Files changed:
- [list files]

What was fixed:
[description]

Tests added/updated:
[list tests]

Review the implementation. Return APPROVED or ITERATE with structured feedback.
```

- **APPROVED** → proceed to Phase 4
- **ITERATE** → apply feedback, re-run quality gates, re-request review

If subagent not available, self-review using checklist from `~/.claude/build/agents/reviewer.md`.

---

## Phase 4: Close

1. **Update LEARNINGS.md** (if applicable)
   - If this was a regression, first-use pattern, or non-obvious design decision, update the nearest LEARNINGS.md

2. **Report to builder**:
   ```
   ## ✅ Bug Fixed

   **Issue**: [summary]
   **Fix**: [what you changed]
   **Files**: [list]
   **Tests**: [added/updated]
   **Commit**: [sha]
   **LEARNINGS.md**: [updated / not applicable — reason]
   ```

---

## Out of Scope

- **Multi-bug triage** → Prioritize first, then one hotfix per bug
- **Refactor discovery** → Note it and stay focused on the bug
- **Feature changes disguised as bugs** → Route to plan mode
