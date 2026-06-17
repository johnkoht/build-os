## Review: Profile Auto-Load — Close the Expertise Lifecycle Gaps

**Type**: Plan
**Review Path**: Full
**Complexity**: Medium
**Recommended Track**: standard

---

### Concerns

1. **Trigger Ambiguity — The `auto_load` trigger is not crisply implementable**
   - The plan's Task 1 describes the trigger as "before code work that spans multiple files, changes behavior, or touches unfamiliar code." "Changes behavior" is model-dependent — every edit changes behavior by definition; the model can't objectively distinguish "behavioral" from "cosmetic." "Unfamiliar code" is even worse: freshness is a function of conversation history, not file content. In a compact format (AGENTS.md is 70 lines of pipe-delimited key-values, not prose), a fresh model reading the `auto_load` key will have no reliable way to apply a subjective trigger like "unfamiliar." The result is either: always loads (over-load), or loads only on explicit multi-file plans (under-load), depending on the model session.
   - **Suggestion**: Replace behavioral/familiarity qualifiers with a purely mechanical trigger: load whenever `target_files` are known AND at least one Edit/Write/bash-that-modifies-code call is imminent. Add one explicit skip list: "(a) single token change the user named explicitly, (b) documentation-only edits, (c) test-only changes with no domain-logic files in scope." This is greppable, session-invariant, and doesn't require the model to judge "familiarity."

2. **Single Point of Failure — Skills deferring to AGENTS.md `auto_load` creates a fragile chain**
   - Tasks 2–5 all say "follow AGENTS.md auto_load procedure." If the AGENTS.md procedure is ambiguous (Concern 1 above), ALL five call-sites inherit that ambiguity. The pre-mortem identified this as Risk 4 and called it a strength ("reference, don't redefine"). But the architectural risk runs both ways: if `auto_load` is the wrong level of indirection, five skills now fail together. There is no per-skill escape hatch. A skill that genuinely needs a different loading strategy (e.g., `/pre-mortem` loads profiles from a PLAN'S intended files, not the current working directory's files) has no way to express that without re-defining the procedure — contradicting the plan's own ACs.
   - **Suggestion**: For skills where the "target paths" are well-defined at invocation time (hotfix: affected files list; pre-mortem: plan's `## Files` section; plan-to-prd: tasks' file paths), define the path-extraction step inline in the skill and then call `auto_load(paths)`. AGENTS.md's procedure is the MATCHER, not the path-resolver. This keeps indirection useful while allowing per-skill path resolution.

