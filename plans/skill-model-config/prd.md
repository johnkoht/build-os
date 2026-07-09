# PRD: skill-model-config

## Goal

Ship a user-configurable model-per-skill system for build-os with layered global → project overrides. Introduces `bin/build-config` (Python 3 CLI over pyyaml), layered `config.yaml` files at `~/.claude/build/` and `<project>/.build/`, and per-skill `bucket:` frontmatter, plus a symlink break-out on first global sync so `~/.claude/commands/` becomes a materialized copy and the source repo stays upstream-clean.

## Parent artifacts

- Plan: `plans/skill-model-config/plan.md` (approved, has_pre_mortem, has_review)
- Pre-mortem: `plans/skill-model-config/pre-mortem.md` (7 risks, 0 CRITICAL)
- Review: `plans/skill-model-config/review.md` (Approve with suggestions — 5 changes folded)
- Memory synthesis: `plans/skill-model-config/build-log.md` § Memory Synthesis

## Global execution rules (apply to every task)

Before opening Edit/Write on any file, the developer subagent MUST:

1. **Read explicit files first** — every task lists a `## Read first` block. Read those files in full before editing. Highest-impact practice per `~/.claude/build/memory/collaboration.md`.
2. **Anchor-string grep, not line numbers** — locate edit points by grepping for a nearby literal string, not by a hard-coded line number. Files may have drifted since the plan was written.
3. **Phantom-task check** — for any file this task creates, `ls`/`stat` first to confirm it doesn't already exist. For any string this task adds, grep the target file to confirm it isn't already present.
4. **Per-file grep ACs, not aggregate** — multi-file edits produce one grep per file, not one grep across all files.
5. **Sequential subagents** — never run two developer subagents in parallel on this codebase (hard constraint from collaboration.md corrections).
6. **Embedded pre-mortem mitigations** — every risk-related instruction from `pre-mortem.md` is repeated inline in the affected task below, not left as a cross-reference.

---

## Task 1: Create `bin/build-config` Python 3 CLI

**File**: `bin/build-config` (new, executable)

**Description**: Single-file Python 3 CLI that owns config resolution, frontmatter editing, and symlink break-out. Called by users directly and by hints emitted from `install.sh`. Uses `pyyaml` for frontmatter round-trip (parses and re-dumps with `sort_keys=False, default_flow_style=False, allow_unicode=True` so existing block-style `triggers:` lists survive intact).

### Read first

- `plans/skill-model-config/plan.md` (full — schema, precedence chain, sync mechanics)
- `plans/skill-model-config/pre-mortem.md` (Risks 1, 2, 3, 4 all apply here)
- `commands/hotfix.md` and `commands/build-os-retrofit.md` — the only two skills with block-style YAML list frontmatter (`triggers:`). Their round-trip is the load-bearing edge case.
- `install.sh` — see the current symlink behavior to preserve compatibility with the "break-out on first sync" flow.

### Required subcommands & flags

- `init [--global | --project]` — writes `build/config.yaml.example` contents to `~/.claude/build/config.yaml` (global) or `.build/config.yaml` (project). Errors if target exists (no overwrite without explicit `--force`).
- `sync [--global | --project | --all] [--force]` — default `--all`. Missing-config in a scope is a friendly no-op (`"no <scope> config found — run bin/build-config init --<scope> to create one"`, exit 0, touch nothing). `--force` bypasses hand-edit protection.
- `show [<skill>]` — prints a table (or single-line detail for `<skill>`) of skill → resolved model with the winning source layer.
- `--help` on every subcommand.

### Resolution algorithm

Precedence chain (highest wins), per skill:

1. Project `skills.<name>`
2. Project `task_models.<bucket-of-skill>`
3. Project `default_model`
4. Global `skills.<name>`
5. Global `task_models.<bucket-of-skill>`
6. Global `default_model`
7. `None` → delete `model:` field from the file

`inherit` is a **terminal** value: at any layer it means "use session model" and stops the chain (writes `model: inherit` or omits, TBD by simplest correct behavior — pick omit to keep files minimal; document this in `show`).

### Symlink break-out (first global sync)

Before writing any file in `~/.claude/commands/`:

