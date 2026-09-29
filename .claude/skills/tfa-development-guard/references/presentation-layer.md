# Presentation Layer (ASP.NET Core Web API)

Project: `{Solution}.Api`. It references Application and Infrastructure (Infrastructure only for DI wiring in `Program.cs`).

NuGet packages:
- `Serilog.AspNetCore` (includes Console, File and Settings.Configuration)
- `Serilog.Enrichers.Environment`
- `Serilog.Enrichers.Thread`
- `Serilog.Expressions` (routes `Audit` records to their own file)
- `Microsoft.EntityFrameworkCore.Design` (`PrivateAssets="all"`, required by `dotnet ef` in the startup project)
- `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore`
- `Swashbuckle.AspNetCore` (or `Microsoft.AspNetCore.OpenApi` on .NET 9+)

```
{Solution}.Api/
  Program.cs
  appsettings.json
  appsettings.Development.json
  Controllers/
    ProductsController.cs
  Middleware/
    GlobalExceptionHandler.cs
```

## Program.cs

```csharp
using Catalog.Api.Middleware;
using Catalog.Api.Services;
using Catalog.Application;
using Catalog.Application.Common;
using Catalog.Infrastructure;
using Catalog.Infrastructure.Persistence;
using Serilog;

// Bootstrap logger captures startup failures before configuration is loaded.
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateBootstrapLogger();

try
{
    Log.Information("Starting Catalog API");

    var builder = WebApplication.CreateBuilder(args);

    // Full Serilog configuration comes from the "Serilog" section of appsettings.
    builder.Host.UseSerilog((context, services, configuration) => configuration
        .ReadFrom.Configuration(context.Configuration)
        .ReadFrom.Services(services));

    // Fail fast on DI mistakes (missing registrations, captive dependencies) in every environment.
    builder.Host.UseDefaultServiceProvider(options =>
    {
        options.ValidateScopes = true;
        options.ValidateOnBuild = true;
    });

    builder.Services
        .AddApplication(builder.Configuration)
        .AddInfrastructure(builder.Configuration);

    // Caller identity for audit logging.
    builder.Services.AddHttpContextAccessor();
    builder.Services.AddScoped<ICurrentUser, HttpCurrentUser>();

    builder.Services.AddControllers();
    builder.Services.AddProblemDetails();
    builder.Services.AddExceptionHandler<GlobalExceptionHandler>();
    builder.Services.AddEndpointsApiExplorer();
    builder.Services.AddSwaggerGen();
    builder.Services.AddHealthChecks().AddDbContextCheck<AppDbContext>("database");

    var app = builder.Build();

    app.UseExceptionHandler();
    app.UseSerilogRequestLogging();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI();
    }

    app.UseHttpsRedirection();
    app.UseAuthorization();

    app.MapControllers();
    app.MapHealthChecks("/health");

    // Controlled by Database:ApplyMigrationsOnStartup.
    await app.Services.ApplyMigrationsAsync();

    await app.RunAsync();
}
catch (Exception ex) when (ex is not HostAbortedException) // HostAbortedException is thrown by `dotnet ef` tooling
{
    Log.Fatal(ex, "Catalog API terminated unexpectedly");
}
finally
{
    await Log.CloseAndFlushAsync();
}

/// <summary>Entry point, exposed for WebApplicationFactory integration tests.</summary>
public partial class Program;
```

## Middleware/GlobalExceptionHandler.cs

