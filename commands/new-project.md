---
name: new-project
description: Scaffold a new project with build-os structure (CLAUDE.md, plans/, memory/, .build/). Use when you're already inside Claude Code.
---

# New Project

Scaffold build-os structure for a new or existing project. Creates CLAUDE.md, directories, and initial memory index.

Use this when you're already in Claude Code. For a fresh project from the terminal, run:
```bash
new-project <name> [--lang typescript|ruby|python|go]
```

---

## What to Provide

Tell me:
1. **Project name** — what are we building?
2. **Language/framework** — TypeScript, Ruby, Python, Go, other?
3. **Directory** — where does this live? (default: current directory)

---

## What Gets Created

```
CLAUDE.md              ← project instructions with QUALITY_GATES, tech stack
plans/                 ← plans/{slug}/ for each feature
memory/
  MEMORY.md            ← memory index
  entries/             ← post-mortem entries land here
.build/
  README.md            ← how to add expertise profiles and project agents
  expertise/           ← domain profiles for subagents (Layer 4)
  agents/              ← project-specific agent personas
```

---

## Workflow

1. Ask for project name, language, and directory if not provided
2. Create the directory structure above
3. Generate CLAUDE.md from template with:
   - Project name filled in
   - `QUALITY_GATES` set for the chosen language
   - Tech stack section ready to fill in
4. Present the created structure
5. Remind to fill in: project context, conventions, any domain-specific notes

---

## CLAUDE.md Quality Gates by Language

| Language | QUALITY_GATES |
|----------|--------------|
| TypeScript | `npm run typecheck && npm test` |
| Node.js | `npm test` |
| Ruby | `bundle exec rubocop && bundle exec rspec` |
| Python | `ruff check . && pytest` |
| Go | `go vet ./... && go test ./...` |

---

## Adding Project-Specific Agents

After scaffolding, project-specific agent personas live at `.build/agents/{name}.md`. Use the same frontmatter format as global agents (`~/.claude/build/agents/*.md`).

Example — a security reviewer for a fintech project:

```markdown
---
name: security-reviewer
description: Security-focused reviewer for payment and auth code
---

You are a security reviewer with expertise in payment processing and authentication...
```

Reference in `CLAUDE.md`:
```
[Project Agents]
|security-reviewer:.build/agents/security-reviewer.md — payments and auth review
```

The orchestrator can then spawn it for tasks touching payment or auth code.
