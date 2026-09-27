# React

Library: `react-oidc-context` (wraps `oidc-client-ts`). Reuses the shared
`userManager` and `safeReturnTo` from the main skill.

## Provider

```tsx
// src/auth/AppAuthProvider.tsx
import { AuthProvider } from 'react-oidc-context';
import { userManager } from './oidc';

export function AppAuthProvider({ children }: { children: React.ReactNode }) {
  return (
    <AuthProvider
      userManager={userManager}
      // Drop ?code=&state= from the address bar; AuthCallback then navigates on.
      onSigninCallback={() => {
        window.history.replaceState({}, document.title, window.location.pathname);
      }}
    >
      {children}
    </AuthProvider>
  );
}
```

`AuthProvider` handles the callback itself when the page loads with `code`
and `state` in the URL, so the callback route only needs to render a loading
state and show errors.

## Callback route

```tsx
// src/auth/AuthCallback.tsx
import { Navigate } from 'react-router-dom';
import { useAuth } from 'react-oidc-context';
import { safeReturnTo } from './oidc';

export function AuthCallback() {
  const auth = useAuth();
  if (auth.error) return <p>Sign-in failed. Please try again.</p>; // never show auth.error.message
  if (auth.isLoading || !auth.isAuthenticated) return <p>Signing you in…</p>;
  return <Navigate to={safeReturnTo(auth.user?.state)} replace />;
}
```

## Protected route

Start the redirect in an effect, not during render.

```tsx
// src/auth/ProtectedRoute.tsx
import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useAuth } from 'react-oidc-context';

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const auth = useAuth();
  const location = useLocation();
  const mustSignIn = !auth.isLoading && !auth.isAuthenticated && !auth.activeNavigator && !auth.error;

  useEffect(() => {
    if (mustSignIn) void auth.signinRedirect({ state: location.pathname + location.search });
  }, [mustSignIn]); // eslint-disable-line react-hooks/exhaustive-deps

  if (auth.error) return <p>Sign-in failed. Please try again.</p>;
  if (!auth.isAuthenticated) return <p>Loading…</p>;
  return <>{children}</>;
}
```

## Routes

```tsx
<AppAuthProvider>
  <Routes>
    <Route path="/auth/callback" element={<AuthCallback />} />
    <Route path="/account" element={<ProtectedRoute><AccountPage /></ProtectedRoute>} />
  </Routes>
</AppAuthProvider>
```

## API calls and sign-out

- API calls: use `authFetch` from the main skill (or the same logic in an
  axios interceptor).
- Sign out: `auth.signoutRedirect()`.
- Current user: `auth.user?.profile` (`sub`, `name`, …).
