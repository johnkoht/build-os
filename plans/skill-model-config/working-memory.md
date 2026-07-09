# Working Memory — skill-model-config

Cross-task knowledge. Every developer reads this before starting and updates it after completing.

## Seeded context (from plan + pre-mortem + review)

- **`~/.claude/commands` is a symlink to `$REPO/commands`** — confirmed in `install.sh`. Task 1's sync MUST break this symlink on first `sync --global`, materializing `~/.claude/commands/` as a real directory. Source repo (`$REPO/commands/`) must stay upstream-clean.
- **10 skill files**, not 9 (Explore report said 9 but `ls` confirms 10): ship, build, hotfix, review, pre-mortem, plan-to-prd, post-mortem, wrap, build-os-retrofit, new-project.
- **Only two skills have non-scalar frontmatter**: `hotfix.md` and `build-os-retrofit.md` have block-style `triggers:` YAML lists. pyyaml round-trip must preserve them (see Task 1 AC 1.1 self-test).
- **pyyaml dump settings that matter**: `sort_keys=False, default_flow_style=False, allow_unicode=True, width=1000`. `width=1000` prevents pyyaml from soft-wrapping long description lines.
- **Env var contract for tests**: `BUILD_OS_CLAUDE_HOME` (default `~/.claude`), `BUILD_OS_REPO` (auto-detected from script location). All filesystem ops in `bin/build-config` go through these.
- **Allowlist**: `opus`, `sonnet`, `haiku`, `inherit`. Unknown values warn but don't hard-error (Claude Code accepts long-form model IDs like `claude-opus-4-7`).

## Discovered Patterns

*(Add: [Task N] pattern-name: description at file:line)*

## Active Gotchas

- `[seed]` `commands/hotfix.md` triggers list — do NOT lose this on round-trip. Task 1 has a fixture test.
- `[seed]` `install.sh` lines 10-31 handle the commands symlink — do NOT touch this logic in Task 6 (append hint only).
- `[seed]` Ship.md doesn't fit cleanly in "execution" (spans planning + execution + mechanical) — assigned to `execution` per plan; user can override via `skills.ship:` in config.

## Shared Utilities Created

*(Add: [Task N] functionName() in path/to/file)*

## Context Corrections

*(Add: [Task N] MISSING_CONTEXT: what was missing and where to find it)*
