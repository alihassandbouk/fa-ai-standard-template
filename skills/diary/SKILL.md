---
name: diary
description: The developer's personal work diary, shared by every repo on this machine. Write to it after a decision, after a long debug or research, and at session end; search it when the developer refers to earlier work, or before touching an area that may have history.
---

# Work diary

A single global journal, shared across every project and every session.
Storage: `~/.claude/diary/YYYY/MM/YYYY-MM-DD.<machine>.md`, one file per day
per machine, entries appended in time order. The `diary` CLI is the only
writer of a day file.

The CLI ships with this plugin: `${CLAUDE_PLUGIN_ROOT}/scripts/diary` (Python 3,
no dependencies). Use that path unless `diary` is on PATH. It works locally
with no setup. A developer who works on more than one machine, or wants a
backup, points it at a private git remote once with
`diary sync --remote <url>`; each machine writes only its own day files, so
machines never conflict, and `@name` after a timestamp marks an entry written
elsewhere.

## Reading

Search before assuming something is new, and whenever the user refers to
earlier work.

```bash
diary search "postgres owner"                 # all terms must match (AND)
diary search rainbow deploy --since 14d       # limit the window
diary search --type decision --since 3m       # every decision, last 3 months
diary search --project rainbow --tag nginx
diary search "certbot" --any --compact        # OR terms, titles only
diary recent 10                               # last 10 entries, any project
diary show 2026-08-20                         # one whole day
diary days --since 30d                        # which days have entries
diary search --machine wsl "certbot"          # only one machine's entries
```

`--since` / `--until` accept `YYYY-MM-DD`, `today`, `yesterday`, or a relative
span: `10d`, `3w`, `6m`, `1y`. Add `--json` when the output feeds further work.

When answering from the diary, quote the entry's date and say it came from the
diary, so the user knows it is recorded fact rather than inference.

## Writing

```bash
diary log --type decision \
  --project rainbow \
  --tags postgres,deploy \
  --title "One line, past tense, specific" \
  --body - <<'EOF'
- **Context:** what forced the decision
- **Decision:** what was chosen
- **Why:** the reasoning, including what was rejected and on what grounds
- **Next:** the open thread, if any
EOF
```

`--type` is one of: `session`, `decision`, `research`, `bug`, `note`, `todo`.
`--project` defaults to the basename of the working directory; set it
explicitly when the folder name is not the real project name.
Pass `--session "$CLAUDE_SESSION_ID"` on the end-of-session entry when the id
is available; the Stop hook uses it to tell whether the session was logged.

### Syncing

Run `diary sync` at the end of a session that wrote entries, and when a
session opens on a machine that may be behind. It commits, pulls, and pushes
in one step. If it reports it cannot reach the remote, the entries are still
committed locally: say so and carry on.

### When to write

- **End of every session** where real work happened: one `session` entry
  covering what changed, what was decided, and what is still open.
- **Immediately after a key decision**: architecture, dependency, schema,
  deploy topology, security tradeoff, or anything the user might reasonably
  ask "why did we do it that way" about in a month. Write it while the
  reasoning is still exact.
- **After heavy research or a long debug**: record the conclusion and the
  dead ends, so the next session does not repeat the search.
- **After a non-obvious fix**: the symptom, the actual cause, and the fix.
  Symptom wording matters: it is what the user will search for later.
- **On request**: "log this", "note that down".

Skip it for trivial exchanges: a single lookup, a one-line edit, a question
answered with no work done. An entry that says nothing costs future searches.

### What a good entry contains

Write for a reader who has none of this session's context. The repo diary
(`/fa:remember`) follows the same advice.

- Name things concretely: real file paths, real command names, real hostnames.
- Record the *why*, not just the *what*. The what is recoverable from git; the
  why is not.
- Record rejected alternatives and the reason they were rejected. That is the
  part most often re-litigated.
- Note anything still unverified, so a later session knows not to trust it.
- Keep it to what would be useful in six months. Half a screen is usually right.
- Secrets stay out. Any credential-like value (key, token, password,
  passphrase, one-time code, private key, certificate, cookie, auth header,
  connection string, webhook secret) is referred to by name (`GHCR_PAT`,
  `DATABASE_URL`) or as `[REDACTED]`. When unsure whether a detail is
  sensitive, treat it as sensitive.
