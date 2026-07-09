# Manual Verification — skill-model-config

The automated ACs in the PRD run inside `/build` against a scratch prefix
(`/tmp/skill-model-config-test/.claude`). Two verification concerns can't run
that way — they need either a live Claude Code session or an existing project
outside the source repo. Run them at `/wrap` before merge.

## M1: Live-session frontmatter model wins

- [ ] Open a new Claude Code session in a scratch directory.
- [ ] Set the session model to haiku: `/model haiku`.
- [ ] Ensure global config sets an override on a target skill (e.g. `skills: {ship: opus}` in `~/.claude/build/config.yaml`) and that `bin/build-config sync --global` has run.
- [ ] Invoke `/ship` (or the skill you overrode).
- [ ] Confirm the invoked turn runs on the frontmatter model (opus) — check the model indicator / status line.
- [ ] After the turn completes, confirm the session returns to haiku.

Pass condition: frontmatter `model:` wins for the skill's turn; session model unaffected outside the skill.

## M2: Retrofit an existing project with project config

- [ ] `cd` to an existing project (e.g. `~/code/homelab`, `~/code/arete-reserv`, or any repo using build-os).
- [ ] Run `bin/build-config init --project` → creates `.build/config.yaml`.
- [ ] Edit `.build/config.yaml`: uncomment or add `skills:` with `wrap: opus`.
- [ ] Run `bin/build-config sync --project`.
- [ ] Verify:
  - `.claude/commands/wrap.md` exists.
  - It carries both `managed: build-os` and `model: opus` in frontmatter.
  - No other skills were materialized in `.claude/commands/`.
- [ ] Remove the override (recomment the line), re-sync → `.claude/commands/wrap.md` deleted.
- [ ] Add an unrelated hand-written `.claude/commands/note.md` (no `managed:` marker) → sync twice → `note.md` untouched both times.

Pass condition: project overrides materialize only their intended files; removing an override cleans up; hand-written commands survive.
