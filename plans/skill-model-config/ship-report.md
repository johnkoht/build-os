# Ship Complete: skill-model-config

| Tasks | Quality Gates | Iterations | Commits |
|-------|--------------|------------|---------|
| 8/8   | ✅ self-test + all ACs | 1 mid-fix | 10 |

## Deliverables

- **`bin/build-config`** — 674-line Python 3 CLI. Subcommands: `init`, `sync --global|--project|--all`, `show [<skill>]`, hidden `self-test`. Precedence resolution across 7 layers, pyyaml round-trip with IndentDumper (preserves `triggers:` YAML lists byte-identical), symlink break-out on first `sync --global`, hand-edit protection, allowlist warnings with "did you mean" hints, env-var scratch-prefix support (`BUILD_OS_REPO`, `BUILD_OS_CLAUDE_HOME`).
- **`build/config.yaml.example`** — annotated template every line commented; `sync` on unmodified example writes zero files.
- **`bucket:` frontmatter added to 10 skills** — planning: pre-mortem/plan-to-prd/review/post-mortem; execution: ship/build/hotfix/new-project/build-os-retrofit; mechanical: wrap.
- **`build/AGENTS.md [Config]` block** — precedence chain + sync semantics documented.
- **`.gitignore`** — `build/config.yaml` gitignored.
- **`install.sh`** — post-install hint.
- **`bin/new-project`** — scaffolds `.build/config.yaml` as fully-commented opt-in template.
- **`plans/skill-model-config/verification-manual.md`** — M1 (live-session frontmatter model wins) + M2 (retrofit existing project) checklists deferred to human-in-the-loop.

## Verified against scratch prefix

All Task 1–7 ACs ran against `/tmp/skill-model-config-test/.claude` (env-var isolated). Task 8 is a doc-only deliverable. See `plans/skill-model-config/pre-mortem.md` and per-commit messages for the AC-by-AC receipt.

## Deferred manual verification

- **M1**: Open a Claude Code session, `/model haiku`, run a skill with `model: opus` — confirm frontmatter wins.
- **M2**: Init + sync a project config in an existing repo — confirm materialization, removal, and hand-written skill safety.

## Key learnings (see memory entry for full detail)

1. **Removal path needed its own predicate** — the hand-edit compare that guards create/update produced false positives on remove (comparing "old override output" to "current no-override output"). Fix: trust the `managed: build-os` marker on the removal branch. Root cause: pre-mortem only enumerated the update path.
2. **`yaml.safe_dump` rejects `Dumper=` kwarg** — silent API constraint. Caught by `self-test` fixture, not by static analysis. Switched to `yaml.dump` with the IndentDumper subclass.
3. **The "sync target" architectural gate was worth the pre-merge conversation.** Symlink break-out (option A) vs dirty source-repo state (option B) shaped the entire PRD; user picked A explicitly.

## Recommendations

**Continue**:
- Env-var scratch prefixes on any CLI touching `~/.claude`.
- Hidden `self-test` subcommands as smoke-test fixtures — no test framework needed.
- Cross-model review as an early architectural gate for meta-system changes.

**Start**:
- Add "removal path" enumeration to future pre-mortems for file-managing tools.
- Verify AC greps are genuinely unique to their target block before writing "expect 1 hit."

**Backlog**:
- `sync --dry-run` before force ops.
- `bin/build-config show --global-only|--project-only`.
- `install.sh` idempotency after `sync --global` breaks the symlink.
- Auto-generate AGENTS.md `[Skills]` block from skill frontmatter (`triggers:` + `bucket:`).
