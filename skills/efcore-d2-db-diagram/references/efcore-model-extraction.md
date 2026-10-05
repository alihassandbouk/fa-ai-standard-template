# EF Core model extraction

## Files to inspect

In this order:

1. `DbContext` classes.
2. `DbSet<T>` declarations.
3. `OnModelCreating`.
4. `IEntityTypeConfiguration<T>` classes.
5. Entity classes.
6. Migrations and model snapshot.
7. Data annotations.

## Source priority

When sources disagree:

1. Latest applied migration / migration snapshot.
2. Fluent API configuration in `OnModelCreating` or `IEntityTypeConfiguration<T>`.
3. Data annotations.
4. EF Core conventions.
5. Raw C# class shape.

## Concepts to detect and represent

- `DbContext` and `DbSet<T>`.
- Entity class names and actual table names from `ToTable`.
- Schema names from `ToTable("Table", "schema")`.
- Primary keys from `HasKey`, `[Key]`, conventions and migrations.
- Composite keys.
- Foreign keys from `HasForeignKey`, navigation properties and migration operations.
- Delete behavior when explicit: `Cascade`, `Restrict`, `NoAction`, `SetNull`, `ClientSetNull`.
- Required/optional relationship markers.
- Owned types from `OwnsOne`, `OwnsMany` and `[Owned]`.
- Many-to-many relationships from `UsingEntity` and implicit EF Core join tables.
- Indexes from `HasIndex`, `IsUnique` and migrations.
- Alternate keys from `HasAlternateKey`.
- Shadow properties configured in Fluent API.
- Value conversions when they affect persisted type or readability.
- Enum properties.
- Ignored properties and ignored entities.

## Fluent API calls to look for

`ToTable`, `HasKey`, `HasAlternateKey`, `HasIndex`, `IsUnique`, `Property`,
`HasColumnName`, `HasColumnType`, `IsRequired`, `HasMaxLength`,
`HasConversion`, `HasOne`, `WithMany`, `WithOne`, `HasForeignKey`,
`OnDelete`, `OwnsOne`, `OwnsMany`, `UsingEntity`, `Ignore`.

## Migrations

Use migrations to confirm actual table names, join tables, shadow FK columns,
indexes, composite keys, delete behaviors, and migration-only tables.
