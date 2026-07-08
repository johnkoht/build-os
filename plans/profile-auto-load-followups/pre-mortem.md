## Pre-Mortem: profile-auto-load-followups

Lightweight pre-mortem — 3 tasks, all markdown edits, small scope.

### Risk 1: Agent-file rewrite scope creep

**Problem**: Task 2 rewrites 4 agent files (orchestrator, developer, reviewer, product-manager). "Rewrite the Layer 4 mention in active voice" is a vague trigger that could balloon into rewriting adjacent context-stack table entries, roles descriptions, or philosophy blocks. Each file has a slightly different Layer 4 line (verified via grep: orchestrator:30 phrases it "Layer 4 is optional…"; the other three use "When loaded with an expertise profile…"). A rewrite pass that "improves clarity" could touch surrounding lines the PRD didn't sanction.

**Mitigation**: In the PRD Task 2, prescribe **exact line numbers and exact replacement text** for each file. Verified line numbers today: orchestrator.md:30, developer.md:24, reviewer.md:24, product-manager.md:25. Give the developer the literal target and literal replacement — same approach as Task 1 in the parent PRD.

**Verification**: Diff Task 2 vs each of the 4 files should show only the prescribed line replaced. `git diff --stat` post-Task-2 should show ~4 line changes per file (the old line + new line ± minor context), not tens of lines.

---

### Risk 2: build.md:99 change breaks existing PRD build flows

**Problem**: `commands/build.md:99` currently reads `[domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]` — this is inside the developer subagent prompt template. It's a placeholder for an orchestrator to fill. Changing it to `[domain expertise profiles loaded via auto_load — attached above]` means the orchestrator is expected to have run auto_load in Phase 2 Step 1 and attached results above this line. If Phase 2 Step 1 update lands but this line is changed without Phase 2 Step 1 also being changed, the prompt template refers to something the orchestrator never did.

**Mitigation**: Task 1 must land both edits (Phase 2 Step 1 new bullet AND line 99 replacement) atomically. Same commit. Don't split them.

**Verification**: `git log commands/build.md` post-Task-1 should show one commit touching both lines.

---

### Risk 3: hotfix.md:38 line-number drift

**Problem**: Task 3 targets `commands/hotfix.md:38` — the parenthetical that mis-attributes LEARNINGS.md loading to auto_load. But hotfix.md was edited in the parent PRD; line 38 was accurate at merge time. If any subsequent commit or a linter reflow shifted lines, the developer's grep may miss the target.

**Mitigation**: Task 3 should use anchor-string search (`grep "Loads scope-matched PROFILE.md bodies and any LEARNINGS.md"`), not line numbers. Line numbers can be cited as "approximately line 38" but the anchor string is authoritative.

**Verification**: Pre-check `grep -n "Loads scope-matched" commands/hotfix.md` before task starts. Confirm one match.

---

### Risk 4: 4 agent files → single dev task risk

**Problem**: Task 2 touches 4 files with the same edit pattern. If the dev makes one silent error (e.g., wrong replacement text on file 3), the reviewer might miss it because the other 3 look right. This is a copy-paste class error.

**Mitigation**: Task 2 AC must include a per-file grep: for each of the 4 files, confirm the new active-voice string is present AND the old passive-voice string is absent. 8 grep checks total, not 2.

**Verification**: Reviewer runs `grep "auto_load" build/agents/*.md` (should return ≥ 4 lines, one per file) AND `grep "When loaded with an expertise profile" build/agents/*.md` (should return 0 lines).

---

### Risk 5: Downstream doc drift

**Problem**: Do other docs (README.md, project-claude.md template, prior memory entries) reference the old "when loaded with a profile" framing in a way that becomes wrong after Task 2?

**Mitigation**: Quick sanity grep before build: `grep -rn "when loaded with an expertise\|if available.*expertise" build/ commands/ templates/ README.md`. If any hit outside the 4 agent files + build.md:99, add to task list.

**Verification (pre-emptive, done in this pre-mortem)**: Grep confirms only 4 agent files (Task 2 targets) + `commands/build.md:99` (Task 1 target) mention these strings. No collateral doc updates needed.

---

## Summary

Total risks: 5
Categories: scope-drift, atomicity, line-number-drift, copy-paste, doc-consistency
CRITICAL: **none** — small markdown PRD.
HIGH: Risk 1 (prescribe exact line + replacement text for all 4 agent files) and Risk 2 (Task 1 must be atomic across both build.md edits).

**Ready to proceed.** Fold Risks 1, 2, 3, 4 mitigations into PRD task ACs.
