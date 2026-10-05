# Refactoring workflow

When asked to refactor, or when a review finds code-quality violations, follow these steps in order. **Refactoring never changes behavior.** If a behavior change is needed, report it separately and do it as its own task.

### 1. Analyze

Read the code thoroughly before changing anything: its purpose, inputs, outputs and side effects (database writes, audit/log records, cookies, idempotency ledger entries, thrown exceptions and the HTTP status each maps to). Find the tests that cover it. If coverage is missing for behavior you're about to touch, add characterization tests first.

### 2. Identify issues

Look for:

- Business logic in controllers (it belongs in services; see [presentation-layer.md](presentation-layer.md#skinny-controllers-no-business-code-in-the-presentation-layer))
- Code duplication
- Long or complex methods (more than 25 lines)
- Deep nesting (more than 3 levels)
- Multiple responsibilities in one class or method
- Missing or incorrect nullable annotations
- Captive dependencies (a singleton holding a scoped service such as `DbContext`, a repository or `ICurrentUser`)
- N+1 queries (a query inside a loop, or lazy navigation access per row). Use `Include`, projection or one batched query instead.
- Synchronous I/O that should be async
- A `CancellationToken` that isn't propagated down to EF Core and other I/O
- Exceptions used for flow control, i.e. thrown and caught locally to steer logic. Typed exceptions that surface to `GlobalExceptionHandler` are the project standard and are **not** flow control.
- Magic numbers or strings that should be constants or options (appsettings)
- Missing argument or request validation
- Places where modern C# features would help readability

### 3. Plan

Before editing, outline the strategy and share it with the user:

- Which logic moves from controllers to services?
- What can be extracted into separate methods, classes or extension methods?
- What can be simplified with early returns or pattern matching?
- Which duplicated code can be consolidated, and where does the shared version live (which layer and namespace)?
- Which modern C# features improve readability?
- Should CQRS/MediatR be introduced? Only propose it. Adding MediatR is a new dependency and an architecture change, so it needs the user's approval and is never part of a behavior-preserving refactor. If the project doesn't already use it, the default answer is no.

### 4. Execute incrementally

Make one kind of change at a time, in this order, and run the tests after each step:

1. Extract business logic from controllers into services.
2. Extract duplicated code into reusable methods or classes.
3. Apply early returns and guard clauses to reduce nesting.
4. Split large methods into smaller ones.
5. Rename symbols for clarity. Use `mcp__jetbrains__rename_refactoring` when that tool is available, because it updates every reference safely. Otherwise rename with the IDE, or search all references (`grep -rn "\bOldName\b"`) and update each one, then build. Never rename persisted names (tables, columns, JSON contract fields, API routes, audit action codes) as part of a refactor, because that changes behavior.
6. Add proper nullable annotations and explicit type declarations.
7. Apply modern C# features: records, pattern matching, collection expressions, primary constructors.
8. Introduce the Result pattern for error handling **only if the project already uses it or the user approves it**. The standard in this skill is typed exceptions mapped by `GlobalExceptionHandler` (see [Error Handling](standards.md#error-handling)). Don't mix both styles in one feature.

### 5. Preserve behavior

The refactored code must behave identically: same outputs, same side effects, same exception types, HTTP status codes and ProblemDetails, same log and audit records, and the same database queries in effect. Don't fix bugs, change validation rules or alter public contracts while refactoring. List any bugs you find and handle them separately.

### 6. Run tests

Run `dotnet test` (or the project's verified test command) after each step above, not only at the end. If a test fails, stop and fix or revert that step before continuing. Never report tests as passing without running them. If tests can't be run, say so explicitly.

### 7. Document changes

Finish with a summary of what was refactored and why, organized by step. For each change, give the file, the issue it fixed (from step 2) and the specific improvement (e.g. "`UsersController.Create` 38 → 4 lines, logic moved to `UserAdministrationService.CreateAsync`"). Include the test command and its result, and anything left undone.
