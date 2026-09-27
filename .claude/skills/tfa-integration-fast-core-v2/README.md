# TFA Integration Fast Core Plugin — v2 (in development)

Complete guide to integrating third-party systems with the core .NET infrastructure.

## 📋 Overview

This plugin provides everything needed to integrate external systems with the core system using one of four methods:

1. **REST API (Server-to-Server)** — Backend-to-backend with API keys
2. **REST API (Client-to-Server)** — Browser/app to backend via SSO
3. **SSO Integration** — User authentication with Identity Server 5
4. **Database Views** — Read-only direct database access

---

## 🎯 Quick Start

### 1. Determine Your Use Case

When you use the plugin, Claude first checks your project for an existing
integration, then asks you to pick the method from an arrow-key list (marking
any method that is already set up), followed by a few method-specific
questions. It never picks a method for you. The options map to:

| Need | Method | Skill |
|------|--------|-------|
| Backend service calls | REST API S2S | `rest-api-server-to-server` |
| Web/mobile app calls | REST API C2S + SSO | `sso-integration-server-side` or `sso-integration-client-side`, + `rest-api-client-to-server` |
| User authentication only | SSO | `sso-integration-server-side` (backend-for-frontend) or `sso-integration-client-side` (SPA) |
| Direct database queries | DB Views | `db-view-integration` |

### 2. Follow the Corresponding Skill

Each skill provides:
- Prerequisites checklist
- Step-by-step setup
- C# code examples
- Error handling
- Testing guidance

### 3. Implement Mandatory Audit Logging

All integrations require comprehensive audit logging. See `references/audit-logging-mandatory.md`

### 4. Test & Deploy

Use provided test cases and deployment checklists.

---

## 📁 Plugin Structure

```
tfa-integration-fast-core/
│
├── SKILL.md
│   Main plugin guide + decision framework
│   (Choose your integration method)
│
├── skills/
│   ├── rest-api-server-to-server/
│   │   └── SKILL.md (Backend integration with API keys)
│   │
│   ├── rest-api-client-to-server/
│   │   └── SKILL.md (Browser/app integration via SSO)
│   │
│   ├── sso-integration-server-side/
│   │   └── SKILL.md (Identity Server 5 sign-in in ASP.NET Core, backend-for-frontend)
│   │
│   ├── sso-integration-client-side/
│   │   ├── SKILL.md (Identity Server 5 sign-in in a browser SPA)
│   │   └── references/ (react.md, angular.md, vue.md, multi-provider.md)
│   │
│   └── db-view-integration/
│       └── SKILL.md (Read-only database access)
│
├── references/
│   ├── core-system-overview.md
│   │   API docs, versioning, authentication details
│   │
│   ├── rate-limiting-guide.md
│   │   Circuit breaker pattern (5 failure threshold)
│   │   Sliding window rate limiting
│   │   Retry strategies
│   │
│   ├── audit-logging-mandatory.md
│   │   REQUIRED for all integrations
│   │   Serilog setup, logging patterns
│   │   Sensitive data protection
│   │
│   ├── api-key-management.md
│   │   Requesting keys, secure storage
│   │
│   ├── api-versioning-guide.md
│   │   How to use API versioning
│   │
│   ├── error-troubleshooting.md
│   │   Common errors and solutions
│   │
│   ├── identity-server-5-guide.md
│   │   Deundo (Identity Server 5) setup
│   │
│   └── security-best-practices.md
│       HTTPS, secrets management, SQL injection prevention
│
├── assets/
│   ├── templates/
│   │   ├── HttpClientIntegration.cs
│   │   ├── RateLimitHandler.cs
│   │   ├── IdentityServerClient.cs
│   │   ├── TokenRefreshHandler.cs
│   │   ├── DbViewContext.cs
│   │   ├── AuditLogger.cs
│   │   ├── LoggingMiddleware.cs
│   │   ├── CircuitBreakerConfiguration.cs
│   │   └── appsettings.json
│   │
│   └── configs/
│       ├── rest-api-server-config.json
│       ├── identity-server-config.json
│       └── database-connection.json
│
└── README.md (this file)
```

---

## ⚡ Key Features

### Rate Limiting & Resilience
- **Sliding Window** monitoring
- **Circuit Breaker** pattern (opens after 5 failures, waits 30s)
- **Exponential backoff** retry strategy
- **Comprehensive logging** of all rate limit events

