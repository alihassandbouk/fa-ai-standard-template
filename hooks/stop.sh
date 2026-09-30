#!/usr/bin/env bash
# Stop: nudge once per session to run /fa:remember save when work happened in
# an FA repo and the repo diary is older than that work.
input=$(cat)
case "$input" in *'"stop_hook_active":true'*) exit 0;; esac
sid=$(printf '%s' "$input" | sed -n 's/.*"session_id":"\([^"]*\)".*/\1/p')
[ -n "$sid" ] || exit 0
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
[ -d "$root/diary/repo" ] || exit 0
marker="${TMPDIR:-/tmp}/fa-remember-$sid.nudged"
[ -e "$marker" ] && exit 0
# latest work: newest modified tracked/untracked file ...
work=0
for p in $(git -C "$root" status --porcelain 2>/dev/null | cut -c4- | sed 's/.* -> //'); do
  [ -e "$root/$p" ] || continue
  t=$(stat -c %Y "$root/$p" 2>/dev/null || stat -f %m "$root/$p" 2>/dev/null); [ "${t:-0}" -gt "$work" ] && work=$t
done
# ... or the last commit, but only if a commit landed after the diary was last committed
c=$(git -C "$root" log -1 --format=%ct 2>/dev/null)
dc=$(git -C "$root" log -1 --format=%ct -- diary/repo 2>/dev/null)
[ "${c:-0}" -gt "${dc:-0}" ] && [ "$c" -gt "$work" ] && work=$c
[ "$work" -gt 0 ] || exit 0
# latest diary entry
d=0; f=$(ls -t "$root"/diary/repo/*-*-*.md 2>/dev/null | head -1)
[ -n "$f" ] && d=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
[ "$d" -ge "$work" ] && exit 0
# ponytail: one nudge per session; the second Stop always passes (stop_hook_active or marker)
touch "$marker"
echo "The repo diary is older than the work in this session. Run /fa:remember save now, or reply that the session was trivial and stop." >&2
exit 2
