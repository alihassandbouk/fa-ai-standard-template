# 18 — INT-01: the SSO / OpenID Connect integration

**Status:** 🟢 Live on the testing server — written 2026-09-07.
**Audience:** the FAST / IMS identity team, and whoever maintains INT-01 here.

**What this is.** One page covering the SSO integration end to end: **what we
built**, **what we need from FAST**, and **what FAST needs from us**. It is
meant to be readable by someone who has never opened this repository, and it is
the document to send when asking for a client registration.

**Related.** [`16_SSO_OIDC_CONFIGURATION.md`](16_SSO_OIDC_CONFIGURATION.md)
carries the full configuration reference and the history of corrections; this
page is the current, condensed statement. Where they disagree, this one is
newer.

---

## 1. What is built

**Expert Hub is an OpenID Connect Relying Party using Authorization Code +
PKCE, and the entire flow runs in the API — not in the browser.**

```
Browser ──► Expert Hub API ──► FAST identity provider
   ▲              │                      │
   └── HttpOnly ──┘◄─── code + tokens ───┘
       session
       cookie
```

The browser never receives a token of any kind. It holds one HttpOnly,
Secure, SameSite=Lax cookie; every token stays server-side. This is the
backend-for-frontend pattern, chosen so that an XSS bug in the SPA cannot read
a session, and so that it does not matter whether FAST issues a client secret.

### The four routes

| Route | Method | What it does |
|---|---|---|
| `/api/auth/login` | GET | Starts the handshake — challenges the OIDC scheme |
| `/api/auth/callback` | GET | **The redirect URI.** Handled by the framework's OIDC middleware |
| `/api/auth/session` | GET | Returns the current session (or 401). The SPA's only identity read |
| `/api/auth/logout` | POST | Ends the local session and returns the provider's end-session URL |

### Behaviour worth knowing

- **Fail closed.** An unmapped role value grants nothing. A user with no
  recognised role reaches no internal screen.
- **An API request is never redirected to the identity provider.** An
  unauthenticated data call gets `401`, never a 302 — only `/api/auth/login`
  challenges.
- **Roles are Expert Hub's own data, not a token claim.** FAST's token carries
  the identity; role assignment lives in our `USER_ROLE` table and is managed
  on our own screens. Claim mapping is still supported if FAST later releases
  roles — it is configuration, not code.
- **Users are provisioned just in time.** A first successful sign-in creates
  the local user record; no user list has to be synchronised in advance.
- **The session cookie carries a key, not a payload.** The authentication
  ticket lives in our database and the cookie holds a GUID. Expired sessions
  are swept hourly.
- **Only `id_token` is retained**, and only so logout can pass `id_token_hint`.
  Access and refresh tokens are discarded on arrival — nothing in Expert Hub
  calls FAST APIs on a user's behalf.

---

## 2. What we need FROM the FAST team

### 2.1 ⚠️ Register the correct redirect URI — the one blocker

This is the only thing preventing the real handshake from completing.

What we were told is registered today:

| | Value |
|---|---|
| Authority / issuer | `https://testingauth.fa.gov.sa/identitymanagement.sts` |
| Client id | `ReactApp` |
| Registered redirect URI | `https://testingdashboard.fa.gov.sa/callback` ← **a host we do not serve** |

**Please register these instead** (they must match character for character — a
trailing slash difference is a rejected login):

| Environment | `redirect_uri` | `post_logout_redirect_uri` |
|---|---|---|
| **Testing** | `https://experts.fa.gov.sa/api/auth/callback` | `https://experts.fa.gov.sa/expert-hub` |
| **Development** | `http://localhost:5173/api/auth/callback` | `http://localhost:5173/expert-hub` |
| Production | `https://<prod-host>/api/auth/callback` | `https://<prod-host>/expert-hub` |

> **Why `/api/...` and not a page URL.** The callback is handled by the API,
> not by the SPA — that is what keeps tokens out of the browser. The redirect
> URI is therefore an API route and is independent of the path the site is
> served at.

### 2.2 Confirm the client type

We assume **public client, Authorization Code + PKCE** — not implicit, not
hybrid.

Please state it explicitly, because some providers default a new client to
*confidential* and issue a secret. **A secret is fine** — the API can hold one
safely — but we must know, since a confidential client that is registered as
public (or the reverse) fails at the token exchange with an unhelpful error.

### 2.3 Session lifetime, refresh, and logout

Open questions, each of which is a configuration value on our side once
answered:

- How long is a session valid, and is a **refresh token** issued?
- Is **single logout** supported, and does the end-session endpoint expect
  `id_token_hint` (we send it) and `post_logout_redirect_uri`?
- Is there an idle timeout the identity provider enforces independently?

### 2.4 A display-name claim

The token currently gives us `sub` and `email`. The header therefore shows an
email address where a person's name belongs.

**Ask:** can a display-name claim be released — and is there an Arabic form?
Tell us the claim name; wiring it is an environment-variable edit, not a
release.

### 2.5 Role claims — only if you have them

We do **not** need roles from FAST; they are managed here. But if the Academy
already carries a role or group claim, tell us its **name and its values** for
staff versus external trainers, and we will honour it. This is `EXPERT_HUB_OIDC_ROLE_CLAIM`
and friends — again, a config edit.

### 2.6 Yaqeen identity verification