```csharp
using Catalog.Application.Common.Exceptions;
using Catalog.Domain.Common;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Api.Middleware;

/// <summary>
/// Converts unhandled exceptions into RFC 7807 problem details and logs them once.
/// </summary>
/// <param name="problemDetailsService">The problem details writer.</param>
/// <param name="environment">The hosting environment.</param>
/// <param name="logger">The logger.</param>
public sealed class GlobalExceptionHandler(
    IProblemDetailsService problemDetailsService,
    IHostEnvironment environment,
    ILogger<GlobalExceptionHandler> logger) : IExceptionHandler
{
    /// <inheritdoc />
    public async ValueTask<bool> TryHandleAsync(HttpContext httpContext, Exception exception, CancellationToken cancellationToken)
    {
        var (status, title) = exception switch
        {
            NotFoundException => (StatusCodes.Status404NotFound, "Resource not found"),
            ConflictException => (StatusCodes.Status409Conflict, "Conflict"),
            DbUpdateException { InnerException: SqlException { Number: 2601 or 2627 } } =>
                (StatusCodes.Status409Conflict, "Duplicate key"),
            DomainException or ArgumentException => (StatusCodes.Status400BadRequest, "Invalid request"),
            DataAccessException => (StatusCodes.Status503ServiceUnavailable, "Database unavailable"),
            OperationCanceledException => (499, "Client closed request"),
            _ => (StatusCodes.Status500InternalServerError, "An unexpected error occurred"),
        };

        // DataAccessException was already logged with its stack trace by DataAccessGuard, so log it once only.
        if (status >= 500 && exception is not DataAccessException)
        {
            logger.LogError(exception, "Unhandled exception for {Method} {Path}", httpContext.Request.Method, httpContext.Request.Path);
        }
        else
        {
            logger.LogWarning("Request {Method} {Path} failed with {StatusCode}: {Message}",
                httpContext.Request.Method, httpContext.Request.Path, status, exception.Message);
        }

        httpContext.Response.StatusCode = status;

        return await problemDetailsService.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = httpContext,
            Exception = exception,
            ProblemDetails = new ProblemDetails
            {
                Status = status,
                Title = title,
                // Never leak internal error details outside Development.
                Detail = status < 500 || environment.IsDevelopment() ? exception.Message : null,
                Instance = httpContext.Request.Path,
            },
        });
    }
}
```

## Controllers/ProductsController.cs (example controller)

```csharp
using Catalog.Application.Common;
using Catalog.Application.Products;
using Catalog.Application.Products.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace Catalog.Api.Controllers;

/// <summary>
/// REST endpoints for products. Delegates all logic to <see cref="IProductService"/>.
/// </summary>
/// <param name="productService">The product application service.</param>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
public sealed class ProductsController(IProductService productService) : ControllerBase
{
    private readonly IProductService _productService = productService ?? throw new ArgumentNullException(nameof(productService));

    /// <summary>Gets a page of products.</summary>
    /// <param name="pageNumber">The 1-based page number.</param>
    /// <param name="pageSize">The page size (defaults and limits come from appsettings).</param>
    /// <param name="categoryId">An optional category filter.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The page of products.</returns>
    [HttpGet]
    [ProducesResponseType<PagedResult<ProductDto>>(StatusCodes.Status200OK)]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetPaged(
        [FromQuery] int pageNumber = 1,
        [FromQuery] int? pageSize = null,
        [FromQuery] int? categoryId = null,
        CancellationToken cancellationToken = default) =>
        Ok(await _productService.GetPagedAsync(pageNumber, pageSize, categoryId, cancellationToken));

    /// <summary>Gets a product by id.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The product.</returns>
    [HttpGet("{id:int}", Name = nameof(GetById))]
    [ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _productService.GetByIdAsync(id, cancellationToken));

    /// <summary>Creates a product.</summary>
    /// <param name="request">The product to create.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The created product with its location.</returns>
    [HttpPost]
    [ProducesResponseType<ProductDto>(StatusCodes.Status201Created)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
    public async Task<ActionResult<ProductDto>> Create([FromBody] CreateProductRequest request, CancellationToken cancellationToken)
    {
        var created = await _productService.CreateAsync(request, cancellationToken);
        return CreatedAtRoute(nameof(GetById), new { id = created.Id }, created);
    }

    /// <summary>Updates a product.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="request">The new product values.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The updated product.</returns>
    [HttpPut("{id:int}")]
    [ProducesResponseType<ProductDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ValidationProblemDetails>(StatusCodes.Status400BadRequest)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<ProductDto>> Update(int id, [FromBody] UpdateProductRequest request, CancellationToken cancellationToken) =>
        Ok(await _productService.UpdateAsync(id, request, cancellationToken));

    /// <summary>Deletes a product.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>No content.</returns>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        await _productService.DeleteAsync(id, cancellationToken);
        return NoContent();
    }
}
```

