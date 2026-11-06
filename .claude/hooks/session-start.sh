#!/bin/bash
# SessionStart hook: orientation, not setup.
#
# CLAUDE.md loads automatically, but docs/, the decisions and the open
# backlog don't. This prints a short index into context at session start.
# Keep it short, because every session pays for it. Facts belong in docs/,
# not here. No network, no installs, no secrets.
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"

echo "── Keyboard: where knowledge lives ──────────────────────────────"
echo "durable → CLAUDE.md + docs/   |   why → docs/decisions/   |   open work → Issues   |   shipped → changelogs/"
echo "PUBLIC REPO: never commit secrets, tokens, webhook URLs, private hostnames or personal details."
echo

if [ -d docs ]; then
  shown=0
  for f in docs/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" = "README.md" ] && continue
    [ $shown -eq 0 ] && echo "docs/ — current reference, edited in place:"
    shown=1
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')
    printf '  %-28s %s\n' "$(basename "$f")" "$title"
  done
  [ $shown -eq 1 ] && echo
fi

# Decisions are printed in full so they're seen BEFORE someone proposes
# something already settled.
if [ -d docs/decisions ]; then
  shown=0
  for f in docs/decisions/[0-9]*.md; do
    [ -e "$f" ] || continue
    [ $shown -eq 0 ] && echo "docs/decisions/ — settled; read before proposing a substrate, schema, library or rewrite:"
    shown=1
    title=$(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# ADR-[0-9]*: //')
    status=$(grep -m1 '^- \*\*Status:\*\*' "$f" 2>/dev/null | sed 's/.*Status:\*\* //')
    case "$status" in
      Accepted) mark="" ;;
      *)        mark=" [$status]" ;;
    esac
    printf '  %-6s %s%s\n' "$(basename "$f" | cut -d- -f1)" "$title" "$mark"
  done
  [ $shown -eq 1 ] && { echo "  → disagree with one? supersede it with a new record; don't re-litigate silently."; echo; }
fi

echo "Open work: GitHub Issues on gharden91/keyboard — list them before planning anything."
echo

echo "Recently shipped:"
git log --date=short --pretty='  %ad  %s' -5 2>/dev/null || true
echo

echo "Before you finish: run /handoff. Distill, don't dump."
echo "─────────────────────────────────────────────────────────────────"
