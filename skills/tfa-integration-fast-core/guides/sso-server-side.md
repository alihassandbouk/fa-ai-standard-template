# SSO Integration (Identity Server 5)

Users sign in through the core identity provider with OpenID Connect instead
of the app managing its own credentials. The FAST Core identity provider is
the only provider; do not add social or other providers.

Follow the parent skill's
[Mandatory rules](../../SKILL.md#mandatory-rules-for-every-method) throughout.

## Flow

Always **Authorization Code + PKCE**. Never implicit or hybrid flows, and never
the resource-owner password grant.

| App shape | Use | Where tokens live |
|---|---|---|
| Frontend served by or proxied to an ASP.NET Core backend | **Backend-for-frontend (BFF)**, recommended | Server side, inside the encrypted auth cookie. The browser never sees a token. |
| Frontend calls the core API directly with no backend of its own | **SPA with PKCE**: see `guides/sso-client-side.md ` | Browser memory only |

Machine-to-machine access with no user (client credentials) is not SSO; use
the server-to-server guide (not written yet).

---

## Step 1: Ask the developer for the SSO settings

Do not write any SSO code until you have the three required values. Ask in a
plain message (not AskUserQuestion — these are free-text values), listing each
setting with its example:

**Required**

1. **Authority URL** — the identity server URL that issues the tokens.
   ```
   Example: https://auth.fa.gov.sa/identitymanagementsts
   ```

2. **Client ID** — the client registered for this app on the identity server.
   ```
   Example: learnly-web
   ```

3. **Redirect URI** — where the identity server sends the user back after
   sign-in. It must match, character for character, a redirect URI registered
   for that client ID on the identity server.
   ```
   Example: https://localhost:5001/signin-oidc
   ```

**Optional** (say the default; the developer can accept it)

4. **Scopes** — default `openid profile`. Add `offline_access` only if the
   app will call the core API with the user's token (it enables refresh).
5. **Post-logout redirect URI** — where the user lands after signing out.
   Default: the app root. It must also be registered for the client.
6. **Client secret** — BFF only, and only if the core team registered the
   client as confidential. Never ask for its value in the chat; tell the
   developer to run
   `! dotnet user-secrets set "FastCoreSso:ClientSecret" "<value>" --project <api project>`.

Check each value before using it:

| Setting | Must be |
|---|---|
| Authority URL | Absolute `https://` URL, no trailing slash, no query string. `{authority}/.well-known/openid-configuration` should respond. |
| Client ID | Non-empty, no spaces. |
| Redirect URI | Absolute URL; `https://` except for `localhost` during development; no fragment (`#`). |
| Scopes | Space-separated; must include `openid`. |
| Post-logout redirect URI | Same rules as the redirect URI. |

If a value fails a check, tell the developer which one and why, and ask again
for that value only.

If the developer does not have a required value yet, do not invent one. Write
the setting as an empty string, list it under "still needed from the core
team" in the final report, and let startup fail with a clear message while it
is empty (see Step 2).

---

## Step 2: Add the settings to appsettings.json

The non-secret values go in configuration. Put environment-specific values
(such as a `localhost` redirect URI) in `appsettings.Development.json`. The
client secret, if any, goes only in user secrets or the deployment's secret
store.

**File:** `appsettings.json`

```json
{
  "FastCoreSso": {
    "Authority": "https://auth.fa.gov.sa/identitymanagementsts",
    "ClientId": "learnly-web",
    "RedirectUri": "https://localhost:5001/signin-oidc",
    "PostLogoutRedirectUri": "https://localhost:5001/",
    "Scopes": "openid profile"
  }
}
```

Bind and validate them at startup, so a missing or malformed value stops the
app instead of failing at the first sign-in:

```csharp
public sealed class FastCoreSsoOptions
{
    public const string SectionName = "FastCoreSso";

    [Required, Url]
    public string Authority { get; init; } = "";

    [Required]
    public string ClientId { get; init; } = "";

    [Required, Url]
    public string RedirectUri { get; init; } = "";

    [Url]
    public string? PostLogoutRedirectUri { get; init; }

    public string Scopes { get; init; } = "openid profile";

    // BFF with a confidential client only. From user secrets, never appsettings.json.
    public string? ClientSecret { get; init; }
}
```

```csharp
// Program.cs
builder.Services
    .AddOptions<FastCoreSsoOptions>()
    .BindConfiguration(FastCoreSsoOptions.SectionName)
    .ValidateDataAnnotations()
    .Validate(o => o.Authority.StartsWith("https://", StringComparison.OrdinalIgnoreCase),
        "FastCoreSso:Authority must use https.")
    .Validate(o => o.Scopes.Split(' ', StringSplitOptions.RemoveEmptyEntries).Contains("openid"),
        "FastCoreSso:Scopes must include openid.")
    .ValidateOnStart();
```

---

## Step 3a: BFF (recommended)

ASP.NET Core does the whole OIDC exchange: PKCE, `state`, `nonce`, ID token
signature/issuer/audience/expiry checks, and discovery of the endpoints from
`{Authority}/.well-known/openid-configuration`. Do not hand-roll any of these
or hard-code the identity server's endpoint URLs.

Package: `Microsoft.AspNetCore.Authentication.OpenIdConnect`.

```csharp
// Program.cs
builder.Services
    .AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = OpenIdConnectDefaults.AuthenticationScheme;
    })
    .AddCookie(options =>
    {
        options.Cookie.Name = "__Host-sso";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.Cookie.SameSite = SameSiteMode.Lax;
        options.ExpireTimeSpan = TimeSpan.FromHours(1); // matches the 1-hour token lifetime
        options.SlidingExpiration = true;
    })
    .AddOpenIdConnect();

builder.Services
    .AddOptions<OpenIdConnectOptions>(OpenIdConnectDefaults.AuthenticationScheme)
    .Configure<IOptions<FastCoreSsoOptions>>((options, ssoOptions) =>
    {
        var sso = ssoOptions.Value;

        options.Authority = sso.Authority;
        options.ClientId = sso.ClientId;
        options.ClientSecret = string.IsNullOrEmpty(sso.ClientSecret) ? null : sso.ClientSecret;
        options.CallbackPath = new Uri(sso.RedirectUri).AbsolutePath;
        options.SignedOutRedirectUri = sso.PostLogoutRedirectUri ?? "/";

        options.ResponseType = OpenIdConnectResponseType.Code;
        options.UsePkce = true;
        options.RequireHttpsMetadata = true;
        options.MapInboundClaims = false; // keep "sub", "name" as issued
        options.TokenValidationParameters.NameClaimType = "name";
        options.GetClaimsFromUserInfoEndpoint = true;
        options.SaveTokens = true; // stored in the encrypted cookie, needed for sign-out and core API calls

        options.Scope.Clear();
        foreach (var scope in sso.Scopes.Split(' ', StringSplitOptions.RemoveEmptyEntries))
            options.Scope.Add(scope);

        options.Events = new OpenIdConnectEvents
        {
            // API calls get 401 instead of a redirect to the sign-in page.
            OnRedirectToIdentityProvider = context =>
            {
                if (context.Request.Path.StartsWithSegments("/api"))
                {
                    context.Response.StatusCode = StatusCodes.Status401Unauthorized;
                    context.HandleResponse();
                }
                return Task.CompletedTask;
            },
            OnTokenValidated = context =>
            {
                AuditLog(context.HttpContext).LogInformation(
                    "SSO sign-in succeeded for {Subject}", context.Principal?.FindFirstValue("sub"));
                return Task.CompletedTask;
            },
            // Never echo the provider's error_description back to the user or into a URL.
            OnRemoteFailure = context =>
            {
                AuditLog(context.HttpContext).LogWarning(
                    "SSO sign-in failed: {FailureType}", context.Failure?.GetType().Name);
                context.Response.Redirect("/?signin=failed");
                context.HandleResponse();
                return Task.CompletedTask;
            },
        };
    });

builder.Services.AddAuthorization();

static ILogger AuditLog(HttpContext context) =>
    context.RequestServices.GetRequiredService<ILoggerFactory>().CreateLogger("FastCore.Audit");
```

```csharp
app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/auth/login", (string? returnUrl) =>
    Results.Challenge(
        new AuthenticationProperties { RedirectUri = IsLocalUrl(returnUrl) ? returnUrl : "/" },
        [OpenIdConnectDefaults.AuthenticationScheme]));

// Signs out of the app and of the identity server (end-session endpoint).
app.MapPost("/auth/logout", async (HttpContext context) =>
{
    AuditLog(context).LogInformation("SSO sign-out for {Subject}", context.User.FindFirstValue("sub"));
    await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
    await context.SignOutAsync(OpenIdConnectDefaults.AuthenticationScheme);
}).RequireAuthorization();

// For the frontend to learn who is signed in; 401 when nobody is.
app.MapGet("/api/auth/me", (ClaimsPrincipal user) => new
{
    Subject = user.FindFirstValue("sub"),
    Name = user.Identity?.Name,
}).RequireAuthorization();

// Blocks open redirects through ?returnUrl=.
static bool IsLocalUrl(string? url) =>
    !string.IsNullOrEmpty(url) && url[0] == '/' &&
    (url.Length == 1 || (url[1] != '/' && url[1] != '\\'));
```

Frontend:

- Sign in: navigate to `/auth/login?returnUrl=<current path>` (a full page
  navigation, not `fetch`).
- Sign out: submit a `<form method="post" action="/auth/logout">`, because the
  response redirects to the identity server.
- On load, call `/api/auth/me`; a `401` means signed out.

Development:

- Run the backend on HTTPS (`dotnet run --launch-profile https`). The
  correlation and nonce cookies are `Secure` and break over plain HTTP.
- If the frontend dev server proxies the API (as Vite does here), also proxy
  `/auth`, the redirect URI path (`/signin-oidc`) and `/signout-callback-oidc`,
  and register the redirect URI on the origin the browser sees.

---

## Step 3b: SPA with PKCE

Use only when there is no backend to act as the BFF. Follow
[`sso-client-side.md`](sso-client-side.md)
instead of Step 3a, with the settings from Step 1 minus the client secret (the
client must be registered as **public**).

Any backend the SPA calls validates the access token with `AddJwtBearer`
(authority, audience, required scope) — see `the client-to-server guide (not written yet)`.

---

## Step 4: Tokens and refresh

- Tokens last **1 hour**. Refresh **reactively**: when a core API call returns
  `401`, use the refresh token once (`grant_type=refresh_token` at the token
  endpoint from discovery) and retry the call once. If the refresh fails, sign
  the user in again. Do not refresh on a timer.
- A refresh token exists only if `offline_access` was requested and the client
  is allowed it. SSO-only apps don't need one; the user signs in again when the
  cookie expires.
- Never put tokens in `localStorage`, URLs, logs or an unencrypted cookie.
  In the BFF the auth cookie is encrypted by ASP.NET Core Data Protection; in
  production, persist the Data Protection keys (shared across instances) so
  cookies survive restarts.

Calling the core API with the user's token is covered by
`the client-to-server guide (not written yet)`.

---

## Step 5: Audit logging

Write to the audit log (category `FastCore.Audit`, retained 90+ days):

| Event | Log |
|---|---|
| Sign-in succeeded | `sub` |
| Sign-in failed | Failure type only |
| Sign-out | `sub` |
| Token refreshed / refresh failed | `sub`, outcome |

Never log tokens, authorization codes, the client secret, email addresses or
names, or the query string of the redirect URI (it carries the code).

---

## Step 6: Verify and report

Verify:

- The app refuses to start with `FastCoreSso:Authority` empty.
- `/auth/login` redirects to `{Authority}/connect/authorize` (or whatever
  discovery lists) with `code_challenge`, `state` and `nonce` parameters.
- A full sign-in and sign-out against the identity server, if the developer
  has test credentials. If not, say that this was not exercised.
- `/api/auth/me` returns `401` when signed out, not a redirect.
- `/auth/login?returnUrl=https://evil.example` lands on `/`.

In the final report, list each setting with the value used (or "still
needed", secrets shown only as "set"/"not set"). Remind the developer that the
redirect URI and post-logout redirect URI must be registered for the client ID
on the identity server for each environment.

## Checklist

- [ ] Authorization Code + PKCE; no implicit flow
- [ ] `state` and `nonce` validated (by the framework or library)
- [ ] Endpoints from discovery, not hard-coded
- [ ] ID token validated: signature, issuer, audience, expiry
- [ ] Settings in `FastCoreSso`, validated on start; secret only in secret storage
- [ ] Tokens server-side (BFF) or in memory (SPA); cookie `HttpOnly`, `Secure`, `SameSite=Lax`
- [ ] `returnUrl` limited to local paths
- [ ] Sign-out ends the identity server session too
- [ ] API routes answer `401`, not a redirect
- [ ] Reactive refresh on `401` only
- [ ] Sign-in, failure, sign-out and refresh audit-logged, with no personal data
- [ ] Provider error text never shown to the user or put in a URL
- [ ] HTTPS everywhere
