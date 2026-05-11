# build-os

A personal build operating system for Claude Code. Product-agnostic process tools, agent roles, and slash commands for autonomous software development.

## What's in here

```
commands/        → slash commands (/ship, /build, /hotfix, etc.)
build/
  AGENTS.md      → build OS identity, roles, skills index, memory protocol
  agents/        → orchestrator, reviewer, developer, gitboss personas
  standards/     → quality gates, coding principles
  memory/        → collaboration.md (local, gitignored) + example template
templates/       → starter CLAUDE.md for new projects
install.sh       → symlinks everything into ~/.claude/
```

## Install

```bash
git clone https://github.com/johnkoht/build-os ~/code/build-os
cd ~/code/build-os && ./install.sh
```

This symlinks `commands/` and `build/` into `~/.claude/`, creates `~/.claude/CLAUDE.md` if absent, and seeds `build/memory/collaboration.md` from the example.

## Per-project setup

Copy `templates/project-claude.md` to your project as `CLAUDE.md` and fill in:
- `QUALITY_GATES` — your project's typecheck + test commands
- Domain expertise profiles (optional) in `.build/expertise/{domain}/PROFILE.md`

## Personal preferences

`~/.claude/build/memory/collaboration.md` is gitignored — it accumulates your preferences and corrections across projects locally. Seed it from `build/memory/collaboration.md.example`.

## Upgrading

```bash
cd ~/code/build-os && git pull
```

Symlinks pick up changes automatically.
