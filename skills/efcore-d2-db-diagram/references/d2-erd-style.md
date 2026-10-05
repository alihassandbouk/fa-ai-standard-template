# D2 ERD style

## Header

```d2
vars: {
  d2-config: {
    layout-engine: elk
    theme-id: 300
  }
}
```

## Tables

Each persisted table is a node with `shape: sql_table`:

```d2
Clients: {
  shape: sql_table
  Id: uuid {constraint: primary_key}
  Name: varchar(200)
  Status: enum
}
```

If `sql_table` is unavailable or fails validation, fall back to a rectangle
with structured text.

## Relationships

Directional edges from dependent table to principal table. The label carries
the cardinality and the FK name when known:

```d2
Offers.ClientId -> Clients.Id: "N:1 FK_Offers_Clients_ClientId"
```

Cardinality labels: `1:1`, `1:N`, `N:1`, `N:N`, `owned`. Inside containers,
edge endpoints use full dot-notation.

## Owned types

Inline by default:

```d2
Clients: {
  shape: sql_table
  Id: uuid {constraint: primary_key}
  Address.Street: text
  Address.ZipCode: text
  Address.City: text
}
```

With `separate`, owned types are visually subordinate tables joined by an
`owned` relationship.

## Many-to-many

Explicit join tables by default, because EF Core creates real tables. For an
implicit many-to-many, create a generated join table node marked
`implicit join`.

## Technical tables

Hidden by default: `__EFMigrationsHistory`, Hangfire tables, ASP.NET Identity
tables, audit logs, outbox tables. Hidden tables are listed in the summary
after the diagram.

## Styles

- Primary entity tables: solid border.
- Join tables: dashed border.
- Owned types: lighter stroke or nested inline fields.
- Technical tables: muted style.
- External tables or migration-only tables: dotted border.
- Required relationships: solid line.
- Optional relationships: dashed line.
- Cascade delete: label suffix `cascade`.

```d2
classes: {
  join_table: {
    style.stroke-dash: 4
  }
  technical: {
    style.opacity: 0.55
  }
  optional_relation: {
    style.stroke-dash: 3
  }
}
```
