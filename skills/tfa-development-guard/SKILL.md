---
name: tfa-development-guard
description: Build and review .NET/C# code against the TFA Clean Architecture standard — Domain, Application, Infrastructure and Api layers, EF Core code-first with SQL Server migrations, read-only view access, repositories, services, DTOs, controllers, appsettings-driven configuration, Serilog audit logging, and the pre-deployment checklist. Use when creating or reviewing any .NET solution, adding an entity or view, scaffolding a layer, or preparing a deployment.
---

# .NET/C# Best Practices (Clean Architecture + EF Core)

Your task is to ensure the .NET/C# code under review (or the code you are generating) follows the architecture and practices below. When the user asks for a feature that touches data (e.g. "get products from the database"), generate **every layer** end to end, following [Workflow: adding an entity](#workflow-adding-an-entity-end-to-end).

## Solution Layout

```
{Solution}.sln
src/
  {Solution}.Domain/           # Core: entities, value objects, domain exceptions, repository interfaces
  {Solution}.Application/      # Use cases: services, DTOs, mappings, options, application exceptions
  {Solution}.Infrastructure/   # EF Core DbContext, entity configurations, repositories, migrations
  {Solution}.Api/              # Presentation: controllers, middleware, Program.cs, appsettings*.json
tests/
  {Solution}.Domain.Tests/
  {Solution}.Application.Tests/
  {Solution}.Infrastructure.Tests/   # integration tests against SQL Server
  {Solution}.Api.Tests/
```

The dependency rule and every other coding rule live in [references/standards.md](references/standards.md). In a project set up with `/fa:init` they are already in `context/code-standards.md`; if that file does not contain them, read `references/standards.md` before writing any code.

## Layer Reference Files

Load the file for the layer you are working on. Each one has complete, compilable templates:

| File | Contents |
|------|----------|
| [references/domain-layer.md](references/domain-layer.md) | `BaseEntity`, entity models, `DomainException`, `IRepository<T>`, entity repository interfaces, `IUnitOfWork` |
| [references/infrastructure-layer.md](references/infrastructure-layer.md) | `AppDbContext`, `IEntityTypeConfiguration<T>`, audit interceptor, `Repository<T>` base, entity repositories, `DatabaseOptions`, DI registration, migrations |
| [references/application-layer.md](references/application-layer.md) | DTOs and request records, mapping extensions, service interface + implementation, application exceptions, pagination options, DI registration |
| [references/standards.md](references/standards.md) | The rules: dependency rule, persistence, configuration, logging, error handling, testing, security, code quality |
| [references/presentation-layer.md](references/presentation-layer.md) | `Program.cs`, Serilog setup, global exception handler, example controller, `appsettings.json` / `appsettings.Development.json`, NuGet packages |
| [references/read-only-views.md](references/read-only-views.md) | Read-only access to SQL Server views: `ReadOnlyDbContext` (SaveChanges blocked), `ToView` mappings, `IReadOnlyRepository<T>`, `DataAccessGuard` error handling, audit logging (`IAuditLogger`, `ICurrentUser`), report service and controller, read-only tests |

## Workflow: Adding an Entity End to End

Do these steps in order. Use `Product` in the reference files as the template:

1. **Entity model** (Domain/`{Feature}`): inherit from `BaseEntity`. Use private setters, a private parameterless constructor for EF, and behaviour methods that enforce invariants.
2. **Repository interface** (Domain/`{Feature}`): `I{Entity}Repository : IRepository<{Entity}>`. Add only the entity-specific queries.
3. **Entity configuration** (Infrastructure/Persistence/Configurations): `{Entity}Configuration : IEntityTypeConfiguration<{Entity}>`. It covers the table name, keys, lengths, precision, indexes and relationships. Never use data annotations on domain entities.
4. **DbContext**: add `DbSet<{Entity}> {Entities} => Set<{Entity}>();` to `AppDbContext`. Configurations are picked up by `ApplyConfigurationsFromAssembly`, filtered to the `Persistence.Configurations` namespace, so the class must live there.
5. **Repository implementation** (Infrastructure/Persistence/Repositories): `{Entity}Repository : Repository<{Entity}>, I{Entity}Repository`.
6. **DTOs** (Application/`{Feature}`/Dtos): a `{Entity}Dto` response record, plus `Create{Entity}Request` and `Update{Entity}Request` records with validation attributes. Add a `{Entity}Mappings` extension class.
7. **Service** (Application/`{Feature}`): `I{Entity}Service` + `{Entity}Service`. The service orchestrates repositories, calls `IUnitOfWork.SaveChangesAsync`, logs, and maps entities to DTOs.
8. **DI registration**: register the repository in `Infrastructure/DependencyInjection.cs` and the service in `Application/DependencyInjection.cs`.
9. **Controller** (Api/Controllers): `{Entities}Controller`, a thin REST controller that calls the service only.
10. **Migration**: from the solution root, run:
    ```bash
    dotnet ef migrations add Add{Entity} --project src/{Solution}.Infrastructure --startup-project src/{Solution}.Api --output-dir Persistence/Migrations
    dotnet ef database update --project src/{Solution}.Infrastructure --startup-project src/{Solution}.Api
    ```
    Review the generated migration before applying it. Never edit a migration that has already been applied to a shared database. Add a new one instead.
11. **Tests**: write service unit tests (mock the repositories and `IUnitOfWork`) and repository integration tests.
12. **Checklist**: run the [pre-deployment checklist](#pre-deployment-checklist) and report its status.

For a **database view** (read-only), follow the same order using [references/read-only-views.md](references/read-only-views.md). The steps are: read model, `I{View}Repository : IReadOnlyRepository<T>`, `ToView` configuration, a `DbSet` on `ReadOnlyDbContext`, repository, DTO, service with auditing, DI, then a GET-only controller. There is no migration step unless the app owns the view's DDL.

## Pre-Deployment Checklist

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

Also confirm before release:
- `EnableSensitiveDataLogging` and `EnableDetailedErrors` are `false` in Production settings.
- Migrations are reviewed, and an idempotent script or bundle has been generated. `ApplyMigrationsOnStartup` is `false` in Production.
- `/health` reports the database as healthy in the target environment, and all tests pass.

## Review Checklist

When reviewing code, flag any of the following:
- [ ] A layer references a project that the dependency rule forbids, or Domain has EF/ASP.NET dependencies
- [ ] A controller uses `DbContext` or a repository directly, or returns entities instead of DTOs
- [ ] A repository calls `SaveChanges`, or a service calls it more than once per use case
- [ ] A read query is missing `AsNoTracking()`, or a list is filtered in memory
- [ ] A hard-coded connection string, timeout, page size or log level
- [ ] A missing `CancellationToken`, or use of `.Result`/`.Wait()`
- [ ] String-interpolated log messages, or sensitive data logging enabled outside Development
- [ ] A schema change without a migration, or edits to an already-applied migration
- [ ] Missing XML docs on public APIs, or missing tests for new services
