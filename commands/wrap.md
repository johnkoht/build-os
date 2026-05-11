---
name: wrap
description: Pre-merge verification checklist. Quality gates, working tree, memory entry, LEARNINGS.md.
---

# Wrap

Pre-merge verification. Run before merging or as the final step in /ship Phase 5.4.

---

## Checklist

| Check | Command | Pass |
|-------|---------|------|
| Working tree | `git status --porcelain` | empty |
| Quality gates | from project `QUALITY_GATES` | all pass |
| Memory entry | `ls memory/entries/` | entry for this work exists |
| MEMORY.md indexed | check memory/MEMORY.md | entry listed |
| LEARNINGS.md | check working-memory.md signals | regressions/first-use documented |
| PRD complete | check `plans/{slug}/prd.json` | all tasks `"complete"` |
| Commit hygiene | `git log origin/main..HEAD --oneline` | no "wip"/"temp" commits |
| Branch sync | `git fetch && git merge-base --is-ancestor origin/main HEAD` | up to date |

---

## Output

```markdown
## Wrap: feature/{slug}

| Check | Status | Notes |
|-------|--------|-------|
| Working tree | ✅/✗ | |
| Typecheck | ✅/✗ | |
| Tests | ✅ (N)/✗ | |
| Memory entry | ✅/⚠️ | path |
| MEMORY.md | ✅/⚠️ | |
| LEARNINGS.md | ✅/⚠️ | files updated |
| PRD complete | ✅/⚠️/N/A | |
| Commit hygiene | ✅/⚠️ | |
| Branch sync | ✅/⚠️ | |

**Status**: ✅ Ready / ⚠️ Warnings / ✗ Fix required
```

- All ✅ → proceed to Gitboss merge gate
- ⚠️ → your call — review and decide if acceptable
- ✗ → fix before merging
