---
status: approved
has_pre_mortem: true
has_review: true
has_prd: true
---

# Per-skill model configuration for build-os

## Context

Claude Code skills and slash commands support a `model:` field in YAML frontmatter that pins the skill to a specific model (opus/sonnet/haiku, or `inherit`) for the turn it runs in. build-os today ships 9 slash commands in `commands/*.md` — none declare `model:`, so they all run on the session model. Some tasks are heavy planners (`/ship`, `/pre-mortem`, `/review`) and want Opus; others are mechanical (`/wrap`) and would run fine on Haiku for less cost/latency.

We want two layers of user control:
- **Global**: a personal default across all build-os skills, plus per-skill overrides — lives in `~/.claude/build/config.yaml`.
- **Project**: an optional override committed to `<project>/.build/config.yaml` so a team can share model choices per repo.

Because Claude Code reads model selection from static frontmatter, config → skill state is bridged by an explicit **sync command** (`bin/build-config sync`) rather than any runtime magic.

## Design

### Storage & layering

- **Global config**: `~/.claude/build/config.yaml` — gitignored in the build-os source repo (precedent: `build/memory/collaboration.md`).
- **Project config**: `<project>/.build/config.yaml` — expected to be committed. `.build/` is already a build-os convention (currently just for `expertise/` and `agents/`); this adds `config.yaml` as its first config-shaped resident.
- **Skill → bucket mapping**: declared in each skill's own frontmatter via a new `bucket:` field (`planning` | `execution` | `mechanical`). Colocated with the skill definition — no separate manifest to keep in sync.

### Config schema

```yaml
# Session-default fallback when nothing else matches
default_model: opus

# Task-bucket defaults — apply to any skill whose frontmatter declares that bucket
task_models:
  planning:   opus
  execution:  sonnet
  mechanical: haiku

# Per-skill overrides (win over bucket)
skills:
  review: opus
  # ship: sonnet     # example
  # wrap: inherit    # example: force session default even if bucket says otherwise
```

All three sections are optional. An empty file means "no overrides" — sync clears any `model:` field from managed skill files.

### Precedence chain (highest wins)

For each skill in a given context:

1. Project config `skills.<name>`
2. Project config `task_models.<bucket-of-skill>`
3. Project config `default_model`
4. Global config `skills.<name>`
5. Global config `task_models.<bucket-of-skill>`
6. Global config `default_model`
7. No `model:` field (session model)

`inherit` is a valid explicit value at any layer — it forces "use session model" without falling through to further layers.

### Sync mechanics

- **Global sync target — symlink break-out**: `install.sh` initially symlinks `~/.claude/commands` → `$REPO/commands` (unchanged from today). The **first** `bin/build-config sync --global` detects the symlink, replaces it with a real directory populated from source, then writes `model:` into that materialized directory. `$REPO/commands/` stays upstream-clean forever. Subsequent syncs edit `~/.claude/commands/*.md` directly. Consequence: `git pull` in build-os no longer auto-updates active skills — user must re-run sync. `install.sh` post-install hint mentions this; sync's help text spells it out.
- **Global sync** (`bin/build-config sync --global`): resolves **every** managed skill through the global-only chain (`skills.<name>` → `task_models.<bucket>` → `default_model` → clear `model:`). Writes/updates/removes `model:` in `~/.claude/commands/<name>.md`. No `model:` value at any layer → `model:` field is deleted from the file.
- **Project sync** (`bin/build-config sync --project`, run from a project with `.build/config.yaml`): for each skill where **project-resolved model ≠ global-resolved model**, materialize a full copy of the skill at `<project>/.claude/commands/<name>.md` with the project-resolved `model:`. If they resolve to the same value, don't materialize (Claude Code falls through to the global skill).
- **`sync --all`** (default): runs both.
- **Managed-file marker**: materialized project files get a `managed: build-os` field in their frontmatter. On re-sync, only files carrying that marker get rewritten or removed — hand-written project-local slash commands are never touched.
- **Hand-edit protection**: before overwriting any managed file, sync compares its current body to the body that would be regenerated. If they differ (user hand-edited the materialized file), sync prints a warning and skips that file unless `--force` is passed. Whole-file comparison, no persisted hash.
- **Missing config**: running `sync --global` with no `~/.claude/build/config.yaml` (or `sync --project` outside a project) is a no-op that prints `no <scope> config found — run bin/build-config init --<scope> to create one`.
- **Idempotent**: two consecutive syncs on unchanged config produce zero file writes on the second run (compare-before-write, not blind overwrite).

### CLI shape (`bin/build-config`, Python 3)

