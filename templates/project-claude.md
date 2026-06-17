# [Project Name]

<!-- 
  Starter CLAUDE.md for a new project using build-os.
  Fill in the sections below, then delete this comment block.
  Place this file at the root of your project as CLAUDE.md.
-->

## Build OS

**At the start of any development work, read `~/.claude/build/AGENTS.md`** — it has your operating instructions, skills index, agent roles, and memory protocol.

Also read before starting:
- `~/.claude/build/memory/collaboration.md` — how to work with this builder
- `memory/MEMORY.md` — recent project decisions and learnings (if it exists)

## Project Context

<!-- 1-2 sentences: what this project is and what it does -->

## Quality Gates

<!-- The exact commands to run typecheck + tests for this project -->

```bash
QUALITY_GATES="npm run typecheck && npm test"
```

Examples:
- TypeScript: `npm run typecheck && npm test`
- Ruby on Rails: `bundle exec rubocop && bundle exec rspec`
- Python: `ruff check . && pytest`
- Go: `go vet ./... && go test ./...`

## Tech Stack

<!-- 
  Language, frameworks, key libraries.
  Agents use this to make appropriate implementation choices.
-->

- Language: 
- Framework: 
- Testing: 
- Key libraries: 

## Development Workflow

| Situation | Command |
|-----------|---------|
| New feature or task | Discuss → `/plan` → `/ship` |
| Bug or regression | `/hotfix` |
| Review a plan before approving | `/review` |
| Have a PRD + worktree ready | `/build` |
| Risk-check before a big change | `/pre-mortem` |
| After significant work completes | `/post-mortem` |
| Before merging | `/wrap` |

For non-trivial work (3+ steps): plan first, don't just start coding.

## Project Structure

```
src/           ← application code
test/          ← tests
plans/         ← plans/{slug}/ per feature (plan.md, prd.md, prd.json, working-memory.md)
memory/        ← MEMORY.md index + entries/
.build/        ← expertise profiles + project-specific agents
```

## Domain Expertise

**Before non-trivial code work in this project, follow the `auto_load` procedure in `~/.claude/build/AGENTS.md` `[Expertise]`** — scan `.build/expertise/*/PROFILE.md` `scope:` frontmatter and load profiles whose globs match the files you're about to touch. This is reinforcement of AGENTS.md's auto_load (the actual behavior is driven there); the explicit hint here helps builders reading the project's own CLAUDE.md understand the loading model.

<!-- 
  If this project has domain profiles for subagents, document them here.
  Profiles live at: .build/expertise/{domain}/PROFILE.md
  
  Example:
  - api: .build/expertise/api/PROFILE.md — HTTP routes, middleware, auth
  - models: .build/expertise/models/PROFILE.md — data models, validations
-->

## Conventions

<!-- 
  Project-specific patterns agents should follow.
  Only list things that are non-obvious or differ from defaults.
  Code patterns live in the code — point to them.
-->

## Out of Scope

<!-- Anything agents should explicitly NOT do without asking -->
