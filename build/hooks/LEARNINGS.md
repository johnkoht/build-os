# LEARNINGS — build/hooks/

Gotchas and invariants for the build-os PreToolUse guardrail hooks.

## Invariants (do not break)

- **Fail-open, always.** Every hook must `exit 0` on ANY ambiguity: no `jq`, empty/malformed stdin,
  not a git repo, missing `file_path`, relative path with no `cwd`, path outside the toplevel.
  These hooks run on EVERY matching tool call in EVERY repo — a non-fail-open bug breaks editing
  machine-wide. Never emit `exit 2` except via the intended decision path (and the decision path
  uses stdout JSON + `exit 0`, not exit 2).
- **Self-gate by `.build/` marker.** Do nothing (exit 0) unless the file's git toplevel has a `.build/`
  dir. This keeps the hooks inert in non-build-os repos and in build-os itself (which has no `.build/`).
- **Allowlist by DIRECTORY, never by file extension.** build-os's own source is markdown, so an
  extension-based allowlist would be a no-op here. Allowlist: `plans/`, `memory/`, `.build/`, `LEARNINGS.md`.

## Gotchas

- **macOS symlink canonicalization.** `mktemp -d` yields `/var/folders/...` (a symlink) while
  `git rev-parse --show-toplevel` yields the canonical `/private/var/folders/...`. To compute the
  repo-relative path, canonicalize the file's dir with `cd "$dir" && pwd -P` BEFORE stripping the
  toplevel prefix — otherwise the prefix never matches and allowlisting silently fails.
- **git-dir is relative in the main checkout.** `git rev-parse --git-dir` returns `.git` (relative) in
  the main checkout but an absolute `.../.git/worktrees/<name>` in a linked worktree. Resolve to
  absolute (`cd "$file_dir" && cd "$git_dir" && pwd -P`) before the `*/worktrees/*` substring test.
- **`EnterPlanMode` hookability is unverified.** `plan-redirect.sh` is built defensively; whether a
  PreToolUse matcher on `EnterPlanMode` actually fires in a given Claude Code version must be checked
  manually (see README.md). Fallback: the CLAUDE.md `/plan` callout.
- **Absolute paths in settings.json.** Wire hooks with `/Users/johnkoht/.claude/build/hooks/...`
  (resolves through the `~/.claude/build` symlink). `~` expansion in hook command paths is undocumented.

## Tests

Each hook has a `test-*.sh` harness using temp git repos. Run them after any change; they assert the
fail-open cases + the allowlist both directions. Never let a hook change ship without green tests.
