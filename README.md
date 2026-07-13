# build-os

A personal build operating system for Claude Code. Product-agnostic process tools, agent roles, and slash commands for autonomous software development.

## Workflow

Non-trivial work routes through a gated flow — enforced by hooks, not just convention:

```
/plan  →  (iterate: keep editing / /approve)  →  /approve  →  /ship | /ship lite | /build
```

- **`/plan`** — plan-mode replacement. Explores read-only, discusses trade-offs, saves a draft to
  `plans/{slug}/plan.md`, and ends with a keep-editing / `/approve` gate. Never auto-executes.
- **`/approve`** — user-only gate. Marks the plan approved and prints the next-step menu.
- **`/ship`** — full plan-to-merge (pre-mortem → review → PRD → worktree → build → wrap → merge).
  **`/ship lite`** skips pre-mortem + review for 3-5 step, low-risk plans.
- **`/hotfix`** — structured bug fix with a mandatory reviewer. Fix requests route here, not ad-hoc.

### Guardrails (PreToolUse hooks)

In any project with a `.build/` marker, two hooks make the protocol hard to skip:
- **edit-guard** — `ask`-prompts when you edit source in the project's main checkout, routing you to
  `/ship` or `/hotfix` (allowlists `plans/`, `memory/`, `LEARNINGS.md`). Fail-open + `.build/`-scoped.
- **plan-redirect** — steers native plan mode to `/plan`.

Worktrees are standardized to `.claude/worktrees/` via the native `EnterWorktree` tool.

## What's in here

```
commands/        → slash commands (/plan, /approve, /ship, /build, /hotfix, etc.)
build/
  AGENTS.md      → build OS identity, roles, skills index, memory protocol
  agents/        → orchestrator, reviewer, developer, gitboss personas
  hooks/         → guardrail PreToolUse hooks (isolation-guard, plan-redirect) + tests
  standards/     → quality gates, coding principles
  memory/        → collaboration.md (local, gitignored) + example template
templates/       → starter CLAUDE.md for new projects
install.sh       → symlinks everything into ~/.claude/ + merges guardrail hooks
```

## Install (once per machine)

```bash
git clone https://github.com/johnkoht/build-os ~/code/build-os
cd ~/code/build-os && ./install.sh
```

This symlinks `commands/` and `build/` into `~/.claude/`, creates `~/.claude/CLAUDE.md` if absent,
seeds `build/memory/collaboration.md` from the example, and **merges the guardrail hooks into
`~/.claude/settings.json`** (backs up first, validates, idempotent) plus sets `worktree.baseRef: head`.
Restart Claude Code afterward so the hooks load.

> If you use per-skill model config (`build-config`), `~/.claude/commands` becomes a real directory
> instead of a symlink. In that case, run `build-config sync --global` after installing/upgrading so
> new or changed skills go live.

## Per-project setup

1. Copy `templates/project-claude.md` to your project as `CLAUDE.md` and fill in:
   - `QUALITY_GATES` — your project's typecheck + test commands
   - Domain expertise profiles (optional) in `.build/expertise/{domain}/PROFILE.md`
2. **Run `/build-os-retrofit`** to opt the project into the guardrails — it adds the `.build/` marker
   (which activates the hooks for that repo), gitignores `.claude/worktrees/`, and verifies the hooks.

New projects scaffolded with `new-project` get `.build/` and the gitignore entry automatically.

## Personal preferences

`~/.claude/build/memory/collaboration.md` is gitignored — it accumulates your preferences and
corrections across projects locally. Seed it from `build/memory/collaboration.md.example`.

## Upgrading

```bash
cd ~/code/build-os && git pull
```

Symlinks pick up `build/` and (if symlinked) `commands/` changes automatically. After an upgrade,
re-run `./install.sh` to pick up new hooks/settings, and `build-config sync --global` if your
`commands/` is materialized. See `CHANGELOG.md` for what's new.
