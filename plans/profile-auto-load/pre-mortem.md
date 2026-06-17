## Pre-Mortem: profile-auto-load

### Risk 1: Profile load triggers on trivial work, bloats every fresh conversation

**Problem**: "Before non-trivial code work" is undefined. If interpreted broadly (any Edit/Write call), then trivial fixes — typo correction, renaming a const, changing a log message — will load full PROFILE.md bodies. Anchor has 4 profiles averaging ~6KB each → ~24KB of context burned on a one-line change. Worse, this happens silently on every fresh conversation, so the user can't opt out without editing AGENTS.md.

**Mitigation**: In Task 1, define the trigger crisply in AGENTS.md. Suggested phrasing: "Load when about to make code changes that span multiple files, change behavior, or touch unfamiliar code. Skip for single-line edits, typo fixes, or renames where the user is explicit about what to change." Also: load only the **scope-matched** profile body, not all profiles in the directory. Frontmatter scan is cheap (a few hundred bytes per profile); body load is gated by scope match.

**Verification**: `grep -A 3 "auto_load" build/AGENTS.md` shows the trigger definition. Manual smoke test: open a fresh session in anchor, ask "fix the typo on line 42 of api/src/app.ts" — confirm no profile body was loaded (only frontmatter scan).

---

### Risk 2: Projects without `.build/expertise/` directory crash the scan

**Problem**: The auto-load procedure assumes `.build/expertise/*/PROFILE.md` exists. Projects that haven't been retrofitted (or new projects before `/new-project` finishes) have no directory. A naive `ls .build/expertise/` or `find` will error or surface a confusing message.

**Mitigation**: In Task 1, specify the scan as: "If `.build/expertise/` does not exist, skip silently. If it exists but is empty, skip silently. Surface nothing to the builder either way." Add explicit graceful-degrade language to AGENTS.md.

**Verification**: Run the scan procedure mentally in a project with no `.build/` directory at all — no error message, no warning, just silently proceeds.

---

### Risk 3: Profiles without `scope:` frontmatter are silently ignored, defeating the whole point

**Problem**: The anchor profiles (May 11) have NO frontmatter at all. They predate the lifecycle feature. A strict "match scope glob" implementation will skip them entirely — exactly the profiles that most need to be loaded. The user thinks auto-load works; meanwhile stale-but-useful profiles are invisible.

**Mitigation**: In Task 1, specify fallback behavior: "If a PROFILE.md has no `scope:` frontmatter, load it whenever ANY work touches the project (treat as project-wide scope) AND surface a one-line ⚠️ note suggesting `/build-os-retrofit` to add scope. Don't skip it." This matches `/wrap`'s migration-warning pattern.

**Verification**: Mental run-through in anchor (which has no-frontmatter profiles): all 4 would be loaded for any work, with a one-line ⚠️.

---

### Risk 4: AGENTS.md change cascades inconsistently into skills

**Problem**: AGENTS.md update is the meta-change. If skills (`/hotfix`, `/pre-mortem`, `/plan-to-prd`, `/review`) still describe their own profile-load procedure, you get drift: AGENTS.md says "scan and load by default," skill says "load if Full Review." Builder ends up unsure which rule wins.

**Mitigation**: In Tasks 2–5, each skill should **reference** AGENTS.md's procedure rather than redefine it. Phrasing: "Before [step X], follow AGENTS.md's expertise auto-load procedure." Skill-specific notes only when the skill needs something different (e.g., `/review` Full Review = adjacent profiles too, not just scope-matched).

**Verification**: `grep -l "auto_load\|expertise auto-load\|AGENTS.md" commands/hotfix.md commands/pre-mortem.md commands/plan-to-prd.md commands/review.md` returns all four files. None of them redefine the scan procedure independently.

---

### Risk 5: `/hotfix` Phase 4 routing test diverges from `/post-mortem`'s

**Problem**: Task 2 asks `/hotfix` Phase 4 to mirror `/post-mortem`'s routing test ("would a subagent fail without this loaded up-front?" → PROFILE.md). If the wording drifts even slightly between the two skills, builders get inconsistent routing decisions across the lifecycle.

**Mitigation**: Reuse the exact routing test from `commands/post-mortem.md` lines 93–98 in `commands/hotfix.md` Phase 4 — copy the wording verbatim including the worked examples table. Better: reference post-mortem's routing test by name and don't duplicate.

**Verification**: `diff <(grep -A 5 "routing test" commands/hotfix.md) <(grep -A 5 "routing test" commands/post-mortem.md)` shows the same test wording (or hotfix.md references post-mortem.md).

---

### Risk 6: `/new-project` template instruction doesn't actually fire for retrofitted projects

**Problem**: Task 6 updates `templates/project-claude.md` for new projects. But existing projects (anchor, others) have their own CLAUDE.md — the template change doesn't reach them. If the AGENTS.md change handles auto-load globally, that's fine. But if any skill relies on the project's CLAUDE.md to know to scan, retrofitted projects miss out.

**Mitigation**: Make AGENTS.md the source of truth for the scan procedure. The project CLAUDE.md scan-on-start line is reinforcement and a documentation hook for builders reading the project's own CLAUDE.md — but the actual behavior is driven by AGENTS.md which all projects read. Note this division of responsibility in Task 1's AC.

**Verification**: Manually trace what triggers auto-load in anchor (which won't get the template change): AGENTS.md scan triggers it. Confirmed via `~/.claude/CLAUDE.md` → `~/.claude/build/AGENTS.md` chain.

---

### Risk 7: Profile load happens too late — after the subagent already started work

**Problem**: AGENTS.md says "before non-trivial code work." But the main agent often dispatches a subagent for analysis BEFORE deciding work is needed. If profile load is gated to "before code work," the analysis phase misses it. Conversely, if loaded earlier, every analysis question burns tokens.

**Mitigation**: Time the load to **when the file paths are known**. For ad-hoc work: when the main agent identifies files it's about to Edit/Write. For skills (`/hotfix` Phase 1, `/pre-mortem` Step 0): when the plan/PRD lists target files. Explicit language in AGENTS.md: "Load when target file paths are known, not before."

**Verification**: AGENTS.md auto_load procedure mentions "when target file paths are known." Skill-level docs in Tasks 2–5 describe the same timing.

---

## Summary

Total risks identified: 7
Categories: context-gaps, backward-compat, scope-drift, integration, documentation
CRITICAL risks (must address before proceeding): **none** — all are addressable inside the existing tasks
HIGH risks (should fold into task ACs): Risk 1 (trigger crispness), Risk 3 (no-frontmatter fallback), Risk 4 (skill consistency)

**Recommended task AC additions before proceeding:**
- Task 1 AC: Add "trigger is crisp," "no-directory graceful skip," "no-frontmatter fallback with ⚠️," "timing tied to known file paths."
- Tasks 2–5 ACs: Each skill references AGENTS.md's procedure rather than redefining.
- Task 2 AC: Verbatim or referenced routing test from `/post-mortem`.

**Ready to proceed with these mitigations folded into the task ACs.**
