---
name: efcore-d2-db-diagram
description: Generate a D2 entity-relationship diagram from Entity Framework Core models. Use when asked for a database diagram, ERD or schema visual of a DbContext.
allowed-tools: Read
---

# EF Core D2 database diagram

Create a D2 entity-relationship diagram that reflects the actual EF Core
persistence model (tables, keys, relationships, owned types, join tables,
indexes, table names), not the raw C# class shape. Output is `.d2` source,
rendered to SVG or PNG with the `d2` CLI; no MCP server is involved.

## Steps

1. **Extract the model.** Locate every `DbContext`, `DbSet<T>`, entity,
   owned type, enum and value object; read `OnModelCreating`, every
   `IEntityTypeConfiguration<T>`, and the migrations when present, by the
   rules and source priority in `references/efcore-model-extraction.md`.
   Done when a normalised database model exists; D2 is written from it, not
   from class nesting. A regeneration re-reads mappings and migrations first.
2. **Ask the questionnaire** below, unless the request already answered it.
3. **Generate the `.d2`** from the model: `references/d2-erd-style.md` for
   nodes, edges, owned types, join tables, technical tables and styles;
   `references/relationship-rules.md` to infer each relationship;
   `references/grouping-modes.md` for the containers.
4. **Validate and render.** `d2 fmt` on the file, then
   `d2 --layout=<engine> docs/schema.d2 docs/schema.svg` when `d2` is
   installed. Done when every line of `references/quality-gate.md` holds.
5. **Deliver.** Write `docs/schema.d2` (and `docs/schema.svg` when rendered)
   unless the user names another path; `context/architecture.md` links to it
   under *Data & domain model*. Then give the `.d2` content, the render
   command for the chosen engine, and a summary of assumptions and hidden
   tables.

## Questionnaire

Ask for every new diagram and every regeneration. The default column answers
a request for a quick generation.

| Question | Choices | Default |
|---|---|---|
| Which DbContext? | auto-detect / all / a name | auto-detect |
| Display columns? | all / key-only / none | key-only |
| Display column types? | yes / no | yes |
| Display nullable/required markers? | yes / no | yes |
| Display indexes and unique constraints? | yes / no | yes |
| Display enum values? | yes / no | no |
| Display owned types? | inline / separate / hide | inline |
| Display many-to-many join tables? | explicit / compact / hide | explicit |
| Display audit/technical tables? | yes / no | no |
| Display migration-only tables not present as entities? | yes / no | yes |
| Grouping mode? | bounded-context / schema / namespace / flat | bounded-context |
| Layout engine? | elk / dagre / tala | elk |
| Output format? | d2 / svg / png | d2 |
