# Decisions

**One file per decision. Written once, never edited, superseded rather than
updated.**

This folder exists for the thing the other homes can't hold: **a decision
that produces no diff.** `docs/` explains why the things that exist are the
way they are, and Issues hold what's next. But an hour spent deciding *not*
to build something leaves no trace anywhere else, so next session it gets
proposed, argued and decided all over again.

## Read this before proposing an approach

If you are about to suggest a substrate, a schema shape, a library, or a
rewrite, **check the index below first.** If a record already covers it,
either build on that decision or make the case for superseding it. Don't
quietly argue it again.

A record is not a rule you can't question. Every one carries a **What would
change our mind** section, which says exactly when reopening is legitimate.

## What earns a record

- A choice between real alternatives, with the reason the losers lost.
- A decision **not** to do something. These are the most valuable.

Not: "we used the existing helper", or anything the diff already explains.

## Writing one

Copy [`TEMPLATE.md`](TEMPLATE.md) to `NNNN-short-slug.md`, numbered next in
sequence. Pick the number after merging `main` into your branch, so two
branches don't take the same one. Keep it to one screen and add a row below.
This repo is public, so nothing secret or private goes in a record.

## Index

| # | Decision | Status | Scope |
|---|---|---|---|
| [0001](0001-hit-width-fills-column-pitch.md) | Key hit targets fill the column pitch; no 42 pt width floor on iPhone portrait or in Compact | Accepted | Layout |
| [0002](0002-keylayout-holds-its-mode.md) | `KeyLayout` holds its mode; everything takes bounds; modules are KB-prefixed | Accepted | `Shared/` |
