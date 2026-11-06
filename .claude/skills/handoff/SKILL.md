---
name: handoff
description: Memorialize a work session into the repo's knowledge system before context is lost — decision records for choices made, issues for discovered work, docs updates for changed behavior, changelog entries for what users will see. Use at the end of a session that produced anything worth keeping, when the user says "wrap up", "hand off", "write this up", "capture this", or when a long discussion has settled on decisions that produced no code. Also use proactively before ending a session where a real choice was made or a non-obvious thing was learned.
---

# Handoff

Distill this session into the knowledge system. **Distill, not dump.** A
record of everything a session did is unreadable, and so nobody reads it.

The test for every candidate: **will a future session be worse off without
this?** If not, let it go. Most of a session is not worth keeping, and saying
so is part of the job.

## 1. Work out what actually happened

```sh
git status --short
git diff --stat HEAD
git log --oneline origin/main..HEAD
```

**Then, before anything else, look for an open PR on this branch** with the
GitHub tools (list pull requests, head `gharden91:<branch>`, state open),
since cloud sessions have no `gh` CLI. The user often opens the PR
themselves mid-session, and git can't tell you. Assume one exists until
you've checked. If there is one, note its number: the changelog entries and
the ADR's *Shipped in* line link it, and step 7 updates its description.

Then re-read the conversation for things that left **no trace in the diff**.
That's where the value is, and it's the part that disappears when the
session ends:

- Options weighed and rejected, and why.
- A decision to *not* build something.
- A constraint discovered the hard way.
- A user preference stated once that should govern future work.
- An assumption that turned out to be wrong.

## 2. Route each item to its home

| What you have | Where it goes |
|---|---|
| A choice between real alternatives | A new record in `docs/decisions/` |
| A decision *not* to do something | A record. These are the most valuable, because they have no other trace |
| Changed behavior, data shape, or invariant | Edit `CLAUDE.md` and/or the `docs/` page **in place** |
| A change a user will notice | An entry in `changelogs/` |
| Something learned that cost an hour | The relevant `docs/` page |
| Work discovered but not done | A GitHub issue |
| What happened, blow by blow | **Nowhere.** That's what the diff and commit message are for. |

Read `docs/decisions/README.md` for what earns a record and what doesn't.
Read the "Finishing a piece of work" section of `CLAUDE.md` for the rules.

## 3. Write decision records

Copy `docs/decisions/TEMPLATE.md`, give it the next number in sequence, and
keep it to one screen.

Two sections carry the weight and are the ones to get right:

- **What we turned down**: the table. Without it a record is just an
  assertion, and the alternative gets proposed again next month.
- **What would change our mind**: concrete conditions for reopening. Without
  it the record reads as dogma and gets ignored.

If this session **reversed or replaced** an earlier decision, write a new
record and set the old one's status to `Superseded by ADR-NNNN` or `Reversed`.
**Never edit or delete the substance of an existing record.** A superseded
record is the only thing that stops the same idea coming back as if it were
new.

Then add the row to the index table in `docs/decisions/README.md`.

## 4. Update docs in place

If behavior changed, edit the relevant page **in place**. Don't append a note,
don't add an "as of August" clause, don't date anything. A page describing the
old behavior is worse than no page, because it reads as authoritative.

Delete what stopped being true. Check `CLAUDE.md` too. It holds the
invariants, and it drifts just as easily.

## 5. Add changelog entries

Every user-visible change gets one line in `changelogs/` (the index in
`changelogs/README.md` says which file). Refactors, test-only and docs-only
work get no entry.

- Put it under today's `## YYYY-MM-DD` heading at the top, creating the
  heading if it isn't there, then under `### Added`, `### Changed`,
  `### Removed` or `### Fixed`, in that order.
- Format: `- [#PR](https://github.com/gharden91/keyboard/pull/N) · [#issue](…/issues/N) · **Lead with the change.** Then what it means for the user, with the ADR behind it linked inline ([ADR-NNNN](../docs/decisions/NNNN-….md)).`
  Leave out the issue part if there is none.
- **No commit hash.** PRs are squash-merged, so the commit that lands on
  `main` doesn't exist until after the merge; the PR link leads to it. If
  there is no PR, ask the user whether to open one (don't open it unasked).
- **Append only.** Never edit or reword an entry already on `main`. If a
  change turned out wrong, the fix gets its own entry.

## 6. File issues, don't leave TODOs

Anything discovered and not done becomes a GitHub issue on
`gharden91/keyboard`. Never leave it in a code comment, a doc or the
conversation, because it will be lost there. **The issue tracker is public
too:** keep secrets and private details out of issue text.

If the session closed something already filed, close the issue and reference it
in the commit body.

## 7. Check for secrets, then commit

This repo is public. Before committing, read `git diff --cached` for keys,
tokens, webhook URLs, private hostnames or addresses, and personal details.
Anything like that comes out first (see `CLAUDE.md`).

Make one commit, with a body that explains **why**, not just what. The commit
message is itself part of the record.

Reference issues closed. Then push to the session's branch.

If the branch has an open PR, re-read its description against everything
now on the branch. A PR opened early describes only its first commit, so
update the body to cover what was added since, and say what wasn't
verified live.

## What to push back on

If the user asks to record something that doesn't clear the bar, say so rather
than filing it. A decisions folder with twelve real records is useful; one with
sixty, most of them "we used the existing helper", is a dumping ground.

Equally: if a session genuinely produced nothing worth recording, say that
and skip the ceremony. Not every session needs one.