```
if ~/.claude/commands is a symlink:
    target = readlink(...)
    if target == $REPO/commands:
        materialize: mkdir ~/.claude/commands.new, cp -a $REPO/commands/*.md ~/.claude/commands.new/
        rm ~/.claude/commands (symlink)
        mv ~/.claude/commands.new ~/.claude/commands
        print: "→ materialized ~/.claude/commands/ (was symlink to $REPO/commands). Re-run this after git-pulling build-os."
    else:
        error: "~/.claude/commands is a symlink to unexpected target: {target}"
elif ~/.claude/commands doesn't exist:
    error: "~/.claude/commands not found — run install.sh first"
else:
    # real directory — write in place
```

### Frontmatter round-trip (Risk 1 mitigation)

Use `pyyaml`:

```python
with open(path) as f: raw = f.read()
# split at ---, parse yaml block, edit dict, dump with:
yaml.safe_dump(fm, sort_keys=False, default_flow_style=False, allow_unicode=True, width=1000)
```

**Fixture test embedded in the CLI**: `bin/build-config self-test` (hidden subcommand) parses `commands/hotfix.md`, dumps it back, exits non-zero if bytes differ. Called by AC 1.

### pyyaml missing (Risk 2 mitigation)

On `import yaml` failure at CLI startup, print (to stderr, exit 2):

```
bin/build-config needs pyyaml. Pick one:
  pipx install pyyaml
  python3 -m venv ~/.claude/build/.venv && ~/.claude/build/.venv/bin/pip install pyyaml
  brew install libyaml && python3 -m pip install --user --break-system-packages pyyaml
Then re-run.
```

Do **not** attempt to auto-install.

### Model allowlist (Risk 3 mitigation)

Known values: `opus`, `sonnet`, `haiku`, `inherit`. On any value outside the allowlist:

- Print `warning: unknown model "{value}" at {source-layer} — did you mean "{nearest}"?` (Levenshtein distance ≤ 2).
- Continue syncing (unknown ≠ invalid — Claude Code accepts long-form model IDs).
- Exit non-zero if any warning fired unless `--force`.

### Hand-edit protection (Risk 4 mitigation)

Before overwriting a project-local managed file (has `managed: build-os` in frontmatter):

- Regenerate the file body from source in memory.
- Byte-compare to the file on disk.
- If differ → print `warning: {path} has been hand-edited since last sync; skipping. Use --force to overwrite.` Skip file. Exit non-zero.
- If match → overwrite freely.

Whole-file body compare, no persisted hash.

### Idempotence (Review Change 5)

Every write is preceded by a "would this write change bytes?" check: hash-compare in-memory buffer to file on disk. If identical, skip the write (preserve mtime).

### Acceptance criteria

- **AC 1.1 (round-trip)**: `bin/build-config self-test` exits 0. `commands/hotfix.md` and `commands/build-os-retrofit.md` round-trip byte-identical through pyyaml with the chosen dump settings. If not, fix dump settings until they do.
- **AC 1.2 (missing pyyaml)**: With pyyaml uninstalled, `bin/build-config init --global` exits 2, prints the three-option install message to stderr, and does NOT print a Python traceback.
- **AC 1.3 (symlink break-out)**: Given `~/.claude/commands` is a symlink to `$REPO/commands`, `sync --global` (against a scratch prefix — see AC 1.10) replaces the symlink with a real directory, populated with byte-identical copies of `$REPO/commands/*.md`. Second sync in the same session doesn't re-materialize.
- **AC 1.4 (default fanout)**: With `default_model: sonnet` (no other layers), `sync --global` produces `model: sonnet` in every skill file under `~/.claude/commands/` and touches no other bytes.
- **AC 1.5 (per-skill override)**: Adding `skills: {ship: opus}` above and re-syncing produces `model: opus` only in `ship.md`; all others keep `model: sonnet`.
- **AC 1.6 (bucket resolution)**: Adding `task_models: {mechanical: haiku}` and re-syncing produces `model: haiku` in `wrap.md` only (bucket=mechanical); ship still `opus`, others sonnet.
- **AC 1.7 (missing-config no-op)**: With `~/.claude/build/config.yaml` removed, `sync --global` exits 0, prints the friendly message, and writes nothing.
- **AC 1.8 (idempotence)**: `sync --global` twice back-to-back with unchanged config: second run writes zero files (mtime unchanged for every skill file — verified via `stat`).
- **AC 1.9 (allowlist warning)**: With `default_model: opuss`, `sync --global` exits non-zero (unless `--force`), prints `warning: unknown model "opuss" at global.default_model — did you mean "opus"?`.
- **AC 1.10 (scratch prefix)**: `bin/build-config` respects `BUILD_OS_CLAUDE_HOME` env var (defaults to `~/.claude`) so tests can point at `/tmp/skill-model-config-test/.claude` without touching the real home. Same for `BUILD_OS_REPO` (defaults to auto-detect from script path).
- **AC 1.11 (show)**: `bin/build-config show ship` prints one line: `ship → <model> (source: <layer-path>)`. Example: `ship → opus (source: global.skills.ship)`.
- **AC 1.12 (hand-edit)**: Materialize a project-local `wrap.md` via project sync, hand-edit its body, re-sync → warning printed, file unchanged, non-zero exit. Re-sync with `--force` overwrites.