Controllers contain no try/catch, no logging of failures (the exception handler does that) and no data access.

## Skinny Controllers: No Business Code in the Presentation Layer

The Api project is a **translation layer between HTTP and application services**. It holds no business rules. Every controller must be skinny, and every other Api type (middleware, filters, attributes, helpers) must deal with HTTP concerns only.

### What a controller action may do

1. **Accept and validate input**: route/query/body binding, data-annotation validation via `[ApiController]`, and HTTP-level attributes (`[Authorize]`, rate limiting, body limits, anti-forgery).
2. **Call application services**: exactly **one** service call per action (a use case). If an action needs two or more service calls to finish its job, that orchestration is a use case and belongs in a service method.
3. **Return the HTTP response**: pick the status code (`Ok`, `CreatedAtRoute`, `NoContent`, …), and read or write purely HTTP artifacts (cookies, headers, `Location`), using values the service returned.

Anything that doesn't fit one of these three steps is business code and must move to the Application layer (or into the Domain entity when it's an invariant).

### What is forbidden in the Api project

| Forbidden in controllers / Api types | Move it to |
|---|---|
| `DbContext`, repositories, `IUnitOfWork`, `FromSql*`, `SqlConnection` | Infrastructure, behind a service |
| Domain entities in signatures, locals or `new Entity(...)` | Application service returning DTOs |
| Branching on business rules (`if (user.Status == ...)`, `switch` on domain state, permission/role decisions beyond `[Authorize]`) | Service method or domain entity |
| Calculations, aggregation or LINQ over results (`.Where`, `.Sum`, `.OrderBy`, `.GroupBy`, `.Select` that reshapes data) | Service (query in the database) |
| Loops over data (`foreach`/`for`/`while`) | Service |
| Mapping entity → DTO, or composing DTOs from several service results | Application mapping extensions / service |
| Orchestrating several services, or calling `SaveChanges` | Service method (one per use case) |
| `try`/`catch` for business outcomes, or translating exceptions to status codes | Typed exceptions + `GlobalExceptionHandler` |
| Hard-coded business values (limits, durations, role names, magic strings) | Options classes / domain constants |
| Validation beyond shape (uniqueness, existence, state checks) | Service (throws `ConflictException`/`NotFoundException`/`InvalidRequestException`) |

HTTP-only logic is allowed and expected in the Api layer, e.g. writing or clearing a session cookie from a token the service returned, reading a header, or setting `Location`. The test is: *would this logic still exist if the same use case were exposed through a CLI or a message queue?* If yes, it's business code and must not live in the Api project.

### Example: fat controller → skinny controller

Fat (rejected):

```csharp
[HttpPost("{id:guid}/suspend")]
public async Task<IActionResult> Suspend(Guid id, [FromBody] StatusRequest request, CancellationToken cancellationToken)
{
    var user = await _users.GetByIdAsync(id, cancellationToken);          // repository in a controller
    if (user is null)
    {
        return NotFound();
    }

    if (user.Roles.Any(r => r.RoleCode == RoleCodes.SystemAdministrator)) // business rule
    {
        return Conflict("The last administrator cannot be suspended.");
    }

    user.Suspend(request.Reason);                                          // domain behaviour driven from the controller
    await _unitOfWork.SaveChangesAsync(cancellationToken);                 // transaction boundary in a controller
    return Ok(user.ToDto());
}
```

Skinny (accepted):

```csharp
[HttpPost("{id:guid}/suspend")]
[ProducesResponseType<UserDto>(StatusCodes.Status200OK)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
[ProducesResponseType<ProblemDetails>(StatusCodes.Status409Conflict)]
public async Task<ActionResult<UserDto>> Suspend(Guid id, [FromBody] StatusRequest request, CancellationToken cancellationToken) =>
    Ok(await _userAdministration.SuspendAsync(id, request, cancellationToken));
```

