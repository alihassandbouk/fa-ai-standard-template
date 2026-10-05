---
name: tfa-integration-fast-core
description: Integrate a system with the FAST Core .NET platform by REST API, SSO against its Identity Server, or read-only database views. Use for any FAST Core, IMS or FASTDB integration.
---

# TFA Integration Fast Core

Integrate a third-party system with the FAST Core .NET platform. The user
chooses the method in Step 2; code starts after that.

## Step 1: Inspect the project

Before asking, look at what already exists so the question can say so:

- Search for an existing integration: `FASTDB`, `FastCore`, `AddJwtBearer`,
  `AddOpenIdConnect`, `HttpClient` registrations pointing at the core system.
- Note the project type (ASP.NET Core minimal APIs or controllers, frontend
  framework if any) and the .NET version.

## Step 2: Ask the user to choose the method

Use the **AskUserQuestion** tool so the user picks from an arrow-key list:
exactly one question, single-select, header `Method`, question "Which FAST
Core integration method do you want to set up?", the options below in this
order with the *Shown* column as each description. Append " (already set
up)" to a label when Step 1 found that method in the project, and put
"(Recommended)" on the first option only if the user's request clearly
points to it. An "Other" answer is mapped onto one of the methods, or gets a
follow-up if it fits none. If the user rejects the question, stop and wait
for their instruction.

| Option | Shown | Follow-up questions (Step 3) | Guide (Step 4) |
|---|---|---|---|
| `Database views` | Read-only queries against core database views, for reporting or bulk reads. Needs the connection string, view names and their columns. | Which views to map (or "I'll paste the definitions"); what the data is for (read-only endpoints, enrich existing features, reporting). | `tfa-development-guard/references/read-only-views.md` (sibling skill): `ReadOnlyDbContext`, `ToView` mappings, `IReadOnlyRepository`, audit logging, GET-only controller. Connection string key: `ConnectionStrings:FASTDB`. |
| `REST API server-to-server` | Your backend calls the core API with an API key or client-credentials token; no user involved. Needs credentials and the endpoints to call. | Authentication: API key, client credentials, or both; first use case (client + health check, specific endpoints, read from Swagger). | Not written yet: build from the mandatory rules below. |
| `SSO + REST client-to-server` | Users sign in through Identity Server 5, and the app calls the core API with their token (refreshed on 401). Needs authority URL, client ID/secret, redirect URI and scopes. | App shape (backend-for-frontend, recommended, or SPA with PKCE); which core endpoints the app calls. | Backend-for-frontend: `guides/sso-server-side.md`; SPA: `guides/sso-client-side.md` plus the per-framework file in `guides/sso-client-side/`. The client-to-server part is not written yet. |
| `SSO only` | Users sign in through Identity Server 5; no core API calls. Needs authority URL, client ID/secret and redirect URI. | App shape (backend-for-frontend, recommended, or SPA with PKCE); replace existing sign-in or add alongside it; which user claims the app needs. | Backend-for-frontend: `guides/sso-server-side.md`; SPA: `guides/sso-client-side.md` plus the per-framework file in `guides/sso-client-side/`. |

Update the table when a guide is added.

## Step 3: Ask the method's follow-up questions

Again with **AskUserQuestion** (up to 4 questions in one call), collect only
the decisions that change what you build. A secret is set by the user with
`! dotnet user-secrets set "<key>" "<value>" --project <api project>`, so the
question names the key only.

## Step 4: Follow the chosen guide

If the guide is missing, tell the user so, then build it from the mandatory
rules below instead of guessing at undocumented core-system behaviour.

## Step 5: Verify and report

- Build and run the tests.
- Exercise the new endpoints or flows for real where possible (a local
  stand-in database or a locally issued token is fine; say so in the report).
- Record the integration in `context/architecture.md` under *System
  Boundaries* (what talks to what, auth, the settings keys). If the core team
  needs a hand-off document, write it as `docs/<name>-integration.md` shaped
  like `references/sso-integration-example.md`, a finished real integration
  document (Expert Hub ↔ FAST SSO) and the document to send the core team
  when requesting a client registration.
- Report what was built, what was verified, and what is still needed from the
  core team (credentials, schema, scopes).

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