**depends_on**: none.

---

## Task 2: Create `build/config.yaml.example` template

**File**: `build/config.yaml.example` (new)

**Description**: Annotated YAML template with every field, rationale comments per bucket, and per-skill override examples. Copied by `bin/build-config init` (as-is) and by `bin/new-project` (with all lines commented out).

### Read first

- `plans/skill-model-config/plan.md` § "Config schema"
- Task 1 above — the CLI is the consumer of this file.

### Content requirements

- Every field commented so `sync` on the unmodified example produces zero writes.
- Rationale comment before each `task_models` bucket explaining why that model was picked (planning = opus for depth; execution = sonnet for cost/speed at similar quality; mechanical = haiku for cheapness).
- Per-skill override examples showing both `<skill>: <model>` and `<skill>: inherit` forms.
- Header comment naming the precedence chain in one sentence, pointing to AGENTS.md `[Config]` for the full chain.

### Acceptance criteria

- **AC 2.1**: File exists at `build/config.yaml.example`, is valid YAML (`python3 -c "import yaml; yaml.safe_load(open('build/config.yaml.example'))"` exits 0).
- **AC 2.2**: Running `bin/build-config init --global` (with `BUILD_OS_CLAUDE_HOME` pointed at a scratch dir) copies this file verbatim; a subsequent `sync --global` writes zero files (every meaningful field is commented out in the example).
- **AC 2.3**: File contains at least one rationale comment per bucket (grep for `# planning`, `# execution`, `# mechanical`).
- **AC 2.4**: File contains an example each of `<skill>: <model>` and `<skill>: inherit`.

**depends_on**: task-1.

---

## Task 3: Add `bucket:` frontmatter to all 10 skill files

**Files** (edit each, multi-file):

- `commands/ship.md`, `commands/build.md`, `commands/hotfix.md`, `commands/new-project.md`, `commands/build-os-retrofit.md` → `bucket: execution`
- `commands/pre-mortem.md`, `commands/plan-to-prd.md`, `commands/review.md`, `commands/post-mortem.md` → `bucket: planning`
- `commands/wrap.md` → `bucket: mechanical`

### Read first

- One of `commands/ship.md` in full to confirm frontmatter shape (name/description).
- `commands/hotfix.md` and `commands/build-os-retrofit.md` in full — these have `triggers:` YAML lists; the `bucket:` field must not disturb the list.

### Exact edit pattern (per file)

For each skill file, locate the frontmatter block (bounded by `---` at lines 1 and N). Insert a new line `bucket: <value>` **immediately after** the `description:` line (which every file has). If `description:` spans multiple lines (none do today, but check), insert after the last line of the value.

**Anchor grep**: for each file, grep `^description: ` to find the anchor line. Insert bucket on the following line.

### Phantom-task check

For each file, before editing: `grep -c "^bucket: " commands/<file>.md` must return 0. If any returns > 0, halt task and report — someone else added bucket already.

### Acceptance criteria