The lookup, the last-administrator rule, the state change and `SaveChangesAsync` all live in `UserAdministrationService.SuspendAsync`, which throws `NotFoundException`/`ConflictException`. `GlobalExceptionHandler` maps those to 404/409.

### Validation procedure (run on every review and before deployment)

Check **every** file under `src/*.Api/` (controllers, `Middleware/`, `Security/`, filters, helpers), not just a sample. Run these from the solution root. Each hit must be either fixed or justified as an HTTP-only concern in the report.

1. **Data access in the Api layer**: must return nothing.
   ```bash
   grep -rnE "DbContext|Repository|IUnitOfWork|SaveChanges|FromSql|ExecuteSql|SqlConnection" src/*.Api --include=*.cs | grep -v "Program.cs"
   ```
2. **Domain types in controllers**: must return nothing. Controllers use DTOs only. Domain constants (e.g. `RoleCodes` in an `[Authorize(Roles = ...)]` attribute) are the only allowed exception.
   ```bash
   grep -rnE "using [A-Za-z.]+\.Domain" src/*.Api/Controllers --include=*.cs
   ```
3. **Branching and loops in controllers**: review every hit. Allowed only for HTTP concerns (e.g. choosing `NoContent` vs `Ok`, or whether to clear a cookie).
   ```bash
   grep -rnE "\b(if|else|switch|foreach|for|while)\b|\?\s*[^?:]+\s*:" src/*.Api/Controllers --include=*.cs
   ```
4. **LINQ / calculations in controllers**: must return nothing.
   ```bash
   grep -rnE "\.(Where|Select|SelectMany|Sum|Count|Any|All|OrderBy|OrderByDescending|GroupBy|Aggregate|First|FirstOrDefault|Single|Max|Min)\(" src/*.Api/Controllers --include=*.cs
   ```
5. **Exception handling in controllers**: must return nothing. Exceptions go through `GlobalExceptionHandler`.
   ```bash
   grep -rnE "\btry\b|\bcatch\b" src/*.Api/Controllers --include=*.cs
   ```
6. **One service call per action**: for each action, count awaited service calls. More than one means the orchestration belongs in a service.
7. **Action size**: an action body (excluding attributes and XML docs) longer than ~10 lines is a smell. Anything that isn't bind → one service call → return must be justified.
8. **Injected dependencies**: controller constructors may take only application service interfaces (`I*Service`) and presentation helpers (e.g. cookie writers, `IRequestContext`). Any other dependency needs a justification.
9. **Non-controller Api types** (middleware, filters, attributes): they may inspect and shape the HTTP request/response (headers, cookies, body limits, CSRF, rate limits, exception → ProblemDetails). They must not make business decisions. Authorization decisions delegate to an Application-layer resolver/policy (e.g. `IActorResolver`, `AccessPolicies`) rather than re-implementing the rules.

### Reporting

Finish the review with this block. List every controller, with ✅ (skinny), ❌ (violation, with `file:line`, the rule broken and the target service method) or ⚠️ (HTTP-only logic kept on purpose, with the reason):

```
Skinny controller check
- ✅ ProductsController
- ❌ OrdersController.Cancel: refund calculation in controller (src/Catalog.Api/Controllers/OrdersController.cs:58) → move to IOrderService.CancelAsync
- ⚠️ AuthController.Login: writes session cookie from LoginResult (HTTP-only concern)
- ✅ Middleware/Security: no business rules
```

Never tick a controller from memory. Open each file and run the checks above.

