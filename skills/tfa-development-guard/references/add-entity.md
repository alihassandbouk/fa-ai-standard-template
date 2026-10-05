# Adding an entity end to end

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
11. **Diagram**: if the change added or altered an entity, relationship or table, regenerate `docs/schema.d2` with `/fa:efcore-d2-db-diagram`.
12. **Tests**: write service unit tests (mock the repositories and `IUnitOfWork`) and repository integration tests.
13. **Checklist**: run the [pre-deployment checklist](pre-deployment-checklist.md) and report its status.

For a **database view** (read-only), follow the same order using [read-only-views.md](read-only-views.md). The steps are: read model, `I{View}Repository : IReadOnlyRepository<T>`, `ToView` configuration, a `DbSet` on `ReadOnlyDbContext`, repository, DTO, service with auditing, DI, then a GET-only controller. There is no migration step unless the app owns the view's DDL.
