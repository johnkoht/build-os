# Build Standards

Generic quality standards for any software project. Projects can supplement with a `build-standards.local.md` alongside this file, or document overrides in their `CLAUDE.md`.

---

## Quality Gates

Every task must pass these before being marked complete. The specific commands depend on the project (see project CLAUDE.md for `QUALITY_GATES`).

Common gate patterns:
- **TypeScript**: `npm run typecheck && npm test`
- **Ruby**: `bundle exec rubocop && bundle exec rspec`
- **Python**: `ruff check . && pytest`
- **Go**: `go vet ./... && go test ./...`

Gates are non-negotiable. If they fail, fix the code — don't skip the gate.

---

## Testing Requirements

| Change Type | Required Tests |
|-------------|----------------|
| New function/module | Happy path, edge cases, error handling |
| Bug fix | Regression test reproducing the bug BEFORE fixing |
| Refactor | Existing tests pass; new tests for new behavior |
| New integration | Integration test with realistic data |
| Schema/config change | Valid AND invalid input tests |
| Documentation only | No tests required — note it explicitly |

### Red Flags (Block Approval)

- "Tests are TODO"
- "Will add tests in follow-up"
- "This is too simple to test"
- Test count decreased without clear justification
- Tests only check that functions exist, not behavior

---

## Code Quality

### General Principles

**DRY** — Don't repeat logic. If you use the same pattern in 2+ places, extract it.

**KISS** — The simplest implementation that meets acceptance criteria. Not simpler, not more complex.

**No magic** — Constants over literals. Named variables over cryptic expressions. Self-documenting code.

**Error handling** — Handle errors at the right level. Don't swallow exceptions silently. Provide useful error messages.

**No guessing at the call site** — Types, parameter names, and function signatures should make intent obvious.

### TypeScript-Specific (when applicable)

- No `any` types — use `unknown` and narrow, or define the type
- Minimize `as` type assertions — they're usually a sign of a type design problem
- Use `.js` extensions in imports (NodeNext module resolution)
- Strict mode on

### Commits

Format: `type(scope): description`

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

Examples:
- `feat(auth): add OAuth2 token refresh`
- `fix(api): handle null response from upstream`
- `refactor(search): extract scoring logic into separate module`

One logical change per commit. Quality gates must pass before committing.

---

## LEARNINGS.md Protocol

LEARNINGS.md files live co-located with the code they document. They capture **non-obvious** information that would otherwise be rediscovered the hard way.

### Write an entry when:
1. You fix a regression or bug — document what broke, why, and how to avoid it
2. You use an API or pattern for the first time in this codebase — document what it is and any non-obvious setup
3. You make a design decision a future developer might reasonably question — document "we chose X over Y because Z"

### Do NOT write an entry for:
- Obvious things any developer would know
- Things already in the README or docs
- Temporary state (in-progress work, debugging notes)

### Format for entries:
```markdown
## [Short descriptive title]

**What**: [One sentence description]
**Why this matters**: [Why a developer would want to know this]
**Details**: [Specifics, gotchas, examples]
**Source**: [PRD name, date, or "discovered during X"]
```

### Path resolution:
Check for LEARNINGS.md in the file's directory, then one level up. If none exists and the gotcha is worth capturing, create one.

---

## Plan & PRD Standards

### Acceptance Criteria must be:
- **Testable** — can be verified with code or observation
- **Specific** — not "works properly" but "returns 200 on success, 400 on invalid input"
- **Bounded** — clear scope, not open-ended

### AC anti-patterns to flag:
- "Works correctly" (what does correct mean?)
- "Handles errors" (which errors? how?)
- "Is performant" (by what measure?)
- "Is well-tested" (how many tests? what coverage?)

### Task sizing:
- **Tiny** (1-2 steps, 1 file): Act directly
- **Small** (3 steps, ≤2 files): Developer + reviewer, no worktree needed
- **Medium** (4-6 steps, 3+ files): Full /ship flow
- **Large** (7+ steps): /ship with multi-phase if needed
