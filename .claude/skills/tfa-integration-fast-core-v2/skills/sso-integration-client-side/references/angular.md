# Angular

Library: `angular-auth-oidc-client` (standalone APIs, Angular 17+). It has its
own OIDC client, so the shared `userManager` from the main skill is not used
here; the same settings and rules apply.

## Config

```ts
// src/app/auth/auth.config.ts
import { PassedInitialConfig, LogLevel } from 'angular-auth-oidc-client';
import { environment } from '../../environments/environment';

export const authConfig: PassedInitialConfig = {
  config: {
    authority: environment.oidc.authority,
    clientId: environment.oidc.clientId,
    redirectUrl: environment.oidc.redirectUri,
    postLogoutRedirectUri: environment.oidc.postLogoutRedirectUri,
    scope: environment.oidc.scopes, // 'openid profile <api scopes>'
    responseType: 'code',            // PKCE, state and nonce handled by the library
    silentRenew: true,
    useRefreshToken: true,           // only if offline_access is in scope
    secureRoutes: [environment.apiOrigin], // token is attached only to these origins
    logLevel: LogLevel.Warn,
  },
};
```

## Token storage

This library keeps tokens and the in-progress sign-in state (PKCE verifier,
`state`, `nonce`) in the same store, `sessionStorage` by default. That store
must survive the redirect to the provider, so pure in-memory storage breaks
sign-in. Keep `sessionStorage` (never switch to `localStorage`), tell the
developer that injected scripts could read the tokens, and keep token
lifetimes short. If that tradeoff is not acceptable, use a backend-for-frontend
instead.

## Providers

```ts
// src/app/app.config.ts
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { provideAuth, authInterceptor, withAppInitializerAuthCheck } from 'angular-auth-oidc-client';
import { authConfig } from './auth/auth.config';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideAuth(authConfig, withAppInitializerAuthCheck()), // restores auth state and handles the callback on startup
    provideHttpClient(withInterceptors([authInterceptor()])),
  ],
};
```

## Routes

```ts
import { autoLoginPartialRoutesGuard } from 'angular-auth-oidc-client';

export const routes: Routes = [
  { path: 'auth/callback', component: AuthCallbackComponent },
  { path: 'account', component: AccountComponent, canActivate: [autoLoginPartialRoutesGuard] },
];
```

`autoLoginPartialRoutesGuard` sends signed-out users to the provider and
returns them to the route they asked for.

## Callback component

```ts
@Component({
  standalone: true,
  template: `@if (failed) { <p>Sign-in failed. Please try again.</p> } @else { <p>Signing you in…</p> }`,
})
export class AuthCallbackComponent {
  failed = false;
  constructor(oidc: OidcSecurityService, router: Router) {
    oidc.checkAuth().subscribe(({ isAuthenticated }) => {
      if (isAuthenticated) router.navigateByUrl('/');
      else this.failed = true; // never show the provider's error text
    });
  }
}
```

## API calls, refresh, sign-out

- `authInterceptor()` adds the bearer token only for `secureRoutes`.
- On `401`, add an interceptor that calls `oidc.forceRefreshSession()` once
  and retries, or `oidc.authorize()` if that fails.
- Sign out: `oidc.logoff().subscribe()` (local and provider).
- Current user: `oidc.userData$`.
