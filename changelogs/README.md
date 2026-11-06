# Changelogs

What shipped, in the [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/)
style. Each release heading is a date and each entry reads
**PR · issue · what changed**, with the ADRs behind it linked inline. Newest
first.

| Area | File |
|---|---|

## Adding an entry

Adding entries is part of shipping: step 2 of *Finishing a piece of work* in
[`CLAUDE.md`](../CLAUDE.md) and step 5 of
[`/handoff`](../.claude/skills/handoff/SKILL.md), which has the full rules.
In short:

- **One line per user-visible change.** Refactors, test-only and docs-only
  work get none.
- Under today's `## YYYY-MM-DD` at the top (create it if needed), then
  `### Added` / `### Changed` / `### Removed` / `### Fixed`, in that order.
- `- [#PR](https://github.com/gharden91/keyboard/pull/N) · [#issue](https://github.com/gharden91/keyboard/issues/N) · **Lead with the change.** Then what it means for the user ([ADR-NNNN](../docs/decisions/…)).`
- **No commit hash**: the squash commit doesn't exist until the merge, and
  the PR links to it.
- **Append only.** Never edit an entry already on `main`.
- **New area?** Create `changelogs/<area>.md` and add a row to the table
  above.
