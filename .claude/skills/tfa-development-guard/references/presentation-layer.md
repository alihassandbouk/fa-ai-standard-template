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