### Authentication
- **API Key** for server-to-server
- **OAuth2/OIDC** for user authentication
- **Identity Server 5 (Deundo)** provider
- **1-hour token lifetime** with reactive refresh on 401

### Security
- **HTTPS only** communication
- **Secrets management** (no hardcoding)
- **Parameterized queries** for database access
- **Audit logging** (mandatory) for compliance
- **PII protection** in logs

### Audit Logging (MANDATORY)
All integrations must log:
- ✅ API calls (method, endpoint, status, latency)
- ✅ Authentication events (token acquisition, refresh, login)
- ✅ Rate limiting hits
- ✅ Circuit breaker state changes
- ✅ Errors with context
- ✅ Database access (operation, view, rows affected)

---

## 🚀 Getting Started

### Step 1: Read the Main SKILL.md
Understand the 4 integration methods and choose one.

### Step 2: Follow the Corresponding Skill
Complete setup for your chosen method (includes code examples).

### Step 3: Implement Audit Logging
Use Serilog or ILogger per `references/audit-logging-mandatory.md`

### Step 4: Configure Error Handling
Handle rate limits (429), unauthorized (401), server errors (5xx).

### Step 5: Test
Use provided test cases to verify setup.

### Step 6: Deploy
Follow pre-deployment checklist in your skill.

---

## 📚 Reference Documents

### Core System
- **`core-system-overview.md`** — API endpoints, versioning, authentication
- **`api-versioning-guide.md`** — How to use API versions
- **`identity-server-5-guide.md`** — Deundo SSO provider details

### Rate Limiting & Resilience
- **`rate-limiting-guide.md`** — Sliding window, circuit breaker (5 failures)
- Circuit breaker states, retry strategies, monitoring

### Logging & Compliance
- **`audit-logging-mandatory.md`** — REQUIRED implementation
- Serilog configuration, logging patterns, sensitive data protection

### Security & Error Handling
- **`security-best-practices.md`** — HTTPS, secrets, SQL injection
- **`error-troubleshooting.md`** — Common errors and solutions
- **`api-key-management.md`** — Key request/storage/rotation

---

## 💡 Common Scenarios

### "I have a backend service that needs to call the core API"
→ Use **REST API Server-to-Server** skill

**Steps:**
1. Request API key from core team
2. Setup HttpClient with circuit breaker (Polly)
3. Implement audit logging
4. Handle 429 rate limits
5. Deploy

### "My web app needs user login and API access"
→ Use **SSO Integration** + **REST API Client-to-Server** skills

**Steps:**
1. Complete SSO setup first (Identity Server 5)
2. Get user token
3. Use token in REST API calls
4. Implement reactive 401 token refresh
5. Add audit logging

### "I need to report on user data from the core system"
→ Use **Database Views** skill

**Steps:**
1. Request view access from core team
2. Setup Entity Framework DbContext
3. Create repository for view access
4. Use parameterized queries
5. Implement audit logging

---

## ⚙️ Configuration Summary

| Aspect | Setting |
|--------|---------|
| **Rate Limiting** | Sliding Window + Circuit Breaker |
| **Circuit Breaker Threshold** | 5 consecutive failures |
| **Circuit Break Duration** | 30 seconds |
| **Token Lifetime** | 1 hour (SSO/OAuth2) |
| **Token Refresh** | Reactive (on 401 response) |
| **Audit Logging** | MANDATORY for all types |
| **API Versioning** | Specified in core system |
| **HTTPS** | Required (no HTTP) |
| **Secrets** | Never hardcode (use secrets manager) |

---

## 📋 Pre-Deployment Checklist

Before deploying to production:

### General
- ✅ Secrets securely stored (not in code)
- ✅ HTTPS used exclusively
- ✅ Audit logging implemented (mandatory)
- ✅ Error handling for all HTTP codes
- ✅ Timeout configured appropriately

### Rate Limiting & Resilience
- ✅ Circuit breaker configured (5 failures)
- ✅ Exponential backoff implemented
- ✅ Rate limit (429) handling implemented
- ✅ Circuit breaker events logged

### Authentication
- ✅ API key / token properly validated
- ✅ Token refresh implemented (if needed)
- ✅ Scope validation (if applicable)
- ✅ Auth failures logged and monitored

### Database (if applicable)
- ✅ Read-only enforcement
- ✅ Parameterized queries used
- ✅ Connection pooling enabled
- ✅ Modification attempts blocked