```
build-config init    [--global | --project]   # scaffold a starter config.yaml
build-config sync    [--global | --project | --all]   # apply config → skill files (default: --all)
build-config show    [<skill-name>]           # print resolved model per skill with source layer
```

`show` output is the diagnostic tool users reach for when "why is /ship running on sonnet?" — it prints `skill → model  (source: project.skills, project.task_models, global.default, …)`.

### Dependency

- Requires `pyyaml`. `install.sh` gets a check that runs `python3 -m pip install --user pyyaml` if the import fails, with a clear error message if the install can't proceed. This is a new dep for build-os — chosen deliberately over TOML for YAML/frontmatter consistency (see plan discussion).

## Files

### New

- **`bin/build-config`** — Python 3 CLI. Reads YAML config with `pyyaml`; edits skill frontmatter with a simple line-based parser (frontmatter shape is trivial: bounded by `---`, one key per line, no nested structures). Idempotent sync; materializes/removes project-local skill copies based on the managed marker.
- **`build/config.yaml.example`** — annotated template showing every field, ready to copy to `~/.claude/build/config.yaml` or `<project>/.build/config.yaml`.

### Edited

- **`commands/*.md`** (all 9 skills) — add `bucket:` to frontmatter. Suggested initial assignments (user can adjust):
  - `planning`: `pre-mortem`, `plan-to-prd`, `review`, `post-mortem`
  - `execution`: `ship`, `build`, `hotfix`, `new-project`, `build-os-retrofit`
  - `mechanical`: `wrap`
- **`build/AGENTS.md`** — new `[Config]` section (short: where config lives, precedence chain, sync command). Mention `bucket:` in `[Skills]`.
- **`.gitignore`** — add `build/config.yaml` alongside existing personal-file entries.
- **`install.sh`** — add `pyyaml` install/check block.
- **`bin/new-project`** — copy `build/config.yaml.example` (as a commented-out example) into `.build/config.yaml` when scaffolding.

## Verification

Automated (runs during `/build` phase inside worktree, targets a scratch prefix so we don't clobber the real `~/.claude/`):

0. **Round-trip fixture**: parse then dump `commands/hotfix.md` and `commands/build-os-retrofit.md` frontmatter with the chosen pyyaml settings; expect byte-identical output. Guards against silent corruption of `triggers:` YAML lists.
1. **Symlink break-out**: with `~/.claude/commands` as a symlink to `$REPO/commands`, run `sync --global`. Confirm the symlink is replaced with a real directory, populated from source, and `$REPO/commands/` has no diff.
2. **Init**: `bin/build-config init --global` creates a config.yaml from the example.
3. **Default fanout**: with `default_model: sonnet`, `sync --global` produces `model: sonnet` in every file under `~/.claude/commands/`.
4. **Per-skill override**: `skills.ship: opus` → only `~/.claude/commands/ship.md` shows opus; rest stay sonnet.
5. **Bucket resolution**: `task_models.mechanical: haiku` → `~/.claude/commands/wrap.md` (bucket=mechanical) flips to haiku, others unchanged.
6. **Snapshot / no-op**: snapshot `~/.claude/commands/` before sync with empty config → expect zero diff on unchanged files. Run sync twice back-to-back → second run writes zero files (mtime unchanged).
7. **Missing-config no-op**: with `~/.claude/build/config.yaml` deleted, `sync --global` exits 0 with the friendly "no global config found" message and touches no files.
8. **Project materialization**: in a scratch project with `.build/config.yaml` containing `skills.wrap: opus`, `sync --project` creates `<project>/.claude/commands/wrap.md` (carries `managed: build-os` + `model: opus`); no other skills materialized.
9. **Project removal**: remove the wrap override, re-sync → `<project>/.claude/commands/wrap.md` deleted.
10. **Hand-written safety**: place a project-local `.claude/commands/note.md` (no `managed:` marker); sync twice → file untouched both times.
11. **Hand-edit warning**: hand-edit body of a materialized managed file → sync warns and skips; sync `--force` overwrites.
12. **`show`**: `bin/build-config show ship` prints resolution trace (source layer for the winning value).

Manual (added to `/wrap` checklist — human-in-the-loop):

- **M1**: In a live Claude Code session, `/model haiku` then invoke a synced skill with `model: opus` → confirm the frontmatter wins for that turn and session returns to haiku after.
- **M2**: Retrofit an existing project: `cd` there, `bin/build-config init --project`, edit, `sync --project`, verify materialized files behave.

## Out of scope for v1

- Fallback models (e.g. try opus, fall back to sonnet if unavailable) — YAGNI.
- Per-turn / per-phase model switching inside a single skill — only static per-skill selection.
- Auto-sync on config change (git hook, filesystem watcher) — sync is manual; docs mention it in AGENTS.md `[Config]`.
