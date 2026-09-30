---
name: tfa-integration-fast-core
description: Integrate a third-party system with the FAST Core .NET platform — REST API (server-to-server or client-to-server), SSO against Identity Server 5 (backend-for-frontend or SPA), or read-only database views. Asks the user to pick the method first, then follows the matching guide. Use for any FAST Core / IMS integration, SSO sign-in, or FASTDB view mapping.
---

# TFA Integration Fast Core

Complete guide to integrating third-party systems with the core .NET infrastructure.

## Overview

The core system supports **4 integration methods**:

1. **REST API (Server-to-Server)** — Direct backend-to-backend integration authenticated with API keys or client-credentials tokens; no end-user context involved. Guide not written yet.
2. **REST API (Client-to-Server)** — Browser/client calls to the core backend, authenticated via a token issued through SSO on behalf of the signed-in user. Guide not written yet.
3. **SSO Integration** — Single Sign-On with Identity Server 5, letting a third party authenticate users against the core identity provider instead of managing its own credentials. See [guides/sso-server-side.md](guides/sso-server-side.md) (backend-for-frontend) or [guides/sso-client-side.md](guides/sso-client-side.md) (browser SPA: React, Angular, Vue, …).
4. **Database Views** — Direct read-only access to the core system's data through dedicated database views, for reporting or batch data sync where an API round-trip isn't needed. The code is the standard read-only stack in `tfa-development-guard`.

## Workflow — always start here

Do not pick a method on the user's behalf, and do not start writing code, until
the user has chosen one in Step 2.

### Step 1: Inspect the project

Before asking, look at what already exists so the question can say so:

- Search for an existing integration: `FASTDB`, `FastCore`, `AddJwtBearer`,
  `AddOpenIdConnect`, `HttpClient` registrations pointing at the core system.
- Note the project type (ASP.NET Core minimal APIs or controllers, frontend
  framework if any) and the .NET version.
- Check which guides exist under `guides/` (see [Guide availability](#guide-availability)).

### Step 2: Ask the user to choose the method

Use the **AskUserQuestion** tool so the user picks from an arrow-key list.
Ask exactly one question, single-select, with these options in this order.
Append " (already set up)" to a label when Step 1 found that method in the
project, and put "(Recommended)" on the first option only if the user's
request clearly points to it.

| Label | Description to show |
|---|---|
| `Database views` | Read-only queries against core database views, for reporting or bulk reads. Needs the connection string, view names and their columns. |
| `REST API server-to-server` | Your backend calls the core API with an API key or client-credentials token; no user involved. Needs credentials and the endpoints to call. |
| `SSO + REST client-to-server` | Users sign in through Identity Server 5, and the app calls the core API with their token (refreshed on 401). Needs authority URL, client ID/secret, redirect URI and scopes. |
| `SSO only` | Users sign in through Identity Server 5; no core API calls. Needs authority URL, client ID/secret and redirect URI. |

Use the header `Method` and the question
"Which FAST Core integration method do you want to set up?".
The user can always answer "Other"; if they do, map their answer onto one of
the methods above, or ask a follow-up if it fits none.

If the user rejects the question, stop and wait for their instruction rather
than choosing a method yourself.

### Step 3: Ask the method's follow-up questions

Again with **AskUserQuestion** (up to 4 questions in one call), collect only
the decisions that change what you build. Never ask for secrets in the
question — tell the user to set them with
`! dotnet user-secrets set "<key>" "<value>" --project <api project>`.

| Method | Follow-up questions |
|---|---|
| Database views | Which views to map (or "I'll paste the definitions"); what the data is for (read-only endpoints, enrich existing features, reporting). |
| REST API server-to-server | Authentication: API key, client credentials, or both; first use case (client + health check, specific endpoints, read from Swagger). |
| SSO + REST client-to-server | App shape (backend-for-frontend, recommended, or SPA with PKCE); which core endpoints the app calls. |
| SSO only | App shape (backend-for-frontend, recommended, or SPA with PKCE); replace existing sign-in or add alongside it; which user claims the app needs. |

### Step 4: Follow the chosen guide

| Choice | Guide |
|---|---|
| Database views | `tfa-development-guard/references/read-only-views.md` (sibling skill): `ReadOnlyDbContext`, `ToView` mappings, `IReadOnlyRepository`, audit logging, GET-only controller. Connection string key: `ConnectionStrings:FASTDB`. |
| REST API server-to-server | not written yet: build from the mandatory rules below |
| SSO + REST client-to-server | Backend-for-frontend: `guides/sso-server-side.md`; SPA: `guides/sso-client-side.md`. Then the client-to-server guide (not written yet) |
| SSO only | Backend-for-frontend: `guides/sso-server-side.md`; SPA: `guides/sso-client-side.md` |

If the chosen guide is missing, tell the user so, then build it from the
[Mandatory rules](#mandatory-rules-for-every-method) below instead of guessing
at undocumented core-system behaviour.

### Step 5: Verify and report

- Build and run the tests.
- Exercise the new endpoints or flows for real where possible (a local
  stand-in database or a locally issued token is fine; say so in the report).
- Record the integration in `context/architecture.md` under *System Boundaries* (what talks to what, auth, the settings keys). If the core team needs a hand-off document, write it as `docs/<name>-integration.md` shaped like `references/sso-integration-example.md`.
- Report what was built, what was verified, and what is still needed from the
  core team (credentials, schema, scopes).

## Guide availability

| Method | Guide |
|---|---|
| Database views | written (in `tfa-development-guard`) |
| SSO, backend-for-frontend | `guides/sso-server-side.md` |
| SSO, SPA | `guides/sso-client-side.md` + per-framework files in `guides/sso-client-side/` |
| REST API server-to-server | not written yet |
| REST API client-to-server | not written yet |

Update this table when a guide is added.

## Mandatory rules for every method

- **Audit logging** of every core access: operation, target, filter shape
  (never values), result size or status, latency, and the caller's opaque
  identity (`sub` or `client_id`). Keep it in its own log, retained 90+ days.
- **No personal data in logs**, including query strings in request logs.
- **Resilience:** exponential-backoff retries; circuit breaker opening after 5
  consecutive failures for 30 seconds; handle `429` and honour `Retry-After`.
- **Rate limiting** on any endpoint that forwards to the core system, per caller.
- **Authentication:** tokens last 1 hour; refresh reactively on `401`.
  Endpoints exposing core data require a validated token and scope.
- **HTTPS only**; **no secrets in code or committed configuration**.
- **Database access** is read-only, parameterised, and paged; never return a
  whole view.

## Choosing a method

| Need | Use |
|---|---|
| A backend service calling the core system with no user involved | REST API (Server-to-Server) |
| A frontend/client app acting on behalf of a signed-in user | REST API (Client-to-Server) |
| Users authenticating once and reusing that session across systems | SSO Integration |
| Bulk or reporting access to core data, no writes | Database Views |

## Structure

- `guides/` — one file per integration method.
- `references/sso-integration-example.md` — a finished, real integration
  document (Expert Hub ↔ FAST SSO): the model for the
  hand-off document you may write in Step 5, and the document to
  send the core team when requesting a client registration.
