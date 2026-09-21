---
name: tfa-development-guard
description: 'Build and review .NET/C# code using Clean Architecture (Domain, Application, Infrastructure, Presentation) with EF Core code-first + SQL Server migrations, read-only SQL Server view access, base/entity repositories, application services, DTOs, controllers, appsettings-driven configuration, audit and full structured logging, and a pre-deployment checklist. Use when creating or reviewing .NET solutions, adding entities/features that read or write the database, mapping database views, scaffolding DbContext/repositories/services/controllers, preparing a deployment, or checking C# code against project best practices.'
---

# .NET/C# Best Practices (Clean Architecture + EF Core)

Your task is to ensure .NET/C# code in ${selection} (or the code you are generating) follows the architecture and practices below. When the user asks for a feature that touches data (e.g. "get products from the database"), generate **every layer** end to end, following [Workflow: adding an entity](#workflow-adding-an-entity-end-to-end).

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

### Dependency rule (never violate)

| Project        | May reference                  | Must NOT reference                         |
|----------------|--------------------------------|--------------------------------------------|
| Domain         | nothing (BCL only)             | EF Core, ASP.NET Core, any other layer     |
| Application    | Domain                         | Infrastructure, Api, EF Core               |
| Infrastructure | Domain, Application            | Api                                        |
| Api            | Application, Infrastructure    | — (Infrastructure is used only for DI wiring in Program.cs) |

- Repository interfaces and `IUnitOfWork` live in **Domain**. Their implementations live in **Infrastructure**.
- Controllers talk **only to application services**. They never use `DbContext` or repositories.
- Services return **DTOs**, never entities. Entities never leave the Application layer.
- Namespaces follow `{Solution}.{Layer}.{Feature}`, e.g. `Catalog.Application.Products`.

## Layer Reference Files

Load the file for the layer you are working on. Each one has complete, compilable templates:

| File | Contents |
|------|----------|
| [references/domain-layer.md](references/domain-layer.md) | `BaseEntity`, entity models, `DomainException`, `IRepository<T>`, entity repository interfaces, `IUnitOfWork` |
| [references/infrastructure-layer.md](references/infrastructure-layer.md) | `AppDbContext`, `IEntityTypeConfiguration<T>`, audit interceptor, `Repository<T>` base, entity repositories, `DatabaseOptions`, DI registration, migrations |
| [references/application-layer.md](references/application-layer.md) | DTOs and request records, mapping extensions, service interface + implementation, application exceptions, pagination options, DI registration |
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

## Persistence (EF Core, Code First, SQL Server)

- Use a code-first model with **migrations only**. Never call `EnsureCreated()` outside throwaway tests.
- There is one read/write `AppDbContext` (plus an optional `ReadOnlyDbContext` for views). `AppDbContext` implements `IUnitOfWork`, and repositories **do not** call `SaveChanges`. The service decides the transaction boundary.
- Read queries use `AsNoTracking()`. Load an entity tracked (`GetByIdAsync`) only when you intend to modify it.
- Project to DTOs or page results in the database (`Skip`/`Take` + `CountAsync`). Never load a whole table just to filter it in memory.
- Set `CreatedAtUtc`/`UpdatedAtUtc` centrally in a `SaveChangesInterceptor`, not in services.
- Configure retries (`EnableRetryOnFailure`), command timeout and migrations assembly from `DatabaseOptions`.
- EF Core parameterizes all LINQ queries. With raw SQL, use `FromSqlInterpolated`/`FromSql` only. **Never** `FromSqlRaw` with string concatenation.
- Deletes use `DeleteBehavior.Restrict` by default. Cascade only when the child cannot exist without its parent.
- Register contexts with `AddDbContextPool`, and keep ADO.NET pooling on in the connection string (`Pooling=True;Min Pool Size;Max Pool Size`). Interceptors used by pooled contexts must be singletons.
- Timeouts come from appsettings: `Database:CommandTimeoutSeconds` (30) and `Connect Timeout=30` in the connection string.

### Read-only data (SQL Server views)

