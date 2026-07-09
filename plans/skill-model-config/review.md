# Review: skill-model-config plan + pre-mortem

**Type**: Plan (with attached pre-mortem)
**Review Path**: Full
**Complexity**: Medium (5+ files, architectural decisions, new dependency)
**Recommended Track**: standard (`/ship` full flow) — already in progress

## Concerns

### 1. Structural: `commands/*.md` is a shared source-of-truth with user-config-driven edits

This is the biggest concern and the reason I'm not marking Approve outright. `~/.claude/commands/` is a **symlink** to `$REPO/commands/` (confirmed in `install.sh`). The plan says global sync writes `model:` into `commands/<name>.md` in the source repo. Consequences:

- After the first `bin/build-config sync --global`, the user's build-os checkout has 9 dirty files with unstaged `model:` additions driven by their personal `~/.claude/build/config.yaml`.
- `git pull` in build-os will conflict on any upstream skill edit that touches frontmatter — because upstream has `model:` absent but locally it's present.
- If the user commits the noise to their fork, they've leaked personal model preferences into their build-os fork.
- If the user reverts to clean up `git status`, they wipe their config.

**Suggestion**: pick one of:
- **(A) Break the symlink for global sync.** `install.sh` still symlinks initially, but the first `bin/build-config sync --global` replaces the symlink with a real directory populated from source. Sync now edits `~/.claude/commands/*.md` directly. Source repo stays clean. Downside: `git pull` in build-os no longer updates the user's active skills until they re-sync. Add that to the sync command's help text and the `install.sh` post-message.
- **(B) Document the tension and ship as-is.** Add explicit "sync will produce unstaged changes in your build-os checkout; that's expected" note in AGENTS.md `[Config]` and `bin/build-config` help. Cheaper to build, uglier to live with.

I'd recommend (A). Worth deciding before PRD conversion.

### 2. pyyaml round-trip may produce noisy diffs even with `sort_keys=False`

pyyaml's `safe_dump` re-quotes strings, normalizes indentation, and can flip flow vs block style. Even semantically identical input can round-trip to different bytes. If sync writes byte-different files with no semantic change, every `sync` produces churn — undermining the "idempotent" promise from the plan.

**Suggestion**: Add an explicit AC to the PRD — "sync run twice back-to-back on unchanged config produces zero file writes (mtime unchanged)". This forces the implementation to hash-compare before writing, or use a formatter setting (`default_flow_style=False`, `default_style=None`, matching quote style) that survives round-trip on the current file shapes. Include a fixture test: parse `hotfix.md`'s frontmatter, dump it back, expect identical bytes.

### 3. `source_hash:` (from pre-mortem Risk 4) adds v1 complexity for a rare failure mode

Pre-mortem Risk 4 proposes storing a SHA256 of the source body in materialized project files to detect user hand-edits. That's real machinery: compute hashes on read, compare on write, wire up `--force`.

**Suggestion**: Simpler v1: sync just prints a warning + skips any managed file whose body differs from what it would generate right now (whole-file compare, no stored hash). If bodies match → overwrite freely. If they don't → warn, skip, require `--force`. Same protection, no persisted state. Store hashes in a future version if we need finer-grained detection.

### 4. Missing behavior spec: what does sync do to skills the user's config doesn't mention?

Plan is silent on: config has `skills: {ship: opus}` but nothing about the other 8 skills. What happens to their `model:` field?

Two reasonable options:
- Sync only touches skills mentioned in config → other files stay whatever they are (dangerous: stale state possible).
- Sync resolves EVERY skill through the full precedence chain → skills with no override get `default_model` (or `model:` cleared if no default set). Predictable but rewrites every file.

**Suggestion**: Pick "resolves every skill" and add to the plan. It's the only behavior consistent with "empty config = no model overrides = clear model: from all managed files."

### 5. Missing behavior spec: sync with no config file at all

What happens if `~/.claude/build/config.yaml` doesn't exist and user runs `bin/build-config sync --global`?

**Suggestion**: No-op with a friendly message: "no global config found — run `bin/build-config init --global` first." Add to plan.

### 6. Test coverage gap: no pre/post diff verification of unchanged files

