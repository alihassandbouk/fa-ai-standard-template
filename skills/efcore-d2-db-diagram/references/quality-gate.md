# Quality gate

Every line holds before delivery:

- [ ] The selected DbContext is clear.
- [ ] All `DbSet<T>` entities are considered.
- [ ] Fluent API configurations are read.
- [ ] Migrations are checked when present.
- [ ] Table names and schema names match EF Core mapping.
- [ ] Primary keys are present.
- [ ] Foreign keys and cardinalities are represented.
- [ ] Owned types are handled according to user choice.
- [ ] Many-to-many join tables are explicit unless the user asked otherwise.
- [ ] Hidden technical tables are listed in the final summary.
- [ ] D2 syntax is valid with `d2 fmt`.
- [ ] Edge endpoints use full dot-notation when inside containers.
- [ ] The diagram remains readable and avoids crossing-heavy layouts.
- [ ] The render command is provided.
