# skill-model-config — Learnings

**Date**: 2026-07-08
**PRD**: `plans/skill-model-config/prd.md`
**Branch**: `feature/skill-model-config`

## What shipped

Layered per-skill model configuration for build-os slash commands.

- `bin/build-config` — Python 3 CLI (674 LOC) with `init` / `sync --global|--project|--all` / `show [<skill>]` / hidden `self-test`. Uses pyyaml with an IndentDumper subclass so `triggers:` lists round-trip cleanly. Env-var overrides for `BUILD_OS_REPO` and `BUILD_OS_CLAUDE_HOME` enable scratch-prefix testing.
- `~/.claude/build/config.yaml` (gitignored) + `<project>/.build/config.yaml` (committable) — YAML config with `default_model`, `task_models` (planning|execution|mechanical), and `skills:` per-skill overrides.
- **First `sync --global` breaks the `~/.claude/commands` symlink** and materializes it — source repo (`$REPO/commands/`) stays upstream-clean; `git pull` in build-os no longer auto-updates active skills (user re-runs sync).
- All 10 skills get a `bucket:` frontmatter field driving `task_models` resolution.
- `[Config]` section added to `build/AGENTS.md` documenting the precedence chain.

## Metrics

- Tasks: 8/8 complete (all ACs verified against `/tmp/skill-model-config-test/` scratch prefix)
- Iterations: 1 mid-task fix (removal path in project sync was incorrectly firing the hand-edit warning)
- Pre-mortem: 7 risks identified, 0 CRITICAL, 0 materialized (all folded into task ACs — see below)
- Review: Approve with suggestions; 5 suggestions folded, notably switching sync target from source-repo to materialized `~/.claude/commands/`
- Commits: 8 on `feature/skill-model-config` (one per task + 1 mid-fix)

## Pre-mortem effectiveness

Every HIGH risk had a matching AC or design element:

- **Risk 1 (parser fragility on `triggers:` list)** — pyyaml + IndentDumper + `bin/build-config self-test` fixture. Byte-identical round-trip achieved after one iteration to add IndentDumper (`safe_dump` doesn't accept custom `Dumper=`, had to switch to `yaml.dump`).
- **Risk 2 (pyyaml install ergonomics)** — Explicit 3-option install message from the CLI on `ImportError`, no auto-install in `install.sh`. Actionable message validated against real "no pyyaml" state during development.
- **Risk 3 (invalid model names)** — Allowlist + Levenshtein "did you mean" hint + non-zero exit unless `--force`. Validated with `default_model: opuss`.
- **Risk 4 (hand-edit protection)** — Whole-file body compare (no persisted hash, per Review Change 2). Validated: hand-edit warns and skips (exit 5); `--force` overwrites. But: original design missed that the *removal* path also called the compare with wrong parameters — false-positive warning on override removal (mid-task fix `28843e7`).
- **Risk 5 (bucket assignment contested)** — Deferred to per-skill override capability + `show` resolution trace. Rationale comments in `config.yaml.example`.
- **Risk 6 (verification requires live session)** — Split into automated ACs (validated in `/build`) and `verification-manual.md` (M1 live-session, M2 project retrofit) for `/wrap` phase.
- **Risk 7 (task ordering)** — Enforced via `depends_on` in `prd.json`; task-1 CLI before everything referencing it. No ordering issues surfaced.

## What worked (+)

- **Scratch-prefix testing via env vars.** `BUILD_OS_CLAUDE_HOME=/tmp/...` isolated all state; no risk of corrupting the real `~/.claude`. Every AC ran against the scratch prefix.
- **pyyaml round-trip fixture as a hidden `self-test` subcommand.** Fast smoke check for any future dump-setting changes. Caught the initial "safe_dump doesn't accept Dumper=" API constraint immediately.
- **Whole-file body compare instead of stored hash (Review Change 2).** Same protection, no persisted state to keep in sync. Simpler.
- **Symlink break-out framed as first-sync side effect, not install-time step.** Users who don't touch model config never break the symlink; those who do get a clear one-line notice when it happens.
- **Bucket abstraction added value.** Setting `task_models.mechanical: haiku` to flip `wrap` (bucket=mechanical) worked without touching per-skill config. Made the "why 3 buckets" abstraction concrete.
- **Cross-model review's "sync target" question was the single most important design gate.** Both A (materialize) and B (dirty source repo) shipped, but B would have created recurring pull-conflict friction — user picked A explicitly, and the resulting PRD/AC shape was different.

## What didn't work (−)

- **First `bin/build-config` iteration used `yaml.safe_dump`, which rejects `Dumper=` kwarg.** Silent gotcha — the try/catch on ImportError doesn't cover API misuse. Would have been caught by a syntax-check pass but not by a syntax check alone. Only surfaced when running `self-test`.
- **Removal path's hand-edit check was wrong-parameter.** Compared file to what would be generated *now* (no override), not what was generated *last sync* (with override). Fix: trust the marker on removal, don't compare content. Root cause: pre-mortem Risk 4 only considered the update path, not the remove path.
- **Nested `[Skills]|root:` in AGENTS.md broke `grep -c "^\[Skills\]"` counting my edited line as still matching.** Not a real issue — the edited line is still the `[Skills]` block — but confused my AC verification for a moment. Recorded as: "AC 4.4 'only additions in diff' allowed 1 deletion for the intended [Skills] line replacement."

## Recommendations

### Continue

- **Env-var scratch prefixes for CLIs that touch `~/.claude`.** Any future build-os CLI should follow the `BUILD_OS_CLAUDE_HOME` / `BUILD_OS_REPO` pattern so tests run in isolation.
- **Hidden `self-test` subcommands as fixture-check smoke tests.** Cheap, self-contained; runs in CI or by user command without any test framework.
- **Cross-model review as an early architectural gate.** Confirmed the "sync target" tension before PRD conversion. Would have burned significant rework if left unaddressed.

### Stop

- **Don't assume the update path and removal path use the same comparison logic.** The mid-task fix caught this; the pre-mortem didn't. Next time: enumerate CRUD ops explicitly.

### Start

- **Add a "removal path" checkbox to pre-mortem Risk 4 style checks.** For any file-managing tool, ask: what does undo/delete look like, and does it use the same predicate as create/update?
- **When the AC verification grep expects "1 hit," verify the pattern is genuinely unique to the target block.** `|purpose:` / `|global:` / `|project:` are common in AGENTS.md — my initial AC was too tight.

## Follow-ups

- **`sync --dry-run` mode** would help before force operations. Currently the only pre-flight is the friendly "no config found" message. Backlog, not blocker.
- **`bin/build-config show` should optionally accept a scope flag** (`--global-only`, `--project-only`) so users can compare "what would sync do here vs there" without leaving the CLI.
- **Should `install.sh` idempotently detect the materialized state** and skip re-symlinking on subsequent runs where a previous `sync --global` already broke the symlink? Currently `install.sh` would fail on the `if [ -L "$CLAUDE_DIR/commands" ]` branch (no longer a symlink) and either overwrite or bail. Worth an explicit branch. Backlog.
- **AGENTS.md `[Skills]` block could be auto-generated** from skill frontmatter (`bucket:` and `triggers:`) — currently duplicates the trigger list. Same tension we solved for `model:`. Backlog.
