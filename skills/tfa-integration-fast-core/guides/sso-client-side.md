# SSO Integration — Client Side (Frontend)

Use this guide to add OpenID Connect sign-in to a browser app. It covers the
client side only. The API that receives the tokens must validate them itself;
that is a backend task (`the client-to-server guide (not written yet)`).

Follow the parent skill's
[Mandatory rules](../../SKILL.md#mandatory-rules-for-every-method) throughout.
For an app with an ASP.NET Core backend that can hold the session, prefer
[`sso-server-side.md`](sso-server-side.md).

Adapted from the `oidc-integration` skill by jeff-tian (v0.1.0), rewritten for
frontend-only use.

## Before writing code

Check these first:

- **Framework and router:** React (React Router), Angular (Angular Router),
  Vue (Vue Router), or other. Read the matching reference file (below).
- **Who owns the session:** if the app has its own backend that can run the
  OIDC flow and hold tokens server-side (backend-for-frontend), recommend
  that instead, and on the frontend only redirect to the backend's login and
  logout URLs. Use this skill's browser flow when the frontend must call APIs
  with the tokens itself.
- **Provider:** any OIDC-compliant provider (IdentityServer, Keycloak, Auth0,
  Azure AD / Entra ID, Authing, …). One or several (see
  `sso-client-side/multi-provider.md`).
- **Existing auth code:** extend an auth wrapper that's already in the repo
  instead of adding a second one.
- **What's needed:** login only, or also route protection, API calls,
  refresh and logout.

## Settings to collect

Ask the developer for these; never invent them.

| Setting | Notes |
|---|---|
| Authority | The identity server URL (the issuer), e.g. `https://auth.fa.gov.sa/identitymanagementsts`. `{authority}/.well-known/openid-configuration` must respond. |
| Client ID | Registered as a **public** client (no secret: nothing in browser code is secret). |
| Redirect URI | The app's callback route, e.g. `https://app.example.com/auth/callback`. Must be registered on the provider exactly. |
| Post-logout redirect URI | Where the user lands after sign-out. Must be registered. |
| Scopes | `openid profile` plus the API scopes the app needs. `offline_access` only if refresh tokens are really needed. |

Put them in the build tool's environment config (`VITE_*` for Vite,
`environment.ts` for Angular, etc.), per environment. Do not build the
redirect URI from `window.location` — it must match what is registered.

## Security defaults

- Authorization Code flow with **PKCE**. Never the implicit flow or the
  password grant.
- Endpoints from discovery, never hard-coded `/authorize`, `/token` or JWKS URLs.
- `state` and `nonce` are validated by the library; do not hand-roll PKCE or
  token exchange unless no maintained library fits.
- **Tokens in memory by default.** `localStorage`/`sessionStorage` lets any
  injected script read them. If the team accepts storage to survive reloads,
  say so explicitly and prefer `sessionStorage` over `localStorage`.
- Send the access token **only to your own API origins**, never to third-party
  URLs.
- Return URLs: carry them through the flow in the `state` argument and accept
  only local paths (starting with `/`, not `//`) — this blocks open redirects.
- On a callback error, show a generic message. Do not render the provider's
  `error_description` or put it in a URL.
- Logout is two steps: clear local state, then end the provider session
  (`end_session_endpoint`).

## Shared core: `oidc-client-ts`

Every framework reference builds on one `UserManager`. It is framework-free,
so for frameworks without a reference file, use it directly.

```ts
// src/auth/oidc.ts
import { UserManager, WebStorageStateStore, InMemoryWebStorage } from 'oidc-client-ts';

export const userManager = new UserManager({
  authority: env.OIDC_AUTHORITY,
  client_id: env.OIDC_CLIENT_ID,
  redirect_uri: env.OIDC_REDIRECT_URI,
  post_logout_redirect_uri: env.OIDC_POST_LOGOUT_REDIRECT_URI,
  scope: env.OIDC_SCOPES ?? 'openid profile',
  response_type: 'code',            // PKCE, state and nonce handled by the library
  userStore: new WebStorageStateStore({ store: new InMemoryWebStorage() }),
  automaticSilentRenew: false,      // refresh on 401 instead (see below)
});

export function safeReturnTo(value: unknown): string {
  return typeof value === 'string' && value.startsWith('/') && !value.startsWith('//')
    && !value.startsWith('/\\') ? value : '/';
}
```

Replace `env.*` with the framework's config source.

The four operations every framework wires up:

| Operation | Call |
|---|---|
| Sign in | `userManager.signinRedirect({ state: currentPath })` |
| Callback route | `const user = await userManager.signinRedirectCallback()` then navigate to `safeReturnTo(user.state)` |
| Current user on startup | `await userManager.getUser()` (null or `expired` → not signed in) |
| Sign out | `await userManager.signoutRedirect()` (sends `id_token_hint` automatically) |

With tokens in memory, a page reload loses them. The route guard then calls
`signinRedirect` again; because the provider session still exists, the user
comes straight back without seeing a login form.

### API calls and refresh

```ts
// src/auth/authFetch.ts
const API_ORIGINS = [env.API_ORIGIN];

export async function authFetch(input: string, init: RequestInit = {}): Promise<Response> {
  const url = new URL(input, window.location.origin);
  const ownApi = url.origin === window.location.origin || API_ORIGINS.includes(url.origin);
  if (!ownApi) return fetch(input, init);

  const send = async () => {
    const user = await userManager.getUser();
    const headers = new Headers(init.headers);
    if (user?.access_token) headers.set('Authorization', `Bearer ${user.access_token}`);
    return fetch(input, { ...init, headers });
  };

  let response = await send();
  if (response.status === 401) {
    try {
      await userManager.signinSilent(); // uses the refresh token if there is one
      response = await send();          // retry once
    } catch {
      await userManager.signinRedirect({ state: window.location.pathname + window.location.search });
    }
  }
  return response;
}
```

Refresh reactively on `401`, retrying once, and send the user to sign-in if
the refresh fails. Turn on `automaticSilentRenew` instead only if the project
wants proactive refresh; don't use both. Without `offline_access`,
`signinSilent` uses a hidden iframe, which browsers that block third-party
cookies may break; the fallback to `signinRedirect` covers that.

## Framework references

Read only the one that applies:

- `sso-client-side/react.md` — React with `react-oidc-context`
- `sso-client-side/angular.md` — Angular with `angular-auth-oidc-client`
- `sso-client-side/vue.md` — Vue 3 with `oidc-client-ts` + Vue Router
- `sso-client-side/multi-provider.md` — more than one provider or issuer

Other frameworks (Svelte, Solid, plain TS): use the shared core above, a
guard in the router's before-navigation hook, and a callback route that calls
`signinRedirectCallback`.

## Deliverables checklist

- [ ] Provider settings in environment config, not code
- [ ] Sign-in entry point that carries the return path in `state`
- [ ] Callback route: success → safe return path; error → generic message
- [ ] Auth state restored on startup
- [ ] Route guard for protected routes
- [ ] Bearer token only on requests to own API origins
- [ ] 401 → refresh once → retry, or sign in again
- [ ] Sign-out: local and provider
- [ ] Multi-provider selection, if applicable

## Verification

- Sign in from a clean browser session and land on the page you started from.
- A return path of `https://evil.example` or `//evil.example` in `state` lands on `/`.
- Callback with `?error=access_denied` shows the generic message.
- Protected route while signed out → provider sign-in.
- Expired or revoked token → one refresh attempt, then sign-in.
- Requests to other origins carry no `Authorization` header.
- Sign-out ends the provider session (signing in again shows the login form).
