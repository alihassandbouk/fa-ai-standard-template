#!/usr/bin/env bash
# PreToolUse(Bash): block destructive git before it runs. Adapted from Matt Pocock's
# git-guardrails-claude-code (MIT). Plain `git push` stays allowed; the developer asks for it.
cmd=$(python3 -c 'import sys,json; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null) || exit 0
for p in 'push[^|;&]*(--force( |$)|-f( |$)|\+)' 'reset --hard' 'clean -[a-z]*f' 'branch -D' '(checkout|restore)( --)? \.( |$)' 'push --delete' 'filter-branch'; do
  if printf '%s' "$cmd" | grep -qE "git[^|;&]*$p"; then
    echo "BLOCKED: '$cmd' matches '$p'. Destructive git is reserved for the developer; ask them to run it." >&2
    exit 2
  fi
done
exit 0
