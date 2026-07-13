---
name: hotfix
description: Structured bug fix process with diagnosis, implementation, review, and documentation. Lighter than PRD but ensures quality.
bucket: execution
triggers:
  - bug
  - fix
  - broken
  - not working
  - fix this
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

2. **Load relevant expertise**
   - Resolve affected files from the bug report, then follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]` with those paths as targets. Loads scope-matched PROFILE.md bodies. Separately, read any LEARNINGS.md in affected directories.

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
   - Write a regression test that would have caught this bug

3. **Run quality gates** (required — must pass before proceeding to review)
   - Run the regression test you just wrote; it must pass
   - Run all quality gates listed in the project CLAUDE.md `QUALITY_GATES`
   - Do not proceed to Phase 3 if any gate fails; fix and re-run

4. **Commit**: `fix(scope): description`

---

## Phase 3: Review

**A reviewer subagent is required.** Dispatch it now:

```
Code review for hotfix: [bug summary]

Files changed:
- [list files]

What was fixed:
[description]

Tests added/updated:
[list tests]

Review the implementation. Return APPROVED or ITERATE with structured feedback.

Additionally, decide profile routing using the test from `commands/post-mortem.md` lines 93–98:
- "If I delegate a subagent to a task in this domain tomorrow, would it fail without this loaded up-front?" → PROFILE.md.
- "Would the subagent be fine working on the domain in general but mess up *this specific file* without the note?" → LEARNINGS.md.
- If neither → none.

Reviewer output adds one line:
**Profile routing**: PROFILE.md ({domain}) / LEARNINGS.md ({file}) / none
```

- **APPROVED** → proceed to Phase 4
- **ITERATE** → apply feedback, re-run quality gates, re-request review

⚠️ **Last resort only**: If the subagent infrastructure is genuinely unavailable, you may self-review using the checklist in `~/.claude/build/agents/reviewer.md`. This is not equivalent to an independent reviewer. Note the fallback prominently in your Phase 4 report.

---

## Phase 4: Close

1. **Apply Phase 3 routing decision.**
   - If `PROFILE.md ({domain})`: update `.build/expertise/{domain}/PROFILE.md` with the new invariant, anti-pattern, or architectural rule. Bump `last_validated:` to today's date.
   - If `LEARNINGS.md ({file})`: update the nearest LEARNINGS.md to that file with the regression, first-use pattern, or non-obvious design decision.
   - If `none`: skip.

2. **Optional secondary route.** Both can fire: a fix may produce both an architectural invariant (PROFILE.md) AND a file-local gotcha (LEARNINGS.md). Apply both if Phase 3 flagged both.

3. **Report to builder**:
   ```
   ## ✅ Bug Fixed

   **Issue**: [summary]
   **Fix**: [what you changed]
   **Files**: [list]
   **Tests**: [added/updated]
   **Commit**: [sha]
   **PROFILE.md**: [domains touched / none]
   **LEARNINGS.md**: [updated / not applicable — reason]
   ```

---

## Out of Scope

- **Multi-bug triage** → Prioritize first, then one hotfix per bug
- **Refactor discovery** → Note it and stay focused on the bug
- **Feature changes disguised as bugs** → Route to `/plan`
