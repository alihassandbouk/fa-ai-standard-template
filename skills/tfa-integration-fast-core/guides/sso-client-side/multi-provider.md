# Multiple Providers (Frontend)

Use this when different users sign in through different providers (for
example, staff through the corporate IdP and customers through a public one),
or the app talks to APIs trusting different issuers.

## One UserManager per provider

Keep each provider's settings explicit and separate; do not merge scopes.

```ts
// src/auth/providers.ts
import { UserManager, WebStorageStateStore, InMemoryWebStorage } from 'oidc-client-ts';

function createManager(prefix: string, s: ProviderSettings) {
  return new UserManager({
    authority: s.authority,
    client_id: s.clientId,
    redirect_uri: s.redirectUri,             // one callback route per provider is simplest
    post_logout_redirect_uri: s.postLogoutRedirectUri,
    scope: s.scopes,
    response_type: 'code',
    userStore: new WebStorageStateStore({ prefix, store: new InMemoryWebStorage() }),
    stateStore: new WebStorageStateStore({ prefix, store: window.localStorage }),
  });
}

export const providers = {
  staff: createManager('staff.', env.STAFF_OIDC),
  customer: createManager('customer.', env.CUSTOMER_OIDC),
} as const;

export type ProviderId = keyof typeof providers;
```

## Resolving the provider on callback

Simplest: give each provider its own callback route (`/auth/callback/staff`,
`/auth/callback/customer`) and call that provider's `signinRedirectCallback`.

If they must share a route, remember the choice before redirecting and
read it back on callback — only as a lookup key, never trusted blindly:

```ts
sessionStorage.setItem('auth_provider', id);
await providers[id].signinRedirect({ state: returnTo });

// on callback
const id = sessionStorage.getItem('auth_provider');
if (id !== 'staff' && id !== 'customer') throw new Error('Unknown provider');
const user = await providers[id].signinRedirectCallback();
sessionStorage.removeItem('auth_provider');
```

## Notes

- Route guards and API calls must use the manager for the provider the user
  signed in with.
- Only attach a provider's token to the API origins that trust that issuer.
- Sign-out ends the session at the provider the user actually used.
- Register callback and post-logout URIs separately at each provider.
