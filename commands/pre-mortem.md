---
name: pre-mortem
description: Risk analysis before multi-step work. Identifies risks and creates actionable mitigations. Run before approving medium+ plans.
---

# Pre-Mortem

Run a structured pre-mortem risk analysis before starting multi-step work.

## When to Use

- ✅ Before executing approved plans (3+ steps)
- ✅ Before large refactors (touching many files)
- ✅ Before new systems or integrations
- ❌ Single, well-understood tasks (overkill)

---

## Workflow

### 0. Load Relevant Expertise

Pre-mortem runs before execution — `Edit`/`Write` is not yet imminent. So path resolution happens HERE, then we hand paths to `auto_load`.

**0a. Resolve target paths.** Extract `**File:**` values from each task in the plan's `## Tasks` section. Collect into a target-path list. If a task has no `**File:**` field, infer from the task description (last resort).

**0b. Load profiles via AGENTS.md `auto_load`.** Pass the path list to the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`. Load matching profile bodies — at minimum the Invariants and Anti-Patterns sections.

The loaded profiles inform the risk analysis below. Reference them by domain name in the risks they relate to.

---

### 1. Work Through Risk Categories

For each category, ask: "What could go wrong in THIS work?"

Be specific: "Task B1 needs context from A1-A3 to understand the service interface"
Not generic: "Things might break"

#### Risk Categories

1. **Context gaps** — What will subagents be missing that they need? Which files/patterns must be in the prompt?

2. **Reimplementation risk** — Does any task risk rebuilding something that already exists? Check the codebase for existing implementations.

3. **Backward compatibility** — Will changes break existing functionality? Legacy data formats? Existing API consumers?

4. **Test complexity** — Are there tricky scenarios to anticipate? Mocking challenges? Integration test setup?

5. **Dependency ordering** — Is the task sequence correct? Does any task depend on output from another?

6. **Scope drift** — Is any AC ambiguous enough to cause over/under-implementation? Vague words: "properly", "correctly", "as needed"? Cross-check against loaded PROFILE.md invariants — does any AC violate or extend them?

7. **Integration risk** — Where do new components touch existing systems? What are the seams? Check loaded PROFILE.md Architecture Map — are seams accounted for?

8. **Documentation debt** — What docs will become stale after this work? README, LEARNINGS.md, expertise profiles? If loaded PROFILE.md invariants are being changed, does the profile itself need an update + `last_validated:` bump?

9. **Environment/config risk** — Secrets, environment variables, external services, local-only dependencies?

10. **Performance/scale** — Any changes that could have unintended performance impact at scale?

11. **Rollback safety** — If this goes wrong in production, can it be safely reverted? Data migration concerns?

If a category doesn't apply, skip it — don't force risks.

### 2. Create Mitigations

For each risk:

```markdown
### Risk: [Short descriptive name]

**Problem**: [What could go wrong and why]

**Mitigation**: [Specific, concrete action to prevent it]

**Verification**: [How to check mitigation was applied]
```

### 3. Present to Builder

Output the complete pre-mortem. Ask:
- "Do you see any other risks?"
- "Are these mitigations sufficient?"

Wait for approval before execution begins.

### 4. Save for Reference

If in plan mode: save to `dev/work/plans/{slug}/pre-mortem.md`.

During task execution, the Orchestrator references this: "Which mitigations apply to this task?"

---

## Output Format

```markdown
## Pre-Mortem: [Work Name]

### Risk 1: [Name]

**Problem**: [Description]

**Mitigation**: [Action]

**Verification**: [How to check]

---

### Risk 2: [Name]

**Problem**: [Description]

**Mitigation**: [Action]

**Verification**: [How to check]

---

[continue for all risks]

## Summary

Total risks identified: N
Categories: [list]
CRITICAL risks (must address before proceeding): [list or "none"]

**Ready to proceed with these mitigations?**
```

---

## Tips

**Be concrete**: "List these 3 files to read" beats "provide context"
**Be actionable**: Mitigations you can actually apply in a prompt
**Be verifiable**: Know when a mitigation was successfully applied
**CRITICAL vs HIGH**: CRITICAL = must address before execution; HIGH = should address, won't block