3. **Risk 3 Fallback — "Load on ANY work for no-frontmatter profiles" will be actively annoying**
   - The plan says: no-frontmatter PROFILE.md → load whenever ANY work touches the project + ⚠️. The anchor project has FOUR profiles with no frontmatter (the pre-mortem confirms this). Until someone runs `/build-os-retrofit`, EVERY conversation in anchor will load all four profiles regardless of what is being changed. Four profiles × ~6KB average = ~24KB of mandatory context burn on every fresh session, plus a warning. The ⚠️ nudge only fires once per session maximum (the model won't repeat it), so it's not a reliable driver to fix the frontmatter. Meanwhile, the builder experiences a slow, token-heavy interaction for weeks until they happen to run `/build-os-retrofit`.
   - **Stronger rule**: No-frontmatter profiles should load ONLY if target paths plausibly overlap the profile's domain name (e.g., a profile directory named `node-api` → load only when target files contain `api/`). If zero overlap heuristic is possible, skip it AND surface a one-time ⚠️ at the end of the session (not mid-task). Better yet: no-frontmatter = skip with a single end-of-session warning, because loading a scoping-free profile is exactly the correctness problem the `scope:` field was designed to solve. Loading it as "project-wide" defeats the lifecycle.

4. **Token Explosion — Ten profiles, multiple scope matches**
   - The plan has no upper bound on how many profiles can match. A project with 10 profiles and a change to `api/src/routes/user.ts` might match: `node-api`, `auth`, `user-domain`, `backend-core`, `middleware`, `rate-limiting` — six profiles simultaneously, each 6–10KB. That's 60KB of Layer 4 context before a single line of code is written. Combined with Layer 1–3 overhead (AGENTS.md, build-standards.md, the role agent), you're at 80–100KB of context per session for routine changes. The plan nowhere acknowledges this risk or proposes a hard cap.
   - **Suggestion**: Add to `auto_load:` procedure: "Load at most N profiles per session (recommend N=3); if more than N match, surface the full match list and load the N most specific (longest glob match wins specificity). Builder can explicitly request more." This gives a safety valve without eliminating functionality.

5. **`/hotfix` Phase 4 Routing — Will not fire in practice for most hotfixes**
   - Phase 4 currently says "Update LEARNINGS.md (if applicable)." The plan proposes adding a routing decision mirroring `/post-mortem` lines 93–109. The issue: hotfixes are exactly the context where the builder has least patience for process. The `/hotfix` flow already has four phases with multiple steps each. Adding a routing decision in Phase 4 — after the fix is done, committed, and reviewed — creates a "one more thing" gate that builders will skip mentally. The existing "if applicable" language signals that LEARNINGS.md is optional; routing to PROFILE.md will feel equally optional. The fix is shipped; the temptation to not update the profile is near-total.
   - **Suggestion**: Move the routing decision to Phase 3 (Review), not Phase 4. The reviewer subagent — already standing — is the right agent to make a domain-knowledge call: "Did this fix expose a new invariant that subagents need up front?" The reviewer is already reading the diff cold, which is the best vantage point for that test. Phase 4 becomes mechanical: "Apply the routing decision from Phase 3."

6. **`/pre-mortem` Step 0 — Chicken-and-egg: paths aren't known at pre-mortem time**
   - Pre-mortem fires before execution begins, when the plan is a list of prose steps ("Update AGENTS.md", "Fix hotfix Phase 4"). Target FILE paths are INFERRED, not specified. The plan says "follow AGENTS.md auto_load procedure against the plan's intended file paths." But `auto_load` trigger is explicitly conditioned on "when target file paths are known." At pre-mortem time, you don't have target paths — you have plan tasks. The scope match will either fail silently (no paths → no match) or require the model to infer paths from plan prose (fragile, hallucination-prone).
   - **Suggestion**: In pre-mortem's Step 0, resolve paths from the plan's `## Tasks` section — each task specifies a `**File:**` key. Pre-mortem should explicitly extract these path hints before calling `auto_load`. This is a pre-mortem-specific step that CANNOT be delegated to AGENTS.md, directly contradicting the "don't redefine the procedure" principle from the pre-mortem's own mitigations.

7. **AC Testability — Several ACs are effectively untestable by a developer agent**
   - Task 1 AC: "The trigger is crisp" — this is a quality judgment, not a verifiable predicate. The grep ACs (`grep "auto_load" build/AGENTS.md`) confirm the text exists, not that the trigger is unambiguous. A developer agent will write any text that contains "auto_load" and the AC will pass.
   - Task 2 AC: "`grep 'last_validated' commands/hotfix.md` returns at least one line" — this passes if the string appears in a comment.
   - Task 5 AC: "Distinction between Quick and Full Review documented" — documentation can be wrong. No behavioral verification.
   - **Suggestion**: Add smoke-test ACs that verify behavior, not text. Example Task 1 AC: "Given a project with one PROFILE.md containing `scope: api/**`, and a task touching `api/src/foo.ts`, the PROFILE.md body is loaded into context. Given a task touching `frontend/src/foo.ts`, it is NOT loaded." These could be verified via mental walkthrough or manual session test.

8. **`/review` Quick Mode — Adds load step but review.md is ALREADY Full-Review-gated at Step 2**
   - The current `review.md` Step 2 label is "Full Review only." Task 5 changes Quick mode to "follow AGENTS.md auto_load (scope-matched only)." But the plan doesn't say whether Quick mode also gets Step 3 (Scan LEARNINGS.md) — which is ALSO gated to "Full Review only." A consistent Quick mode would logically get scope-matched profiles AND scope-matched LEARNINGS.md. Not specifying this leaves an inconsistency in review.md after the change. The developer implementing Task 5 will have to guess.
   - **Suggestion**: Task 5 should explicitly state whether Step 3 is also unlocked for Quick mode, or stays Full Review only. The AC should reflect this choice.

9. **Out-of-Scope omission — No mention of `/wrap`'s interaction with auto-loaded profiles**
   - The plan scopes in "auto-load" but `/wrap` already reads `last_validated:` frontmatter to detect drift. After this plan lands, the main agent has been LOADING profiles via auto-load — which means it has the profile in context at wrap time. But `/wrap` still does a fresh file-system scan. There's now a question: should `/wrap` use already-loaded profiles from context (faster, but may be stale from earlier in the session) or re-read from disk? The plan doesn't address this interaction.
   - **Suggestion**: Add to Out-of-Scope: "/wrap interaction with already-loaded profiles — /wrap always re-reads from disk, regardless of auto-load state." This prevents a future ambiguity without requiring any work now.

---

### AC Validation Issues

| Task | AC | Issue | Suggested Fix |
|------|----|-------|---------------|
| Task 1 | "The trigger is crisp" | Not testable — subjective quality judgment | Replace with behavioral smoke test (path match loads body; non-match does not) |
| Task 1 | "`grep 'auto_load' build/AGENTS.md`" | Verifies presence, not correctness | Add: trigger, discovery, match, fallback, and load each appear as distinct parseable fields |
| Task 2 | "`grep 'last_validated'` returns one line" | Passes if string is in a comment or wrong context | Require the string appear in a routing decision block, not just anywhere |
| Task 5 | "Distinction documented" | Docs can be wrong | Add: Quick mode does NOT trigger Step 3 (or explicitly DOES) per the plan's intent |

---

### Test Coverage Gaps

- Task 1: No behavioral test for the no-frontmatter fallback path. The claim "all 4 anchor profiles would load" is a mental walkthrough, not a verification step.
- Task 2: No regression test that the original "Update LEARNINGS.md" path still works — the routing test could accidentally make LEARNINGS.md updates feel optional.
- Task 3–4: No verification that loaded profiles actually appear in the output (risk category references) — the profile could be loaded and never used.

---

### Strengths

- The core insight is correct: the lifecycle has a read/write asymmetry — skills write profiles (post-mortem) but only specific skills READ them. Closing that gap via AGENTS.md is the right architectural level.
- Deferring to `auto_load` rather than copy-pasting scan logic into five files is the right structural choice. The concern isn't the pattern — it's the quality of the anchor procedure.
- Separating "frontmatter scan" (cheap) from "body load" (gated on match) is a smart two-phase design that handles the token cost cleanly — IF the trigger definition is crisp.
- Pre-mortem was thorough on the risks it covered (7 risks). The mitigations were folded into the plan's ACs, showing the plan iterated on feedback.
- The no-frontmatter ⚠️ surfacing pattern follows the existing `/wrap` migration-warning convention — consistent system design.

---

### Devil's Advocate

**If this fails, it will be because...** The `auto_load` trigger is not crisp enough to be interpreted consistently across model sessions. "Changes behavior" and "unfamiliar code" are judgment calls that vary by conversation history, model version, and phrasing of the user's request. The plan generates five call-sites that all depend on this trigger being reliable. Within three weeks of shipping, different sessions will have different interpretations, builders will notice inconsistent loading, and the feature will be perceived as broken even though it "passed" all grep-based ACs. The pre-mortem flagged trigger crispness as a HIGH risk and recommended concrete phrasing — but the plan's Task 1 still uses the same vague language ("non-trivial code work," "changes behavior") in its description.

**The worst outcome would be...** Risk 3's fallback (no-frontmatter = load always) fires in the anchor project for every single session, burning 24KB of context on every interaction — including simple questions, quick lookups, and one-liners — until the builder happens to run `/build-os-retrofit`. Combined with no token cap (Concern 4), a project with 10 legacy profiles becomes actively painful to use with build-os. The builder disables auto-load in AGENTS.md, which removes the feature entirely and leaves gap 1 permanently open.

---

### Verdict

- [ ] Approve
- [x] Approve with suggestions
- [ ] Approve pending pre-mortem
- [ ] Revise

The plan is approvable as-is if the pre-mortem's existing mitigations are applied faithfully. However, three concerns need explicit resolution before implementation begins (not blocking approval, but must be folded into Task 1 before a developer touches AGENTS.md):

---

### Suggested Changes

**Change 1**: Trigger Definition (Task 1)
- **What's wrong**: "Before code work that changes behavior or touches unfamiliar code" is not mechanically evaluable by a language model reading AGENTS.md in a compact format. Two sessions with the same user request will produce different load decisions.
- **What to do**: Replace with a mechanical trigger: "Load when (a) target file paths are known AND (b) at least one Edit/Write/code-modifying Bash call is about to be made. Skip when: user named an exact single-token change, documentation-only edit, test-only change with no domain-logic files in scope."
- **Where to fix**: Task 1 description, `auto_load: trigger:` key in AGENTS.md

**Change 2**: No-Frontmatter Fallback (Task 1 / Risk 3)
- **What's wrong**: Loading no-frontmatter profiles on ANY project work will create a severe token-burn experience for projects with legacy profiles (anchor: 4 profiles × ~6KB = 24KB on every fresh session).
- **What to do**: Change fallback to: "No-frontmatter profile → load ONLY if target paths contain a substring matching the profile's directory name (heuristic scope). If no heuristic match, skip body load. Surface one ⚠️ end-of-session (not mid-task) suggesting `/build-os-retrofit`."
- **Where to fix**: Task 1 description, `auto_load: fallback:` key in AGENTS.md

**Change 3**: Token Cap (Task 1 — currently missing)
- **What's wrong**: No upper bound on simultaneous profile loads. A project with 10 profiles and a cross-cutting change loads all 10 bodies simultaneously.
- **What to do**: Add to `auto_load:` procedure: "Load at most 3 profiles per session. If more match, load the 3 with most-specific (longest) scope glob match. Surface remaining matches as a one-line note."
- **Where to fix**: Task 1 description, new `auto_load: cap:` key in AGENTS.md

**Change 4**: Phase 4 Routing Placement (Task 2)
- **What's wrong**: Adding a routing decision in Phase 4 (after the fix is committed) will be skipped in practice — builders have no motivation to re-evaluate domain knowledge after the work is merged.
- **What to do**: Move routing decision to Phase 3 (Review). The reviewer subagent asks: "Did this fix expose an invariant subagents need before working in this domain?" Answer drives whether Phase 4 writes to PROFILE.md or LEARNINGS.md only.
- **Where to fix**: `commands/hotfix.md` Phase 3 reviewer prompt + Phase 4 template

**Change 5**: Pre-mortem Path Extraction (Task 3)
- **What's wrong**: Pre-mortem runs before execution — target file paths must be extracted from the plan's `**File:**` fields, not from current working files. AGENTS.md `auto_load` trigger assumes paths are already known. This is a pre-mortem-specific step that cannot be delegated.
- **What to do**: Add to Task 3: "Before calling auto_load, extract `**File:**` values from each plan task. Pass these as target paths." This is Step 0a; auto_load is Step 0b.
- **Where to fix**: Task 3 description and AC, `commands/pre-mortem.md` Step 0
