# TFA .NET standard (Clean Architecture + EF Core)

The rules every .NET/C# project follows. `/fa:init` copies this page into `context/code-standards.md`, where it is loaded every session. The how-to (workflow, code templates, checklists) is the `tfa-development-guard` skill.

## Dependency rule (never violate)

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

- Follow SOLID principles, and use names that reflect domain concepts.
- **DRY (Don't Repeat Yourself)**: if the same logic appears twice, extract it into a reusable service, extension method or helper class. Also reuse the base repository, mapping extensions and shared base classes.
- **Single Responsibility Principle**: each class and method does one thing and does it well. If a method has more than one responsibility, split it into focused, single-purpose methods.
- **Skinny controllers, fat services**: controllers are thin orchestrators that delegate to application services. Business logic belongs in services (and domain entities), never in controllers. A controller action may only:
  1. accept and validate input,
  2. call service methods,
  3. return the appropriate HTTP response.
- **Early returns and guard clauses**: avoid deep nesting. Handle invalid arguments, error conditions and edge cases at the top of the method and return or throw immediately. The happy path stays unindented at the end.
- **Small, focused functions**: keep methods under 20–25 lines where possible. When a method grows longer, extract well-named private helpers. Each method should be understandable at a glance.
- **Modularity**: organize code into logical namespaces and project layers. Group related functionality by feature (`{Solution}.{Layer}.{Feature}`), following Clean Architecture (the layout above) or Vertical Slice Architecture where the project already uses it. Don't mix the two within one feature.
