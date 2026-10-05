# Pre-deployment checklist

Every item must pass before a deployment. When you generate or review data-access code, finish by printing this checklist with ✅ (verified), ❌ (failing, with the file and a fix) or ➖ (not applicable, e.g. the view items when there are no views). Verify each item against the code; never tick one from memory.

Report in this format:

```
Pre-deployment checklist
- ✅ Connection string in appsettings.json
- ✅ DbContext configured and registered
- ➖ All views mapped in OnModelCreating (no views in this solution)
- ❌ Error handling in all methods: OrderRepository.GetRecentAsync bypasses DataAccessGuard (src/Catalog.Infrastructure/Persistence/Repositories/OrderRepository.cs:42)
- ...
```

| # | Item | How to verify |
|---|------|---------------|
| 1 | Connection string in appsettings.json | `ConnectionStrings:DefaultConnection` (and `ReadOnlyConnection` if views are used) exists in `appsettings.json`. `grep -rn "Server=\|Data Source=" --include=*.cs src/` returns nothing. Production values come from env vars or a vault under the same key. |
| 2 | DbContext configured and registered | `AddDbContextPool<AppDbContext>` / `AddDbContextPool<ReadOnlyDbContext>` in `AddInfrastructure`, using `UseSqlServer` with settings from `DatabaseOptions`. The app starts with `ValidateOnBuild = true`. |
| 3 | All views mapped in OnModelCreating | Each database view used has an `IEntityTypeConfiguration<T>` with `ToView("name", "schema")` and a key choice, applied in `ReadOnlyDbContext.OnModelCreating`. The `AllViews_AreQueryable` integration test passes against the target database. |
| 4 | SaveChanges() blocked (read-only enforcement) | `ReadOnlyDbContext` overrides `SaveChanges(bool)` and `SaveChangesAsync(bool, CancellationToken)` to throw `InvalidOperationException`, and uses `NoTracking`. The `SaveChangesAsync_OnReadOnlyContext_Throws` test passes. The SQL login is `db_datareader` only. |
| 5 | Repository interface implemented | Every entity and view has an `I{Name}Repository` in Domain, an implementation in Infrastructure deriving from `Repository<T>`/`ReadOnlyRepository<T>`, and a DI registration. |
| 6 | Service layer created | `I{Name}Service` + implementation in Application, registered in `AddApplication`. No controller injects `DbContext` or a repository (`grep -rn "DbContext\|Repository" src/*.Api/Controllers` returns nothing). |
| 7 | DTOs defined | Response and request records in `Application/{Feature}/Dtos`. No entity or read-model type appears in controller signatures or service return types. |
| 8 | Dependency injection configured | `Program.cs` calls only `AddApplication` / `AddInfrastructure` (+ `ICurrentUser`). Options use `ValidateDataAnnotations().ValidateOnStart()`. `ValidateScopes` and `ValidateOnBuild` are enabled, and the app starts cleanly. |
| 9 | Audit logging implemented | `AuditableEntityInterceptor` is registered for writes. Every read-service method goes through `IAuditLogger` (success and failure). The `Audit` sink writes `logs/audit-*.log`. |
| 10 | Error handling in all methods | Every public method validates its arguments. Every database-touching repository method uses `DataAccessGuard`. Services throw typed exceptions. `GlobalExceptionHandler` maps them to 400/404/409/503/500. No empty `catch`. |
| 11 | Parameterized queries used | LINQ only, or `FromSql`/`FromSqlInterpolated`/`ExecuteSql`. `grep -rn "FromSqlRaw\|ExecuteSqlRaw\|SqlCommand" src/` finds no concatenated or interpolated input. |
| 12 | Connection pooling enabled | `AddDbContextPool` (with `Database:DbContextPoolSize`), plus `Pooling=True;Min Pool Size=5;Max Pool Size=100` in every connection string. No manually created, undisposed `SqlConnection`. |
| 13 | Timeout configured (30 seconds) | `Database:CommandTimeoutSeconds = 30`, applied through `sql.CommandTimeout(...)`, and `Connect Timeout=30` in every connection string. |
| 14 | Skinny controllers, no business code in the Api layer | Every controller and Api type passes the [validation procedure in presentation-layer.md](presentation-layer.md#validation-procedure-run-on-every-review-and-before-deployment): no data access, no domain types, no business branching, LINQ or try/catch, one service call per action. Print the "Skinny controller check" block. |

Also confirm before release:
- `EnableSensitiveDataLogging` and `EnableDetailedErrors` are `false` in Production settings.
- Migrations are reviewed, and an idempotent script or bundle has been generated. `ApplyMigrationsOnStartup` is `false` in Production.
- `/health` reports the database as healthy in the target environment, and all tests pass.
