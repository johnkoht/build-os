---
status: ready
slug: profile-auto-load-followups
branchName: feature/profile-auto-load-followups
parent_prd: profile-auto-load
---

# PRD: Profile Auto-Load Follow-Ups

## Goal

Close the 3 eng-lead-flagged gaps from `profile-auto-load`: wire `/build` orchestrator to explicitly call `auto_load`, flip 4 agent role files from passive "when loaded with a profile" to active self-trigger framing, and fix the `hotfix.md:38` LEARNINGS.md mis-attribution parenthetical.

## Embedded Memory Guidance

1. **Explicit file reading list + exact line numbers** in every subagent prompt.
2. **Pre-mortem mitigations embedded literally** in each task's AC — not just referenced.
3. **Phantom-task grep before every Write** — for each task, run the anchor-string grep to confirm the target text still exists as prescribed.
4. **Sequential execution** — never parallel on same codebase.
5. **Prescribe exact replacement text for compact-format edits** — new learning from parent PRD. Don't say "rewrite in active voice"; give the developer the literal old and new strings.

## Embedded Pre-Mortem Mitigations

- **Risk 1** (agent-file scope creep): exact line + exact replacement per file; ~4-line diff per file expected.
- **Risk 2** (build.md atomicity): both build.md edits (Phase 2 Step 1 bullet AND line 99) in ONE commit.
- **Risk 3** (hotfix line drift): use anchor-string search, not line numbers.
- **Risk 4** (copy-paste class error): AC requires per-file grep, 8 checks (4 old strings absent + 4 new strings present).
- **Risk 5** (doc drift): verified pre-emptively — no other docs reference the old strings.

---

## Tasks

### Task 1: build.md — Phase 2 Step 1 auto_load call + line 99 template

**Files to READ first:**
- `plans/profile-auto-load-followups/plan.md` (Task 1 scope)
- `plans/profile-auto-load-followups/pre-mortem.md` (Risk 2 — atomicity)
- `commands/build.md` FULL FILE. Pay attention to:
  - Phase 2 Step 1 "Prepare Context" bulleted list (~lines 65–70)
  - Line 99 in the developer subagent prompt template
- `build/AGENTS.md` `[Expertise]|auto_load` block (lines ~40–48) — you're wiring `/build` to call this

**Files to WRITE:** `commands/build.md` (single file, both edits atomic in one commit)

**Phantom-task grep (before writing):**
```bash
grep -n "if available.*expertise\|domain expertise profile" /Users/johnkoht/code/build-os-worktrees/profile-auto-load-followups/commands/build.md
```
Expect: exactly one match at line 99 (`2. [domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]`). If zero or multiple, STOP.

**Edit 1a — Phase 2 Step 1 "Prepare Context" list:** Add a new bullet as the FIRST item in the list. Locate the bullet block starting with "- Read completed tasks" and insert BEFORE it:

```
- **Follow AGENTS.md `auto_load` procedure** for the task's target files. Attach loaded PROFILE.md bodies to the developer prompt below (Layer 4).
```

**Edit 1b — Line 99 template placeholder:** Find the exact string `2. [domain expertise profile if available: .build/expertise/{domain}/PROFILE.md]` and replace with:
```
2. [domain expertise profiles loaded via auto_load — attached above as Layer 4]
```

**AC:**
1. `grep -c "auto_load" commands/build.md` returns ≥ 2.
2. `grep "if available.*expertise" commands/build.md` returns 0 lines.
3. `grep "loaded via auto_load" commands/build.md` returns 1 line.
4. Phase 2 Step 1 "Prepare Context" bulleted list has `**Follow AGENTS.md \`auto_load\` procedure**` as its first bullet.
5. **Atomicity**: `git log -1 --stat commands/build.md` shows both edits in the SAME commit (not two commits).

**Commit message:**
```
feat(build): wire /build orchestrator to call AGENTS.md auto_load

Phase 2 Step 1 now explicitly calls auto_load for target files.
Developer subagent prompt template (line 99) references the loaded
profiles instead of the old passive "if available" bracket.
```

---

### Task 2: Agent role files — active self-trigger framing

**Files to READ first:**
- `plans/profile-auto-load-followups/plan.md` (Task 2 scope)
- `plans/profile-auto-load-followups/pre-mortem.md` (Risks 1 and 4)
- All 4 agent files (before editing any):
  - `build/agents/orchestrator.md` — verified line 30 today
  - `build/agents/developer.md` — verified line 24 today
  - `build/agents/reviewer.md` — verified line 24 today
  - `build/agents/product-manager.md` — verified line 25 today

**Files to WRITE:** 4 files, edited sequentially in one commit.

**Phantom-task grep (before writing):**
```bash
grep -n "When loaded with an expertise\|Layer 4 is optional" /Users/johnkoht/code/build-os-worktrees/profile-auto-load-followups/build/agents/*.md
```
Expect: exactly 4 matches (one per file). If not 4, STOP and report which files are missing.

**Prescribed edits (exact old → new per file):**

**`build/agents/orchestrator.md` line 30:**
- OLD: `Layer 4 is optional — not all projects have expertise profiles. When they exist, include them for subagents touching that domain. They provide architecture maps, invariants, and anti-patterns that prevent subagents from discovering things from scratch.`
- NEW: `Before dispatching a subagent, follow AGENTS.md \`auto_load\` for the task's target files; attach any loaded profile bodies as the subagent's Layer 4. Not all projects have expertise profiles (\`auto_load\` skips silently if none exist); when they do, they provide architecture maps, invariants, and anti-patterns that prevent subagents from discovering things from scratch.`