- Views are served by a separate `ReadOnlyDbContext` on `ConnectionStrings:ReadOnlyConnection`. Each view has an `IEntityTypeConfiguration<T>` with `ToView(...)` and `HasNoKey()`/`HasKey(...)`, and explicit column names.
- `ReadOnlyDbContext` overrides `SaveChanges(bool)` and `SaveChangesAsync(bool, CancellationToken)` to throw, and uses `QueryTrackingBehavior.NoTracking`. The SQL login has read permission only.
- View repositories implement `IReadOnlyRepository<T>`, which has no add, update or remove. Controllers expose GET only.
- `AppDbContext` and `ReadOnlyDbContext` apply only their own configurations (filtered by namespace). EF commands use `--context AppDbContext`.

## Configuration: Everything in appsettings

- **No hard-coded** connection strings, timeouts, page sizes, log levels, URLs or feature flags. All of them live in `appsettings.json` and are overridden per environment in `appsettings.{Environment}.json`.
- Connection strings go in `ConnectionStrings:DefaultConnection`. Secrets for real environments come from user-secrets, environment variables (`ConnectionStrings__DefaultConnection`) or a vault. They use the same keys and are never committed.
- Bind each section to a strongly-typed options class with a `const string SectionName`, data annotations, and `ValidateDataAnnotations().ValidateOnStart()`.
- Inject `IOptions<T>` (or `IOptionsMonitor<T>` for values that can change at runtime). Never inject raw `IConfiguration` into services.

## Logging: Full Logs Enabled

- Use **Serilog** configured entirely from the `Serilog` section of appsettings (`ReadFrom.Configuration`). Write to Console and a rolling File sink, and enrich with `FromLogContext`, `WithMachineName` and `WithThreadId`.
- Wrap startup in a bootstrap logger with `try/catch/finally` plus `Log.CloseAndFlushAsync()`, so startup failures get logged.
- `UseSerilogRequestLogging()` logs every HTTP request with its status and elapsed time.
- EF Core SQL logging: `Microsoft.EntityFrameworkCore.Database.Command` is `Information` in all environments. In Development, `EnableSensitiveDataLogging` and `EnableDetailedErrors` are `true` (from `Database` options) so parameter values and detailed errors are logged. **Never enable sensitive data logging in Production.**
- Development uses a `Debug` minimum level. Production uses `Information` with `Microsoft.*` overrides set to `Warning`.
- Use structured message templates (`logger.LogInformation("Created product {ProductId}", id)`). Never string interpolation.
- Services log at the start of writes (`Information`), on not-found and conflicts (`Warning`) and on failures (`Error`, with the exception). Use `logger.BeginScope` for correlation context. Use the `[LoggerMessage]` source generator on hot paths.
- The global exception handler logs every unhandled exception once. Don't log and rethrow the same exception in several layers.
- **Audit logging**:
  - Writes: `AuditableEntityInterceptor` stamps `CreatedAtUtc`/`UpdatedAtUtc`.
  - Reads: services call `IAuditLogger` for every data access, successful or failed. Each record holds the operation, resource, user (from `ICurrentUser`), criteria, row count and elapsed time.
  - Audit records go to a dedicated `logs/audit-*.log` sink with 90-day retention.

## Documentation & Structure

- Write XML documentation comments for all public classes, interfaces, methods and properties.
- Include `<param>`, `<returns>` and `<exception>` descriptions.
- Put one public type per file, with the file name matching the type name.

## Design Patterns & Architecture

- Use primary constructor syntax for dependency injection, e.g. `public sealed class ProductService(IProductRepository repository, ...)`.
- Use the generic base repository (`Repository<TEntity>`) with entity-specific repositories that extend it.
- Prefix interfaces with `I` and keep them small and focused (interface segregation).
- Use rich domain models, where behaviour and invariants live in entities, rather than anemic property bags.
- Use the Factory pattern for complex object creation, and the Command Handler pattern (`CommandHandler<TOptions>`) where the project already uses it.
- Seal classes that are not designed for inheritance.

