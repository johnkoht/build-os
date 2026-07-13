# Backlog: protocol-guardrails

Deferred items from this build. Each has a trigger for when to pull it forward.

## Deferred

- **`.build/.planning` read-only sentinel** — `/plan` drops a sentinel; the edit-guard hard-blocks
  ALL mutation (incl. Bash) until `/approve` clears it, recovering native plan mode's total read-only
  inside our own flow (the `plans/` allowlist still lets the plan artifact save).
  *Trigger:* if agents get action-happy during `/plan` (start editing/running things mid-planning).

- **SessionStart resident protocol injection** — inject a compact protocol reminder at session start.
  *Rejected for now* as resident-context bloat (John: "steer, don't bloat"). *Trigger:* if the
  event-driven hooks prove insufficient and drift persists in fresh sessions.

- **UserPromptSubmit approval-language nudge** — detect "go ahead / build it / lgtm" and inject a
  one-line "→ run /approve then /ship" when an approved plan exists.
  *Trigger:* if plans shaped in plain conversation (no `/plan`) still lead to ad-hoc builds.

- **Escalate edit-guard `ask` → `deny`** — make the edit-guard hard-block instead of prompting.
  *Trigger:* if the `ask` prompt is routinely click-approved without actually routing to /ship.

- **Statusline `⚠ MAIN` vs `⎇ worktree` indicator** — ambient signal in the statusline so drift is
  visible at a glance. *Trigger:* if John wants a human-side backstop beyond the hooks.

- **Separate `/fix` mini-build skill** — a dedicated fix→review→test loop distinct from `/hotfix`.
  *Not built:* strengthened `/hotfix` (mandatory reviewer + tests) covers the need. *Trigger:* if
  mid-execution multi-issue fixes need a shape `/hotfix`'s single-bug scope doesn't fit.

- **Retrofit build-os itself with `.build/`** — would make the guard + plan-redirect protect
  build-os's own development. *Deferred:* adding `.build/` makes the guards fire while editing the
  guards themselves (friction/bootstrap risk). *Trigger:* John's call — if he wants build-os
  development dogfooded through the guardrails.

- **Live-verify `EnterPlanMode` hookability** — the plan-redirect hook is built defensively but its
  live firing is unverified. *Trigger:* first post-install session — follow the manual check in
  `build/hooks/README.md`; if it doesn't fire, the CLAUDE.md `/plan` callout is the fallback.