### Logging & Monitoring
- ✅ All API calls logged
- ✅ All auth events logged
- ✅ All errors logged with context
- ✅ Rate limit events logged
- ✅ Circuit breaker events logged
- ✅ Log retention configured (90+ days)
- ✅ Alerts set up (errors, circuit breaks)

---

## 🆘 Troubleshooting

### "I'm getting 401 Unauthorized"
1. Check API key / token validity
2. Verify credentials are not expired
3. See `references/error-troubleshooting.md`

### "Too many requests (429)"
1. Reduce request rate
2. Circuit breaker will handle retries
3. Check `references/rate-limiting-guide.md`

### "Circuit breaker is stuck OPEN"
1. Check core system health/status
2. Verify timeout settings aren't too aggressive
3. Monitor logs for actual failures

### "Audit logging not working"
1. Check Serilog configuration in appsettings.json
2. Verify log directory permissions
3. Review `references/audit-logging-mandatory.md`

---

## 📖 Documentation Quick Links

- **Main Guide** → SKILL.md
- **REST API S2S** → skills/rest-api-server-to-server/SKILL.md
- **REST API C2S** → skills/rest-api-client-to-server/SKILL.md
- **SSO Setup (server side)** → skills/sso-integration-server-side/SKILL.md
- **SSO Setup (client side)** → skills/sso-integration-client-side/SKILL.md
- **Database Views** → skills/db-view-integration/SKILL.md
- **Rate Limiting** → references/rate-limiting-guide.md
- **Audit Logging** → references/audit-logging-mandatory.md
- **Troubleshooting** → references/error-troubleshooting.md

---

## 🔗 External Resources

- **API Swagger Docs:** https://betaportal.fa.gov.sa/mobile-api/swagger/index.html
- **Identity Server 5 Docs:** Check references/identity-server-5-guide.md
- **Polly (Circuit Breaker):** GitHub.com/App-vNext/Polly
- **Serilog Docs:** github.com/serilog/serilog/wiki

---

## ✅ Next Steps

1. **Review the main SKILL.md** to understand your options
2. **Choose your integration method**
3. **Follow the corresponding skill** for step-by-step setup
4. **Implement mandatory audit logging**
5. **Test thoroughly**
6. **Deploy with confidence**

---

## 📝 Changelog

### 2.0 (in development)
- Started from 1.0 (as installed in `.claude/skills/tfa-integration-fast-core`) on 2026-09-16.
- Added `skills/sso-integration/SKILL.md` (2026-09-27): Claude first asks the developer for the authority URL (identity server URL, e.g. `https://auth.fa.gov.sa/identitymanagementsts`), client ID and redirect URI, checks them, and writes them to `appsettings.json` under `FastCoreSso`, validated at startup. The sign-in flow itself is not written yet.
- The SSO method options now list the redirect URI among the required settings.
- `skills/sso-integration/SKILL.md` completed (2026-09-27), drawing on the `oauth2-oidc-implementer` skill but rewritten for ASP.NET Core and React: Authorization Code + PKCE, backend-for-frontend (recommended) or SPA, optional scopes / post-logout redirect URI / client secret, sign-in and sign-out endpoints, local-only `returnUrl`, `401` for API routes, reactive refresh on 401, audit logging, and a verification checklist. Dropped from the source skill: Next.js code, social providers, client credentials (belongs to server-to-server), proactive refresh, and tokens in an unencrypted cookie.
- Renamed `skills/sso-integration/` to `skills/sso-integration-server-side/` (skill name `sso-integration-server-side`), with references updated (2026-09-27).
- Added `skills/sso-integration-client-side/` (2026-09-27): frontend-only SSO for React, Angular, Vue and other frameworks, adapted from the `oidc-integration` skill by jeff-tian (v0.1.0) with its Spring Boot backend content removed. The server-side guide's SPA section now points to it.

### 1.0
- Claude asks the user to choose the integration method from an arrow-key list before doing anything, marking any method already set up, then asks method-specific follow-up questions.
- Added "Guide availability" and "Mandatory rules for every method" (caller identity in audit logs, no query strings in logs, per-caller rate limiting, paged database reads).
- Database-views guide renamed to `skills/db-view-integration/SKILL.md`.
- Only the database-views guide is written; the other three method folders are still empty.

---

**Last Updated:** September 2026  
**Plugin Version:** 2.0 (in development)  
**Status:** In development — use `tfa-integration-fast-core` (1.0) for real work

Happy integrating! 🚀
