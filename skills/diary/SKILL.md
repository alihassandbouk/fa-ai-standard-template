---
name: diary
description: "Read from and write to the developer's personal work diary — a single append-only journal at ~/.claude/diary shared by every Claude Code session in every folder on this machine, optionally synced to a private git remote. Use it to WRITE at the end of a session, after any key decision (architecture, tooling, schema, deploy, tradeoff accepted), after heavy research or long debugging, and whenever something was learned that a future session would otherwise have to rediscover. Use it to READ whenever the user refers to past work — 'what did we decide about X', 'why did I do it this way', 'last week', 'a few days ago', 'remind me', 'we already fixed this' — or before starting work on an area that may have prior history."
---

# Work diary

A single global journal, shared across every project and every session.
Storage: `~/.claude/diary/YYYY/MM/YYYY-MM-DD.<machine>.md` — one file per day
per machine, entries appended in time order. The `diary` CLI is the only thing
that should write to it — never hand-edit or overwrite a day file.

The CLI ships with this plugin: `${CLAUDE_PLUGIN_ROOT}/bin/diary` (Python 3,
no dependencies). Use that path unless `diary` is on PATH. It works locally
with no setup. A developer who works on more than one machine, or wants a
backup, points it at a private git remote once with
`diary sync --remote <url>`; each machine writes only its own day files, so
machines never conflict, and `@name` after a timestamp marks an entry written
elsewhere.

## Reading

Search before assuming something is new. Always run a search when the user
refers to earlier work.

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
is available — the Stop hook uses it to tell whether the session was logged.

### Syncing

Run `diary sync` at the end of a session that wrote entries, and when a
session opens on a machine that may be behind. It commits, pulls, and pushes
in one step. If it reports it cannot reach the remote, the entries are still
committed locally — say so and carry on rather than retrying in a loop.

### When to write

- **End of every session** where real work happened — one `session` entry
  covering what changed, what was decided, and what is still open.
- **Immediately after a key decision** — architecture, dependency, schema,
  deploy topology, security tradeoff, or anything the user might reasonably
  ask "why did we do it that way" about in a month. Do not wait for the end
  of the session; write it while the reasoning is still exact.
- **After heavy research or a long debug** — record the conclusion and the
  dead ends, so the next session does not repeat the search.
- **After a non-obvious fix** — the symptom, the actual cause, and the fix.
  Symptom wording matters: it is what the user will search for later.
- **On request** — "log this", "note that down".

Skip it for trivial exchanges: a single lookup, a one-line edit, a question
answered with no work done. An entry that says nothing costs future searches.

### What a good entry contains

Write for a reader who has none of this session's context.

- Name things concretely: real file paths, real command names, real hostnames.
- Record the *why*, not just the *what*. The what is recoverable from git; the
  why is not.
- Record rejected alternatives and the reason they were rejected. That is the
  part most often re-litigated.
- Note anything still unverified, so a later session knows not to trust it.
- Keep it to what would be useful in six months. Half a screen is usually right.

Never put secrets in the diary — no passwords, tokens, private keys, or full
connection strings. Refer to them by name (`GHCR_PAT`, `DATABASE_URL`) instead.