## Dependency Injection & Services

- Guard primary-constructor dependencies with a null check: `private readonly IFoo _foo = foo ?? throw new ArgumentNullException(nameof(foo));`.
- Each layer exposes one `DependencyInjection` extension: `AddApplication(configuration)` and `AddInfrastructure(configuration)`. `Program.cs` only calls these.
- Lifetimes: `DbContext`, repositories, `IUnitOfWork` and services are **Scoped**. Stateless helpers and `TimeProvider` are **Singleton**.
- Program against interfaces so everything stays testable.

## Async/Await Patterns

- Use async/await for all I/O. Return `Task`/`Task<T>`, and suffix method names with `Async`.
- Every async method takes a `CancellationToken cancellationToken = default` and passes it down to EF Core. Controllers receive it from ASP.NET Core.
- Use `ConfigureAwait(false)` in Domain, Application and Infrastructure library code. It's not needed in controllers.
- Never use `.Result`, `.Wait()` or `async void`.

## Error Handling

- Domain invariant violations throw `DomainException`. Application-level failures throw `NotFoundException` or `ConflictException`.
- **Every method handles errors.** Every method validates its arguments (`ArgumentNullException.ThrowIfNull`, `ArgumentOutOfRangeException.ThrowIfNegativeOrZero`). Every repository method that hits the database runs through `DataAccessGuard`, which logs provider failures (`DbException`, `TimeoutException`, `RetryLimitExceededException`) and rethrows them as `DataAccessException`. Services throw `NotFoundException`/`ConflictException` for expected failures, and audit failed reads. Empty `catch` blocks are forbidden.
- A single `IExceptionHandler` in the Api layer maps exceptions to RFC 7807 `ProblemDetails`: 400 for domain/argument errors, 404 for not found, 409 for conflicts and duplicate keys, 503 for `DataAccessException`, and 500 otherwise, with no internal details in Production.
- Validate request DTOs with data annotations. `[ApiController]` returns 400 automatically.
- Throw specific exceptions with descriptive messages. Use try/catch only for expected, recoverable failures.

## Resource Management & Localization

- Use `ResourceManager` for localized user-facing messages and error strings when the project is localized.
- Keep separate `LogMessages` and `ErrorMessages` resource files, accessed via `_resourceManager.GetString("MessageKey")`.
- Implement `IDisposable`/`IAsyncDisposable` correctly for owned unmanaged resources. Never dispose DI-managed instances manually.

## Testing Standards

- Use MSTest with FluentAssertions for assertions and Moq for mocking.
- Follow the AAA pattern (Arrange, Act, Assert) and name tests `Method_Scenario_ExpectedResult`.
- **Service tests**: mock `I{Entity}Repository` and `IUnitOfWork`, and verify that `SaveChangesAsync` is called exactly once on writes and never on failure paths.
- **Repository and migration tests**: integration tests against real SQL Server (e.g. `Testcontainers.MsSql`). Don't rely on the EF InMemory provider, because it does not behave like a relational database.
- **Controller tests**: `WebApplicationFactory<Program>` for the HTTP pipeline and status codes.
- Test both success and failure scenarios, including null-argument validation.

## Semantic Kernel & AI Integration (when applicable)

- Use Microsoft.SemanticKernel for AI operations, registered through DI in the Infrastructure layer behind an Application-layer interface.
- Keep model names, endpoints and keys in appsettings (secrets via user-secrets or a vault).
- Use structured output patterns for reliable AI responses, and follow secure coding practices for AI/ML input.

## Performance & Security

- Target .NET 8+ with C# 12+ features (primary constructors, collection expressions, records).
- Enable nullable reference types and treat warnings as errors (`<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`).
- Validate and sanitize all input, and cap page sizes (`PaginationOptions.MaxPageSize`).
- Never expose entities, stack traces or connection strings in API responses.

## Code Quality

- Follow SOLID principles.
- Avoid duplication by using the base repository, mapping extensions and shared base classes.
- Use names that reflect domain concepts.
- Keep methods small, focused and cohesive.

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