Per the owner's ruling, identity verification is **Yaqeen (يقين)**, reached
**through FAST** rather than as a direct integration with the provider.

**Ask:** the endpoints and the token exchange for Yaqeen verification. This is
the last screen in Expert Hub still running on demo data.

### 2.7 Service-to-service authentication

Separate from user sign-in: how does Expert Hub authenticate as a *service*
when it later reads trainer, plan and evaluation data? Client credentials,
mutual TLS, an API key? This applies to every FAST integration beyond SSO.

---

## 3. What we give TO the FAST team

Everything below is settled on our side and needs no further work from us.

### 3.1 Client registration details

| Field | Value |
|---|---|
| Application name | Expert Hub — Financial Academy (منصة الخبراء والمدربين) |
| Client type | Public, Authorization Code + PKCE *(confidential also supported)* |
| Grant type | `authorization_code` |
| Redirect URIs | See §2.1 |
| Post-logout redirect URIs | See §2.1 |
| Scopes requested | `openid profile email` |
| PKCE | Required, `S256` |
| Front-channel logout | Not used — we call the end-session endpoint from the API |

### 3.2 Endpoints we call on your side

Discovered from the authority's `/.well-known/openid-configuration`, so no URL
is hard-coded here:

- the **authorization** endpoint (and the **pushed authorization request**
  endpoint if advertised — see §3.4)
- the **token** endpoint
- the **JWKS** endpoint, for signature validation
- the **userinfo** endpoint, only if you tell us claims are released there
  rather than in the id token
- the **end-session** endpoint, at logout, with `id_token_hint`

### 3.3 What we do with the identity

- `sub` — the stable identifier; our local user record is keyed to it
- `email` — stored, and used to recognise a returning person
- Nothing else is read, and nothing is written back to FAST by the SSO
  integration

### 3.4 One thing to be aware of at your end

- **Pushed Authorization Requests (PAR)** are supported and preferred. They are
  currently **switched off** on our testing server only because the pushed
  request fails while the redirect URI is unregistered; we turn them back on
  the moment §2.1 lands.
- **The sign-in response carries large `Set-Cookie` headers.** If any proxy
  sits in front of our API on your side, its response-header buffers must be
  raised — the defaults reject an encrypted session ticket.

---

## 4. Current state and what unblocks what

| | Item | State |
|---|---|---|
| The flow | Authorization Code + PKCE, in the API | ✅ Built and running |
| Sign-in against the testing IdP | | ✅ Working |
| Session, logout, JIT provisioning | | ✅ Working |
| Server-side session store + sweeper | | ✅ Working |
| **Redirect URI registration** | §2.1 | 🔴 **Blocks the real handshake** |
| Client type confirmation | §2.2 | 🟡 Assumed public/PKCE |
| Session/refresh/logout contract | §2.3 | 🟡 Defaults in use |
| Display-name claim | §2.4 | 🟡 Header shows an email meanwhile |
| Role claims | §2.5 | ⚪ Not needed — ours |
| **Yaqeen verification** | §2.6 | 🔴 Last screen on demo data |
| Service-to-service auth | §2.7 | 🔴 Blocks every other FAST integration |

**The one-line summary for a status meeting:** the code has been finished since
August; what stands between it and a working production sign-in is a client
registration and a claim name.

---

## 5. For whoever maintains this here

**Configuration.** Every value is an environment variable — `Oidc__Authority`,
`Oidc__ClientId`, `Oidc__ClientSecret`, `Oidc__RoleClaim`,
`Oidc__NameClaim`, `Oidc__UsePushedAuthorization` and the rest — supplied
through `deploy/expert-hub/env/`. Answering any question in §2 is an env edit
and a container restart, never a code change. `appsettings.json` names every
key and leaves it empty; a test fails the build if a secret value is committed.

**A secret never goes in `config.js`.** That file is served to every browser.
The frontend runtime config has no field that could hold a secret, and the
container refuses to start if one is set. This is why the flow lives in the
API.

**Two operational settings that are not in this repository's control.** Both
live in the *server's* nginx, which was copied from
`deploy/expert-hub/server-nginx.example.conf` once — editing the example
changes nothing on a running server:

```nginx
# Large Set-Cookie on the SSO callback: nginx's 4k default returns 502
proxy_buffer_size        16k;
proxy_buffers            8 16k;
proxy_busy_buffers_size  32k;

# Session cookies exceed the 4x8k request-header default: 400 "Request Header
# Or Cookie Too Large"
large_client_header_buffers 8 32k;
```

**Data-protection keys must survive a deployment.** They encrypt the session
cookie, so they live on a named volume — and the directory is created *and
chowned to the app user while still root* in the Dockerfile, because a named
volume inherits the image directory's ownership and the API runs unprivileged.
Without that, every sign-in fails with a permission error deep inside the
framework.

**The lesson worth carrying to the next integration:** INT-01's code was
finished weeks before the integration worked, and everything in between was a
registration, a proxy setting, a volume, or a claim name. Budget for those.

---

*Maintained beside [`16_SSO_OIDC_CONFIGURATION.md`](16_SSO_OIDC_CONFIGURATION.md)
(full configuration reference) and
[`15_INPUTS_REGISTER.md`](15_INPUTS_REGISTER.md) (every outstanding ask, by
party).*
