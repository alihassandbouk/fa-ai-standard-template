# Audit mode

Run when product UI already exists and pattern consistency is uncertain, or
before establishing `context/ui-patterns.md` for the first time.

1. **Scan** every screen in the product. Group them by what they do: lists,
   detail views, create/edit flows, dashboards, empty/error handling.
2. **Extract the dominant pattern per group**, the composition most screens
   already share, and every deviation from it: same job, different shape.
3. **Report** patterns and conflicts. For each conflict, recommend which
   shape should win, based on what the majority does and what the design
   system intends. Also list every local build with no entry in
   `context/ui-patterns.md`, and every raw element doing a component's job.
4. **Wait.** Present and ask; the registry and the screens stay untouched
   until the developer confirms the baseline. Then write
   `context/ui-patterns.md` and produce the fix list of deviating screens.
