# Review checklist

When reviewing code, flag any of the following:
- [ ] A layer references a project that the dependency rule forbids, or Domain has EF/ASP.NET dependencies
- [ ] A controller uses `DbContext` or a repository directly, or returns entities instead of DTOs
- [ ] A controller action contains business logic (branching on domain rules, calculations, multiple service orchestration steps) instead of delegating to a service
- [ ] Duplicated logic (the same code in two or more places) that should be a shared service, extension method or helper
- [ ] A class or method with more than one responsibility
- [ ] Deep nesting (more than three levels) where guard clauses and early returns would flatten it
- [ ] Captive dependencies (a singleton holding a scoped service), N+1 queries, or synchronous I/O
- [ ] Exceptions caught locally to steer logic, magic numbers/strings, or missing validation
- [ ] A method longer than ~25 lines that could be split into focused helpers
- [ ] Code placed in the wrong layer or namespace for its feature
- [ ] A repository calls `SaveChanges`, or a service calls it more than once per use case
- [ ] A read query is missing `AsNoTracking()`, or a list is filtered in memory
- [ ] A hard-coded connection string, timeout, page size or log level
- [ ] A missing `CancellationToken`, or use of `.Result`/`.Wait()`
- [ ] String-interpolated log messages, or sensitive data logging enabled outside Development
- [ ] A schema change without a migration, or edits to an already-applied migration
- [ ] Missing XML docs on public APIs, or missing tests for new services