- **AC 3.1** (per-file, execution bucket): each of `grep -c "^bucket: execution$" commands/ship.md`, `.../build.md`, `.../hotfix.md`, `.../new-project.md`, `.../build-os-retrofit.md` returns 1.
- **AC 3.2** (per-file, planning bucket): each of `grep -c "^bucket: planning$" commands/pre-mortem.md`, `.../plan-to-prd.md`, `.../review.md`, `.../post-mortem.md` returns 1.
- **AC 3.3** (per-file, mechanical bucket): `grep -c "^bucket: mechanical$" commands/wrap.md` returns 1.
- **AC 3.4** (triggers preserved): `commands/hotfix.md` and `commands/build-os-retrofit.md` still have their `triggers:` YAML list intact — `python3 -c "import yaml,sys; d=yaml.safe_load(open('commands/hotfix.md').read().split('---')[1]); assert isinstance(d.get('triggers'), list) and len(d['triggers']) > 0"` exits 0 (same for build-os-retrofit).
- **AC 3.5** (no body changes): `git diff commands/*.md` shows only added `bucket:` lines in frontmatter — zero changes to skill body content.

**depends_on**: none.

---

## Task 4: Add `[Config]` section to `build/AGENTS.md`

**File**: `build/AGENTS.md`

### Read first

- `build/AGENTS.md` in full (78 lines).
- Existing block-style sections `[Expertise]`, `[Skills]`, `[Memory]` for tone/format.

### Insertion point

Immediately **after** the `[Memory]` block. Anchor grep: `^\[Memory\]` — find the block, insert `[Config]` block after its last line (last line starts with `|after_work:`).

### `[Config]` block content

Format matches existing blocks: `[Name]|key:value` lines, `{...}` for nested. Content:

