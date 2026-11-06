# Keyboard

A split-layout software keyboard for iPhone and iPad, with swipe typing and
on-device English autocorrect. No network, no analytics. **The build spec is
[`SPEC.md`](SPEC.md)** (discussed in issue #2; the road map is issue #1).
Read its §3 (platform constraints) and §16 (hexagon: deferred, gated) before
proposing anything that touches them.

- [`docs/development.md`](docs/development.md): where Swift builds and tests
  run (Mac vs. cloud sessions; use the `keyboard` cloud environment, which
  installs Swift, so `swift test` on `Shared/` works there)

> Keep this file to invariants; put the depth in [`docs/`](docs/).

## This repository is public

Anything committed here can be read by anyone, permanently. Deleting it in a
later commit doesn't help, because git history keeps it.

- **Never commit a secret.** That means API keys, tokens, passwords, webhook
  URLs, private keys and any credentialed URL. Read them from the environment
  or from a git-ignored local file (`.env`, `*.local.json`; see `.gitignore`).
  If a file needs an example, commit `.env.example` with placeholder values.
- **Never commit personal or private infrastructure details.** That means
  internal hostnames, home-network addresses, email addresses other than the
  commit author's, and links to private repos or services. Write
  `example.com`, `192.0.2.x` or a placeholder instead.
- **Check before every commit:** `git diff --cached` and read it. If a secret
  slips through, treat it as leaked: rotate it first, then remove it from the
  code. Rewriting history doesn't un-publish it.
- Don't copy config or docs over from private repos (such as `gharden91/tools`)
  without removing anything private first.

## Where knowledge lives (read this first)

Each kind of knowledge has one home. Putting knowledge in the wrong place is
how plan folders go stale and stop being useful.

| Kind | Home | Rule |
|---|---|---|
| **Durable**: how it works, why, what not to break | **This file** (invariants) + [`docs/`](docs/) (depth) | Edited in place. Never dated. |
| **Decisions**: why this and not that | [`docs/decisions/`](docs/decisions/) | Immutable. Superseded, never edited. |
| **Open intent**: what's next, what was deferred | **GitHub Issues** | The only place open work lives |
| **Changelog**: what shipped | [`changelogs/`](changelogs/) | Append-only. New entries on top; old ones never edited. |
| **History**: what shipped, blow by blow | git log | Never the source of truth. |

**Before proposing a substrate, a schema shape, a library or a rewrite,
[check `docs/decisions/`](docs/decisions/).** If a record covers it, build on
that decision or make the case for superseding it. Don't quietly argue it
again. Every record has a *What would change our mind* section that says when
reopening it is legitimate. The folder exists for the one thing the other
homes can't hold: **a decision that produces no diff.** An hour spent
deciding *not* to do something leaves no other trace, and gets argued all
over again next session.

**The code outranks every document, including this one.** Prose drifts; the
code doesn't. When a doc and the source disagree, the source is right. Fix
the doc in the same commit rather than working around it. **Check the source
before you repeat anything you read in a doc**, especially anything you're
about to build on.

**Never put open work in a doc.** No "TODO", no "next steps", no "still open"
section in `CLAUDE.md`, `docs/` or a code comment. File an issue instead.

## Finishing a piece of work

Docs drift when updating them isn't part of shipping, so here it is part of
shipping. **Run [`/handoff`](.claude/skills/handoff/SKILL.md)** and it walks
this list; do it by hand if you'd rather.

0. **Is there already a PR for this branch?** Check with the GitHub tools
   before anything below; a PR is often opened mid-session, and git can't
   see it. Its number goes in the changelog and the ADR, and its description
   gets updated to cover everything on the branch.
1. **Did behavior, a data shape or an invariant change?** Update `CLAUDE.md`
   and/or the relevant `docs/` page **in the same commit**. Edit in place;
   don't append a note.
2. **Did users see a change?** Add an entry to
   [`changelogs/`](changelogs/README.md) under today's date:
   `[#PR](…) · [#issue](…) · what changed`, one line per user-visible change,
   filed under Added / Changed / Removed / Fixed.
3. **Did you choose between real alternatives, or decide *not* to do
   something?** Write a record in [`docs/decisions/`](docs/decisions/). The
   "decided not to" case matters most, because it leaves no other trace.
4. **Did you close out something from the backlog?** Close the issue, and
   reference it in the commit or PR body.
5. **Did you discover work you're not doing now?** File an issue.
6. **Did you learn something that cost you an hour?** Write it down in the
   relevant `docs/` page.
7. **Run the tests** if you touched tested code.
8. **Re-read the diff for anything secret or private** (see above).

Distill, don't dump. A session's blow-by-blow belongs in the diff and the
commit message, nowhere else.
