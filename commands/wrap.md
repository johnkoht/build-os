---
name: wrap
description: Pre-merge verification checklist. Confirms quality gates pass, no uncommitted changes, memory entry exists, LEARNINGS.md updated.
---

# Wrap

Pre-merge verification checklist. Run before merging a feature branch to confirm everything is in order.

## When to Use

- Before merging a feature branch (called by /ship Phase 5.4)
- Anytime you want to verify the current branch is merge-ready
- "Wrap up", "verify before ship", "check before merge"

---

## Checklist

Run each check and report ✅ / ⚠️ / ✗.

### 1. Working Tree

```bash
git status --porcelain
```
- ✅ Empty (clean)
- ✗ Non-empty → commit or stash before proceeding

### 2. Quality Gates

Run the project's quality gates (from project CLAUDE.md `QUALITY_GATES`):
- ✅ Typecheck passes
- ✅ All tests pass
- ✗ Any failure → must fix before merge

### 3. Memory Entry

Check `memory/entries/` for an entry dated today or during this branch's work:
- ✅ Entry exists — `memory/entries/YYYY-MM-DD_{slug}-learnings.md`
- ✅ Entry indexed in `memory/MEMORY.md`
- ⚠️ No entry → create one before merging (see /post-mortem)

### 4. LEARNINGS.md

Check progress.md and developer signals for regressions, first-use patterns, or non-obvious decisions:
- ✅ All regressions have LEARNINGS.md entries
- ✅ First-use patterns documented
- ⚠️ Gap found → update before merging

### 5. PRD Completion

If executing a PRD:
```bash
# Check prd.json — are all tasks complete?
cat dev/executions/{slug}/prd.json | grep '"status"'
```
- ✅ All tasks `"status": "complete"`
- ✗ Pending tasks → complete them or document why they're skipped

### 6. Commit Hygiene

```bash
git log origin/main..HEAD --oneline
```
- ✅ All commits have meaningful messages (not "wip", "fix", "temp")
- ✅ No debug commits or commented-out code
- ⚠️ Cleanup needed → squash or amend before merge

### 7. Branch Sync

```bash
git fetch origin main
git merge-base --is-ancestor origin/main HEAD
```
- ✅ Branch is up to date with main
- ⚠️ Behind main → rebase or merge main first

---

## Output Format

```markdown
## Wrap Check: feature/{slug}

| Check | Status | Notes |
|-------|--------|-------|
| Working tree | ✅ / ✗ | |
| Typecheck | ✅ / ✗ | |
| Tests | ✅ (N passing) / ✗ | |
| Memory entry | ✅ / ⚠️ | path if exists |
| LEARNINGS.md | ✅ / ⚠️ | files updated |
| PRD complete | ✅ / ⚠️ / N/A | |
| Commit hygiene | ✅ / ⚠️ | |
| Branch sync | ✅ / ⚠️ | |

**Status**: ✅ Ready to merge / ⚠️ Review warnings / ✗ Fix required

[Action items if not ready]
```

---

## What Happens Next

- All ✅ → run `/ship` Phase 5.6 (Merge Gate via Gitboss), or merge directly
- Any ⚠️ → your call: review warnings and decide if they're acceptable
- Any ✗ → fix the issue before merging
