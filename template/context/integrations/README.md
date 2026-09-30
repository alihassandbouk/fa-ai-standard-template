# Integrations

**Function:** One file per external technology/integration this project
depends on (e.g. `rabbitmq.md`, `auth.md`, `backend.md`, `frontend.md`,
`deployment.md`). Each file augments `code-standards.md` with the specific
conventions for that integration. Present-tense only.

Promote an integration file to a shared skill only when it becomes
multi-repo, script-needing, or too large to stay a single file.

---

## Template for a new integration file

```
# <Integration Name>

**Function:** How this project integrates with <technology>, and the
conventions specific to it.

## Setup / connection
_TODO_

## Conventions
_TODO_

## Gotchas
_TODO_
```