Verification steps write the config and check what changed, but don't check what *didn't* change. If a bug in the parser breaks `hotfix.md`'s `triggers:` list (pre-mortem Risk 1), the current steps might not catch it.

**Suggestion**: Add verification step: "before first sync, snapshot `commands/*.md` (e.g., copy to `/tmp/skills-before/`). After sync with empty config, diff should be zero. After sync with populated config, diff should show only `model:` insertions in expected files."

## Strengths

- Precedence chain is well-defined (7 layers, unambiguous).
- Layered config global → project mirrors an existing build-os pattern (`[Roles]` layering — good precedent).
- Bucket abstraction is optional and additive — per-skill overrides still work if user skips buckets entirely.
- `managed: build-os` marker is a clean way to distinguish generated from hand-written project-local commands.
- Verification section is 9 concrete steps, not vague "test it works."
- Out-of-scope section is disciplined (fallback models, per-turn switching, auto-sync all correctly deferred).
- Pre-mortem folded 7 risks into actionable mitigations before this review — very few surface here that pre-mortem missed.

## Devil's Advocate

**If this fails, it will be because...** pyyaml round-trips existing frontmatter to byte-different but semantically-identical output, so every sync marks every skill file as modified in `git status`. Combined with the symlink-to-source-repo design (concern #1), users see 9 dirty files in their build-os checkout after one sync. Half will commit the noise, half will `git checkout` and wipe their config. Trust in the tool erodes fast.

**The worst outcome would be...** sync corrupts the `triggers:` YAML list in `hotfix.md` (a real edge case since it's the only non-scalar frontmatter field in the codebase). `/hotfix` silently stops responding to bug-fix triggers. User types "fix this bug" for weeks without realizing `/hotfix` is dead. When they finally notice, they don't trace back to sync — they file a build-os bug against `/hotfix` itself.

## Verdict

- [ ] Approve
- [x] Approve with suggestions
- [ ] Approve pending pre-mortem
- [ ] Revise

Pre-mortem is done. Suggestions above are meaningful but not structural blockers — they should fold into the PRD's task ACs. Concern #1 (symlink structural choice) is the only one that could reshape the plan; recommend deciding (A) vs (B) before PRD conversion so the PRD's task list reflects the chosen sync architecture.

## Suggested Changes

**Change 1**: Pick sync-target architecture (Concern #1)
- **What's wrong**: Plan implicitly assumes sync writes into the symlinked `commands/` in the source repo, creating unavoidable dirty git state and pull-conflict risk.
- **What to do**: Decide between (A) sync breaks the symlink and writes to a materialized `~/.claude/commands/`, or (B) accept dirty source-repo state and document it. Recommend (A).
- **Where to fix**: `plan.md` § "Sync mechanics" — add a "Global sync target" paragraph naming the choice and its consequences.

**Change 2**: Simplify divergence detection (Concern #3)
- **What's wrong**: `source_hash:` field is v1 over-engineering for the "user hand-edited a materialized file" case.
- **What to do**: Replace with whole-file body comparison at sync time — if project-local file's body differs from what would be regenerated, warn & skip unless `--force`. No persisted hash.
- **Where to fix**: `pre-mortem.md` § Risk 4 mitigation.

**Change 3**: Specify sync behavior on unmentioned skills and missing config (Concerns #4, #5)
- **What's wrong**: Two behavior gaps that will bite implementation.
- **What to do**: Add "resolves EVERY skill through the full chain, including clearing `model:` when nothing resolves" and "no-op with friendly message when config file missing" to plan.
- **Where to fix**: `plan.md` § "Sync mechanics".

**Change 4**: Add pre/post snapshot verification (Concern #6)
- **What's wrong**: Verification steps validate additions but not that untouched files stay untouched.
- **What to do**: New verification step: snapshot `commands/*.md`, run sync with empty config, expect zero diff.
- **Where to fix**: `plan.md` § "Verification".

**Change 5**: Add idempotence AC (Concern #2)
- **What's wrong**: pyyaml round-trip may produce noisy diffs even on unchanged input; "idempotent" needs teeth.
- **What to do**: PRD task for `bin/build-config` gets AC: "Two consecutive `sync` runs on unchanged config produce zero file mtime changes on the second run." Implementation: hash-compare before write.
- **Where to fix**: PRD (Phase 2.2) — fold when converting plan.
