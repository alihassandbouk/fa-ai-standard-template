# Vue 3

Library: `oidc-client-ts` directly, with Vue Router. Reuses the shared
`userManager`, `safeReturnTo` and `authFetch` from the main skill.

## Composable

```ts
// src/auth/useAuth.ts
import { ref, readonly } from 'vue';
import type { User } from 'oidc-client-ts';
import { userManager } from './oidc';

const user = ref<User | null>(null);
userManager.events.addUserLoaded((u) => { user.value = u; });
userManager.events.addUserUnloaded(() => { user.value = null; });

export async function restoreUser() {
  const u = await userManager.getUser();
  user.value = u && !u.expired ? u : null;
}

export function useAuth() {
  return {
    user: readonly(user),
    signIn: (returnTo: string) => userManager.signinRedirect({ state: returnTo }),
    signOut: () => userManager.signoutRedirect(),
  };
}
```

Call `await restoreUser()` in `main.ts` before `app.mount()`.

## Router guard

```ts
// src/router/index.ts
router.beforeEach(async (to) => {
  if (!to.meta.requiresAuth) return true;
  const u = await userManager.getUser();
  if (u && !u.expired) return true;
  await userManager.signinRedirect({ state: to.fullPath });
  return false;
});
```

Mark protected routes with `meta: { requiresAuth: true }`.

## Callback route

```vue
<!-- src/auth/AuthCallback.vue -->
<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { userManager, safeReturnTo } from './oidc';

const router = useRouter();
const failed = ref(false);

onMounted(async () => {
  try {
    const user = await userManager.signinRedirectCallback();
    await router.replace(safeReturnTo(user.state));
  } catch {
    failed.value = true; // never show the provider's error text
  }
});
</script>

<template>
  <p v-if="failed">Sign-in failed. Please try again.</p>
  <p v-else>Signing you in…</p>
</template>
```

Register it at the redirect URI's path, e.g. `{ path: '/auth/callback', component: AuthCallback }`.

## API calls and sign-out

- API calls: `authFetch` from the main skill, or the same logic in an axios
  interceptor.
- Sign out: `useAuth().signOut()`.
- Current user: `useAuth().user.value?.profile`.

Using Pinia? Put the same state and actions in a store instead of the
composable.