## appsettings.json (all configuration lives here)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=CatalogDb;Trusted_Connection=True;TrustServerCertificate=True;MultipleActiveResultSets=true;Pooling=True;Min Pool Size=5;Max Pool Size=100;Connect Timeout=30",
    "ReadOnlyConnection": "Server=localhost;Database=CatalogDb;Trusted_Connection=True;TrustServerCertificate=True;ApplicationIntent=ReadOnly;Pooling=True;Min Pool Size=5;Max Pool Size=100;Connect Timeout=30"
  },
  "Database": {
    "CommandTimeoutSeconds": 30,
    "MaxRetryCount": 5,
    "MaxRetryDelaySeconds": 10,
    "EnableSensitiveDataLogging": false,
    "EnableDetailedErrors": false,
    "ApplyMigrationsOnStartup": false,
    "DbContextPoolSize": 128
  },
  "Pagination": {
    "DefaultPageSize": 20,
    "MaxPageSize": 100
  },
  "Serilog": {
    "Using": [ "Serilog.Sinks.Console", "Serilog.Sinks.File", "Serilog.Expressions" ],
    "MinimumLevel": {
      "Default": "Information",
      "Override": {
        "Microsoft": "Warning",
        "Microsoft.AspNetCore": "Warning",
        "Microsoft.Hosting.Lifetime": "Information",
        "Microsoft.EntityFrameworkCore.Database.Command": "Information",
        "System": "Warning"
      }
    },
    "WriteTo": [
      {
        "Name": "Console",
        "Args": {
          "outputTemplate": "[{Timestamp:HH:mm:ss} {Level:u3}] {SourceContext}: {Message:lj}{NewLine}{Exception}"
        }
      },
      {
        "Name": "File",
        "Args": {
          "path": "logs/catalog-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 14,
          "fileSizeLimitBytes": 104857600,
          "rollOnFileSizeLimit": true,
          "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] [{MachineName}/{ThreadId}] {SourceContext} {RequestId} {Message:lj}{NewLine}{Exception}"
        }
      },
      {
        "Name": "Logger",
        "Args": {
          "configureLogger": {
            "Filter": [
              { "Name": "ByIncludingOnly", "Args": { "expression": "SourceContext = 'Audit'" } }
            ],
            "WriteTo": [
              {
                "Name": "File",
                "Args": {
                  "path": "logs/audit-.log",
                  "rollingInterval": "Day",
                  "retainedFileCountLimit": 90,
                  "outputTemplate": "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {RequestId} {Message:lj}{NewLine}"
                }
              }
            ]
          }
        }
      }
    ],
    "Enrich": [ "FromLogContext", "WithMachineName", "WithThreadId" ],
    "Properties": {
      "Application": "Catalog.Api"
    }
  },
  "AllowedHosts": "*"
}
```

## appsettings.Development.json (full logs)

```json
{
  "Database": {
    "EnableSensitiveDataLogging": true,
    "EnableDetailedErrors": true,
    "ApplyMigrationsOnStartup": true
  },
  "Serilog": {
    "MinimumLevel": {
      "Default": "Debug",
      "Override": {
        "Microsoft": "Information",
        "Microsoft.AspNetCore": "Information",
        "Microsoft.EntityFrameworkCore": "Information",
        "Microsoft.EntityFrameworkCore.Database.Command": "Information",
        "Microsoft.EntityFrameworkCore.ChangeTracking": "Debug",
        "System": "Information"
      }
    }
  }
}
```

With this configuration, Development logs contain:
- every HTTP request (`UseSerilogRequestLogging`), with method, path, status code and elapsed time
- every SQL statement EF Core executes, with parameter values (`EnableSensitiveDataLogging`) and duration
- change-tracking detail, migrations applied at startup, and application `Debug` logs from services
- unhandled exceptions with full stack traces (Console + rolling file in `logs/`)

Production keeps SQL command logging at `Information`, but without parameter values.

Audit records (the `Audit` source context from `IAuditLogger`) also go to `logs/audit-*.log`, kept for 90 days. They record who accessed which resource, with what criteria, how many rows came back and how long it took.

Override secrets per environment without changing code, using the same keys:
- `dotnet user-secrets set "ConnectionStrings:DefaultConnection" "..."` (local)
- the `ConnectionStrings__DefaultConnection` environment variable (containers/CI)
