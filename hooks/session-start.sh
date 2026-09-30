#!/usr/bin/env bash
# SessionStart: stdout is added to context.
# 1. one line about the personal diary  2. the last entry of each author's newest repo diary file
echo "Personal diary: run \`diary search <terms> --since 30d\` (CLI: ${CLAUDE_PLUGIN_ROOT:-<plugin root>}/scripts/diary) before working on an area that may have history; log decisions when they happen, not at the end."
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
files=$(ls "$root"/diary/repo/*-*-*.md 2>/dev/null | sort) || true
[ -n "$files" ] || exit 0
newest=$(printf '%s\n' "$files" | sed 's|.*/||; s|\..*||' | sort | tail -1)
echo
echo "Repo diary, newest day $newest. Restore from it: summarise last session, open threads and next step, and confirm with the developer before building."
for f in $(printf '%s\n' "$files" | grep "/$newest\."); do
  echo; echo "--- ${f#$root/}"
  awk '/^## /{buf=""} {buf=buf $0 "\n"} END{printf "%s", buf}' "$f"
done