```
[Config]|per-skill model selection for build-os slash commands
|purpose:Layered YAML config controls which Claude model each skill runs on. Config → skill frontmatter is bridged by `bin/build-config sync` (not runtime).
|global:~/.claude/build/config.yaml (gitignored)
|project:<project>/.build/config.yaml (committable)
|precedence:project.skills → project.task_models[bucket] → project.default_model → global.skills → global.task_models[bucket] → global.default_model → (session model)
|buckets:planning | execution | mechanical — declared in each skill's `bucket:` frontmatter
|sync:`bin/build-config sync` writes `model:` into `~/.claude/commands/*.md`. First global sync replaces the `~/.claude/commands` symlink with a materialized directory; re-run after `git pull` in build-os.
|values:opus, sonnet, haiku, or `inherit` (use session model)
```

Also amend the existing `[Skills]|root:` line to add `,bucket:planning|execution|mechanical declared per skill; drives task_models resolution`. Anchor grep: `^\[Skills\]\|root:~/\.claude/commands`.

### Acceptance criteria

- **AC 4.1**: `grep -c "^\[Config\]" build/AGENTS.md` returns 1.
- **AC 4.2**: `[Config]` block contains all 7 keys above (purpose, global, project, precedence, buckets, sync, values). Verify with `grep -c "^|precedence:"` etc. — one hit each.
- **AC 4.3**: `[Skills]` line mentions buckets — `grep "^\[Skills\]" build/AGENTS.md | grep -c "bucket:"` returns 1.
- **AC 4.4**: No other block was modified — `git diff build/AGENTS.md` shows only additions.

**depends_on**: task-1 (block references `bin/build-config`).

---

## Task 5: Gitignore `build/config.yaml`

**File**: `.gitignore`

### Read first

- `.gitignore` in full (current: 5 lines, 2 patterns).

### Edit

Append after the last existing pattern (`build/standards/build-standards.local.md`):

```

# Per-skill model config — personal, not tracked
build/config.yaml
```

Anchor grep: `^build/standards/build-standards\.local\.md$`.

### Acceptance criteria

- **AC 5.1**: `grep -c "^build/config\.yaml$" .gitignore` returns 1.
- **AC 5.2**: Original two patterns still present — `grep -c "^build/memory/collaboration\.md$" .gitignore` and `grep -c "^build/standards/build-standards\.local\.md$" .gitignore` both return 1.

**depends_on**: none.

---

## Task 6: Update `install.sh` — post-install hint

**File**: `install.sh`

### Read first

- `install.sh` in full (72 lines).

### Edit

Append after the existing final echo/exit (grep for the last non-blank line of the script; append after it). Add:

```bash

echo ""
echo "→ Optional: run \`bin/build-config init --global\` to configure per-skill models."
echo "  First sync replaces the ~/.claude/commands symlink with a real directory."
echo "  Requires pyyaml — bin/build-config prints install instructions if missing."
```

Anchor grep: locate the current last echo line (`echo "✓ ..."` or similar) to insert after.

### Acceptance criteria

- **AC 6.1**: `grep -c "bin/build-config init --global" install.sh` returns 1.
- **AC 6.2**: `grep -c "replaces the ~/.claude/commands symlink" install.sh` returns 1.
- **AC 6.3**: `bash -n install.sh` exits 0 (script still parses).
- **AC 6.4**: Existing symlink logic (lines that grep for `ln -sf`) unchanged — no diff on those lines.

**depends_on**: task-1, task-2.

---

## Task 7: Update `bin/new-project` — scaffold `.build/config.yaml`

**File**: `bin/new-project`

### Read first

- `bin/new-project` in full (237 lines) — pay attention to the existing `.build/` scaffolding logic (referenced in Explore report as lines 98, 162–185).
- `build/config.yaml.example` (created in Task 2).

### Edit

Within the `.build/` scaffolding block, after the existing `expertise/` and `agents/` scaffolding, add a step that copies `build/config.yaml.example` to the new project's `.build/config.yaml` — with every non-comment line prefixed with `# ` so the file starts as a fully-commented opt-in template. Print a hint on success: `→ scaffolded .build/config.yaml (all commented out — uncomment fields to override global model config)`.

Anchor grep: locate the end of the current `.build/` scaffolding by grepping for `.build/agents/` or similar terminal marker; insert after.

### Acceptance criteria

- **AC 7.1**: `grep -c "config.yaml.example" bin/new-project` returns at least 1 (the copy step).
- **AC 7.2**: `bash -n bin/new-project` exits 0.
- **AC 7.3**: Running `bin/new-project` against a scratch directory produces a `.build/config.yaml` where every non-blank line begins with `#` (verified: `grep -c "^[^#]" scratch/.build/config.yaml` returns 0, excluding blank lines).
- **AC 7.4**: Existing `expertise/` and `agents/` scaffolding logic unchanged (git diff shows only the new config.yaml step added).

**depends_on**: task-2.

---

## Task 8: Manual verification checklist

**File**: `plans/skill-model-config/verification-manual.md` (new)

**Description**: Non-code deliverable. Documents the two verification steps that require a live Claude Code session or an existing project outside the source repo — folded into the `/wrap` phase per pre-mortem Risk 6 mitigation.

### Content

Markdown checklist with two sections:

```markdown
# Manual Verification — skill-model-config

Run these AFTER `/wrap` verifies automated ACs pass, BEFORE merge.

## M1: Live-session frontmatter model wins

- [ ] Open a new Claude Code session; set session model to haiku: `/model haiku`.
- [ ] Ensure global config sets `skills.ship: opus` and `bin/build-config sync --global` has run.
- [ ] Invoke `/ship` (or any skill with `model: opus` in frontmatter).
- [ ] Confirm the turn runs on Opus (check status line / model indicator).
- [ ] After the turn, confirm session returns to Haiku.

## M2: Retrofit an existing project

- [ ] `cd` to an existing project (e.g. `~/code/homelab` or any other build-os-using repo).
- [ ] Run `bin/build-config init --project` → creates `.build/config.yaml`.
- [ ] Edit `.build/config.yaml`: set `skills: {wrap: opus}`.
- [ ] Run `bin/build-config sync --project`.
- [ ] Verify `.claude/commands/wrap.md` was created with `managed: build-os` and `model: opus`.
- [ ] Verify no other skills were materialized in `.claude/commands/`.
- [ ] Remove the override, re-sync → `.claude/commands/wrap.md` deleted.
```

### Acceptance criteria

- **AC 8.1**: File exists at `plans/skill-model-config/verification-manual.md`.
- **AC 8.2**: Both M1 and M2 sections present, formatted as markdown checklists with actionable steps.
- **AC 8.3**: File is referenced from `plans/skill-model-config/build-log.md` § Session Notes as "manual verification pending at /wrap phase."

**depends_on**: task-1 (references `bin/build-config` in checklist steps).

---

## Verification Summary

Automated ACs above cover verification steps 0–12 from `plan.md`. Manual steps M1, M2 are Task 8's deliverable and become a `/wrap` phase checklist item.

## Out of scope (v1)

- Fallback models on unavailable model.
- Per-turn / per-phase model switching within a single skill.
- Auto-sync on config change (git hook, file watcher).
- Bulk-fixing user-config drift after upstream skill body changes (user re-runs sync manually).
