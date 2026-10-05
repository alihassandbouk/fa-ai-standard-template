---
name: tfa-development-guard
description: Build and review .NET/C# code against the TFA Clean Architecture standard. Use for any .NET work: a new solution, an entity or view, a layer, a refactor, or a deployment.
allowed-tools: Read
---

# .NET/C# Best Practices (Clean Architecture + EF Core)

Every .NET/C# file you write or review follows the TFA standard. A feature
that touches data ("get products from the database") is generated across
every layer, end to end.

## Solution layout

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

## Layer reference files

Load the file for the layer you are working on. Each one has complete, compilable templates:

| File | Contents |
|------|----------|
| [references/domain-layer.md](references/domain-layer.md) | `BaseEntity`, entity models, `DomainException`, `IRepository<T>`, entity repository interfaces, `IUnitOfWork` |
| [references/infrastructure-layer.md](references/infrastructure-layer.md) | `AppDbContext`, `IEntityTypeConfiguration<T>`, audit interceptor, `Repository<T>` base, entity repositories, `DatabaseOptions`, DI registration, migrations |
| [references/application-layer.md](references/application-layer.md) | DTOs and request records, mapping extensions, service interface + implementation, application exceptions, pagination options, DI registration |
| [references/standards.md](references/standards.md) | The rules: dependency rule, persistence, configuration, logging, error handling, testing, security, code quality |
| [references/presentation-layer.md](references/presentation-layer.md) | `Program.cs`, Serilog setup, global exception handler, example controller, skinny-controller rules and validation procedure, `appsettings.json` / `appsettings.Development.json`, NuGet packages |
| [references/read-only-views.md](references/read-only-views.md) | Read-only access to SQL Server views: `ReadOnlyDbContext` (SaveChanges blocked), `ToView` mappings, `IReadOnlyRepository<T>`, `DataAccessGuard` error handling, audit logging (`IAuditLogger`, `ICurrentUser`), report service and controller, read-only tests |

## Branches

| Doing | Read |
|---|---|
| Adding an entity or a read-only view, or any feature that touches data | [references/add-entity.md](references/add-entity.md), then the pre-deployment checklist |
| Refactoring, or a review that found code-quality violations | [references/refactoring.md](references/refactoring.md) |
| Reviewing code (`/fa:review` in a .NET repo) | [references/review-checklist.md](references/review-checklist.md), then the skinny-controller validation procedure in [references/presentation-layer.md](references/presentation-layer.md#validation-procedure-run-on-every-review-and-before-deployment) |
| Finishing generated or reviewed data-access code, or preparing a deployment | [references/pre-deployment-checklist.md](references/pre-deployment-checklist.md): print it with every item verified against the code |