**`build/agents/developer.md` line 24:**
- OLD: `When loaded with an expertise profile (Layer 4), follow its invariants, read its required files, and respect its component relationships.`
- NEW: `Before touching code, follow AGENTS.md \`auto_load\` for the files you will edit. Any loaded profile (Layer 4) supplies invariants to follow, required files to read, and component relationships to respect.`

**`build/agents/reviewer.md` line 24:**
- OLD: `When loaded with an expertise profile (Layer 4), use it to verify the developer's changes respect domain invariants and architectural patterns.`
- NEW: `Before reviewing, follow AGENTS.md \`auto_load\` for the diff's touched files. Any loaded profile (Layer 4) is the reference for verifying the developer's changes respect domain invariants and architectural patterns.`

**`build/agents/product-manager.md` line 25:**
- OLD: `When loaded with an expertise profile (Layer 4), use it to understand what's feasible, what's risky, and how components relate — so you can shape plans that respect the architecture.`
- NEW: `Before shaping technical scope, follow AGENTS.md \`auto_load\` for the plan's target files. Any loaded profile (Layer 4) grounds what's feasible, what's risky, and how components relate — so plans respect the architecture.`

**AC:** All 8 grep checks must pass.

1. `grep "When loaded with an expertise" build/agents/*.md` returns **0 lines** (all 4 passive-voice strings removed).
2. `grep "Layer 4 is optional" build/agents/orchestrator.md` returns **0 lines**.
3. `grep -l "auto_load" build/agents/orchestrator.md build/agents/developer.md build/agents/reviewer.md build/agents/product-manager.md` returns **4 lines** (one per file).
4. `grep "Before dispatching a subagent" build/agents/orchestrator.md` returns 1 line.
5. `grep "Before touching code" build/agents/developer.md` returns 1 line.
6. `grep "Before reviewing" build/agents/reviewer.md` returns 1 line.
7. `grep "Before shaping technical scope" build/agents/product-manager.md` returns 1 line.
8. `git diff --stat build/agents/` post-Task-2 shows ≤ 4 line changes per file (i.e., surgical, no scope creep).

**Commit message:**
```
feat(agents): flip role files to active auto_load self-trigger framing

Orchestrator/developer/reviewer/product-manager now describe
triggering auto_load themselves before dispatch/edit/review/shape,
instead of the old passive "when loaded with a profile" framing.
Aligns role docs with the actual auto_load flow.
```

---

### Task 3: hotfix.md — split parenthetical, precise attribution

**Files to READ first:**
- `plans/profile-auto-load-followups/plan.md` (Task 3 scope)
- `commands/hotfix.md` — full file (recent-parent PRD landed edits; line numbers may have shifted)

**Files to WRITE:** `commands/hotfix.md`

**Phantom-task grep (before writing — use anchor string, NOT line number):**
```bash
grep -n "Loads scope-matched PROFILE.md bodies and any LEARNINGS.md" /Users/johnkoht/code/build-os-worktrees/profile-auto-load-followups/commands/hotfix.md
```
Expect: exactly 1 match. If 0 or >1, STOP.

**Edit — split the parenthetical:**
- OLD: `Resolve affected files from the bug report, then follow the \`auto_load\` procedure in \`~/.claude/build/AGENTS.md\` \`[Expertise]\` with those paths as targets. (Loads scope-matched PROFILE.md bodies and any LEARNINGS.md in affected directories.)`
- NEW: `Resolve affected files from the bug report, then follow the \`auto_load\` procedure in \`~/.claude/build/AGENTS.md\` \`[Expertise]\` with those paths as targets. Loads scope-matched PROFILE.md bodies. Separately, read any LEARNINGS.md in affected directories.`

**AC:**
1. `grep "Loads scope-matched PROFILE.md bodies and any LEARNINGS.md" commands/hotfix.md` returns **0 lines**.
2. `grep "Loads scope-matched PROFILE.md bodies. Separately, read any LEARNINGS.md" commands/hotfix.md` returns **1 line**.
3. No other section of hotfix.md changed (`git diff --stat commands/hotfix.md` shows ~2 line changes: 1 removed + 1 added).

**Commit message:**
```
fix(hotfix): split auto_load parenthetical, correct LEARNINGS.md attribution

auto_load loads profile bodies only. LEARNINGS.md is a separate read
step. Prior wording conflated the two.
```

---

## Verification (all tasks complete)

```bash
grep -c "auto_load" commands/build.md                    # ≥ 2
grep "When loaded with an expertise" build/agents/*.md   # 0 lines
grep -l "auto_load" build/agents/*.md | wc -l            # 4
grep "Loads scope-matched PROFILE.md bodies. Separately" commands/hotfix.md  # 1 line
```

## Out of Scope

- Hotfix Phase 3 output-line format brittleness (`{file}` containing `/`, `/ none` ambiguity when both fire). Defer to a separate plan if it proves problematic.
- Adding profiles to build-os itself (dogfooding). Larger scope decision.
- Runtime enforcement of `auto_load` trigger. Requires a Claude Code hook, not a build-os change.
