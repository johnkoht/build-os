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
| Expertise profiles | scope-filtered drift + stale check | up to date, N/A, or ⚠️ |
| PRD complete | check `plans/{slug}/prd.json` | all tasks `"complete"` |
| Commit hygiene | `git log origin/main..HEAD --oneline` | no "wip"/"temp" commits |
| Branch sync | `git fetch && git merge-base --is-ancestor origin/main HEAD` | up to date |

---

### Expertise profile check

For each `.build/expertise/*/PROFILE.md`:

1. **Scope match.** Read the profile's `scope` frontmatter (list of git-pathspec globs). Compute the branch diff: `git diff --name-only origin/main...HEAD`. If no changed path matches any scope glob → **N/A**, skip the rest.
2. **Drift check** (only if scope matched). Compare the diff against the profile's Architecture Map, Required Reading, and Anti-Patterns sections. Emit ⚠️ if any of:
   - A new file appeared in the scope that isn't listed in Architecture Map
   - An invariant changed (auth flow, ordering rule, lifecycle state machine)
   - A new anti-pattern was discovered (the user should add a row)
   - A required-reading file was renamed or moved
3. **Staleness check.** If `last_validated` is missing OR older than 90 days OR there have been >50 commits in the scope since `last_validated` → ⚠️ "validate-and-refresh the profile."
4. **Missing frontmatter.** If the PROFILE.md lacks `scope`/`last_validated` frontmatter at all → ⚠️ "add frontmatter (one-time migration)." Suggest running `/build-os-retrofit` in migration mode.

After updating any profile in response to a ⚠️, bump its `last_validated:` to today's date.

If a touched domain has no PROFILE.md → ⚠️ "consider `/build-os-retrofit` to bootstrap."

Severity is always ⚠️ (warning, builder's call) — never ✗. False positives need to be cheap to dismiss.

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
| Expertise profiles | ✅/⚠️/N/A | domains touched + drift/staleness findings |
| PRD complete | ✅/⚠️/N/A | |
| Commit hygiene | ✅/⚠️ | |
| Branch sync | ✅/⚠️ | |

**Status**: ✅ Ready / ⚠️ Warnings / ✗ Fix required
```

- All ✅ → proceed to Gitboss merge gate
- ⚠️ → your call — review and decide if acceptable
- ✗ → fix before merging
