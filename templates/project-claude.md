# [Project Name]

<!-- 
  Starter CLAUDE.md for a new project using build-os.
  Fill in the sections below, then delete this comment block.
  Place this file at the root of your project as CLAUDE.md.
-->

## Build OS

This project uses the build-os process. See `~/.claude/build/AGENTS.md` for skills, agent roles, and memory protocol.

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

## Project Structure

<!-- Key directories. Remove anything that doesn't apply. -->

```
src/           ← application code
test/          ← tests
dev/           ← build artifacts (plans, executions, memory)
  work/plans/  ← plan.md, prd.md, prd.json per feature
  executions/  ← execution state per feature
memory/        ← MEMORY.md index + entries/
```

## Domain Expertise

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
