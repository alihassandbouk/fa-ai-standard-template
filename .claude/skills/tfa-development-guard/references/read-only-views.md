# Read-Only Data Access (SQL Server Views)

Use this pattern when the application **reads** from database views (reporting, integration or legacy databases) and must never write to them. It lives next to the read/write `AppDbContext`. A read-only-only application simply omits `AppDbContext`.

Guarantees (these map to the [pre-deployment checklist](../SKILL.md#pre-deployment-checklist)):
- Every view is mapped in `OnModelCreating` through an `IEntityTypeConfiguration<T>` with `ToView(...)`.
- `SaveChanges`/`SaveChangesAsync` **throw**, and change tracking is disabled.
- Repositories expose query methods only, and every method translates database failures into `DataAccessException`.
- Services write an **audit log** entry for every data access, whether it succeeds or fails.
- Queries are LINQ (always parameterized), use a pooled `DbContext` plus ADO.NET connection pooling, and have a 30-second timeout.

```
Domain/
  Common/IReadOnlyRepository.cs
  Reporting/ProductSalesSummary.cs              # read model (view row)
  Reporting/IProductSalesSummaryRepository.cs
Application/
  Common/ICurrentUser.cs
  Common/Auditing/IAuditLogger.cs
  Common/Exceptions/DataAccessException.cs
  Reporting/Dtos/ProductSalesSummaryDto.cs
  Reporting/IProductSalesReportService.cs
  Reporting/ProductSalesReportService.cs
Infrastructure/
  Auditing/AuditLogger.cs
  Persistence/DataAccessGuard.cs
  Persistence/ReadOnly/ReadOnlyDbContext.cs
  Persistence/ReadOnly/Configurations/ProductSalesSummaryConfiguration.cs
  Persistence/ReadOnly/Repositories/ReadOnlyRepository.cs
  Persistence/ReadOnly/Repositories/ProductSalesSummaryRepository.cs
Api/
  Services/HttpCurrentUser.cs
  Controllers/ReportsController.cs
```

## Domain

```csharp
using System.Linq.Expressions;

namespace Catalog.Domain.Common;

/// <summary>
/// Query-only repository contract for read models backed by database views.
/// Exposes no add, update or remove operations.
/// </summary>
/// <typeparam name="TReadModel">The read model type.</typeparam>
public interface IReadOnlyRepository<TReadModel> where TReadModel : class
{
    /// <summary>Finds read models matching a predicate.</summary>
    /// <param name="predicate">The filter expression (translated to parameterized SQL).</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The matching rows.</returns>
    Task<IReadOnlyList<TReadModel>> FindAsync(Expression<Func<TReadModel, bool>> predicate, CancellationToken cancellationToken = default);

    /// <summary>Gets the first read model matching a predicate.</summary>
    /// <param name="predicate">The filter expression.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The row, or <c>null</c> when none matches.</returns>
    Task<TReadModel?> FirstOrDefaultAsync(Expression<Func<TReadModel, bool>> predicate, CancellationToken cancellationToken = default);

    /// <summary>Counts read models, optionally filtered.</summary>
    /// <param name="predicate">An optional filter expression.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The number of matching rows.</returns>
    Task<int> CountAsync(Expression<Func<TReadModel, bool>>? predicate = null, CancellationToken cancellationToken = default);

    /// <summary>Gets a page of read models ordered by a key.</summary>
    /// <typeparam name="TKey">The ordering key type.</typeparam>
    /// <param name="predicate">An optional filter expression.</param>
    /// <param name="orderBy">The ordering key selector (required for stable paging).</param>
    /// <param name="pageNumber">The 1-based page number.</param>
    /// <param name="pageSize">The page size.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The page items and total count.</returns>
    Task<(IReadOnlyList<TReadModel> Items, int TotalCount)> GetPagedAsync<TKey>(
        Expression<Func<TReadModel, bool>>? predicate,
        Expression<Func<TReadModel, TKey>> orderBy,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default);
}
```

```csharp
namespace Catalog.Domain.Reporting;

/// <summary>
/// A row of the <c>dbo.vw_ProductSalesSummary</c> view. Read-only; never persisted by the application.
/// </summary>
public sealed class ProductSalesSummary
{
    /// <summary>Required by EF Core.</summary>
    private ProductSalesSummary()
    {
    }

    /// <summary>Gets the product id.</summary>
    public int ProductId { get; private set; }

    /// <summary>Gets the product name.</summary>
    public string ProductName { get; private set; } = string.Empty;

    /// <summary>Gets the SKU.</summary>
    public string Sku { get; private set; } = string.Empty;

    /// <summary>Gets the category name.</summary>
    public string CategoryName { get; private set; } = string.Empty;

    /// <summary>Gets the total quantity sold.</summary>
    public int TotalQuantitySold { get; private set; }

    /// <summary>Gets the total revenue.</summary>
    public decimal TotalRevenue { get; private set; }

    /// <summary>Gets the UTC timestamp of the last sale, if any.</summary>
    public DateTime? LastSoldAtUtc { get; private set; }
}
```

```csharp
using Catalog.Domain.Common;

namespace Catalog.Domain.Reporting;

/// <summary>
/// Queries over the product sales summary view.
/// </summary>
public interface IProductSalesSummaryRepository : IReadOnlyRepository<ProductSalesSummary>
{
    /// <summary>Gets the summary for one product.</summary>
    /// <param name="productId">The product id.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The summary, or <c>null</c> when not found.</returns>
    Task<ProductSalesSummary?> GetByProductIdAsync(int productId, CancellationToken cancellationToken = default);

    /// <summary>Gets the best-selling products by revenue.</summary>
    /// <param name="top">The number of rows to return.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The top sellers, highest revenue first.</returns>
    Task<IReadOnlyList<ProductSalesSummary>> GetTopSellersAsync(int top, CancellationToken cancellationToken = default);
}
```

## Application

```csharp
namespace Catalog.Application.Common;

/// <summary>Provides the identity of the caller for auditing.</summary>
public interface ICurrentUser
{
    /// <summary>Gets the caller's user name, or <c>"anonymous"</c>.</summary>
    string UserName { get; }
}
```

```csharp
namespace Catalog.Application.Common.Auditing;

/// <summary>
/// Writes audit records for data access. Records go to the dedicated "Audit" log sink.
/// </summary>
public interface IAuditLogger
{
    /// <summary>Records a successful data access.</summary>
    /// <param name="operation">The use case name.</param>
    /// <param name="resource">The accessed resource (view or entity name).</param>
    /// <param name="criteria">The query criteria (logged as structured data; never include secrets).</param>
    /// <param name="resultCount">The number of rows returned.</param>
    /// <param name="elapsed">The elapsed time.</param>
    void LogAccess(string operation, string resource, object? criteria, int resultCount, TimeSpan elapsed);

    /// <summary>Records a failed data access.</summary>
    /// <param name="operation">The use case name.</param>
    /// <param name="resource">The accessed resource.</param>
    /// <param name="criteria">The query criteria.</param>
    /// <param name="exception">The failure.</param>
    /// <param name="elapsed">The elapsed time.</param>
    void LogFailure(string operation, string resource, object? criteria, Exception exception, TimeSpan elapsed);
}
```

```csharp
namespace Catalog.Application.Common.Exceptions;

/// <summary>
/// Thrown by repositories when the database cannot be reached or a query fails.
/// Mapped to HTTP 503 by the global exception handler.
/// </summary>
/// <param name="message">A safe, non-sensitive description.</param>
/// <param name="innerException">The underlying provider exception.</param>
public sealed class DataAccessException(string message, Exception innerException) : Exception(message, innerException);
```

```csharp
namespace Catalog.Application.Reporting.Dtos;

/// <summary>Product sales summary returned to clients.</summary>
public sealed record ProductSalesSummaryDto(
    int ProductId,
    string ProductName,
    string Sku,
    string CategoryName,
    int TotalQuantitySold,
    decimal TotalRevenue,
    DateTime? LastSoldAtUtc);
```

```csharp
using Catalog.Application.Reporting.Dtos;

namespace Catalog.Application.Reporting;

/// <summary>Read-only product sales reporting use cases.</summary>
public interface IProductSalesReportService
{
    /// <summary>Gets the sales summary for one product.</summary>
    /// <param name="productId">The product id (must be positive).</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The summary.</returns>
    /// <exception cref="ArgumentOutOfRangeException">Thrown when <paramref name="productId"/> is not positive.</exception>
    /// <exception cref="Common.Exceptions.NotFoundException">Thrown when no summary exists.</exception>
    /// <exception cref="Common.Exceptions.DataAccessException">Thrown when the database query fails.</exception>
    Task<ProductSalesSummaryDto> GetByProductIdAsync(int productId, CancellationToken cancellationToken = default);

    /// <summary>Gets the best-selling products.</summary>
    /// <param name="top">The number of rows requested (clamped to the configured maximum).</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The top sellers.</returns>
    /// <exception cref="Common.Exceptions.DataAccessException">Thrown when the database query fails.</exception>
    Task<IReadOnlyList<ProductSalesSummaryDto>> GetTopSellersAsync(int top, CancellationToken cancellationToken = default);
}
```

```csharp
using System.Diagnostics;
using Catalog.Application.Common;
using Catalog.Application.Common.Auditing;
using Catalog.Application.Common.Exceptions;
using Catalog.Application.Reporting.Dtos;
using Catalog.Domain.Reporting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Catalog.Application.Reporting;

/// <summary>
/// Implements read-only reporting use cases with input validation, auditing and error handling in every method.
/// </summary>
/// <param name="repository">The view repository.</param>
/// <param name="auditLogger">The audit logger.</param>
/// <param name="paginationOptions">Paging limits from configuration.</param>
/// <param name="logger">The logger.</param>
public sealed class ProductSalesReportService(
    IProductSalesSummaryRepository repository,
    IAuditLogger auditLogger,
    IOptions<PaginationOptions> paginationOptions,
    ILogger<ProductSalesReportService> logger) : IProductSalesReportService
{
    private const string Resource = "vw_ProductSalesSummary";

    private readonly IProductSalesSummaryRepository _repository = repository ?? throw new ArgumentNullException(nameof(repository));
    private readonly IAuditLogger _auditLogger = auditLogger ?? throw new ArgumentNullException(nameof(auditLogger));
    private readonly PaginationOptions _pagination = paginationOptions?.Value ?? throw new ArgumentNullException(nameof(paginationOptions));
    private readonly ILogger<ProductSalesReportService> _logger = logger ?? throw new ArgumentNullException(nameof(logger));

    /// <inheritdoc />
    public async Task<ProductSalesSummaryDto> GetByProductIdAsync(int productId, CancellationToken cancellationToken = default)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(productId);

        var summary = await AuditedAsync(
            nameof(GetByProductIdAsync),
            new { ProductId = productId },
            () => _repository.GetByProductIdAsync(productId, cancellationToken),
            result => result is null ? 0 : 1).ConfigureAwait(false);

        if (summary is null)
        {
            _logger.LogWarning("Sales summary for product {ProductId} not found", productId);
            throw new NotFoundException(nameof(ProductSalesSummary), productId);
        }

        return ToDto(summary);
    }

    /// <inheritdoc />
    public async Task<IReadOnlyList<ProductSalesSummaryDto>> GetTopSellersAsync(int top, CancellationToken cancellationToken = default)
    {
        var size = Math.Clamp(top, 1, _pagination.MaxPageSize);

        var items = await AuditedAsync(
            nameof(GetTopSellersAsync),
            new { Top = size },
            () => _repository.GetTopSellersAsync(size, cancellationToken),
            result => result.Count).ConfigureAwait(false);

        return items.Select(ToDto).ToList();
    }

    /// <summary>
    /// Runs a query, audits success or failure with timing, and rethrows failures for the global handler.
    /// </summary>
    private async Task<T> AuditedAsync<T>(string operation, object criteria, Func<Task<T>> query, Func<T, int> count)
    {
        var start = Stopwatch.GetTimestamp();
        try
        {
            var result = await query().ConfigureAwait(false);
            _auditLogger.LogAccess(operation, Resource, criteria, count(result), Stopwatch.GetElapsedTime(start));
            return result;
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _auditLogger.LogFailure(operation, Resource, criteria, ex, Stopwatch.GetElapsedTime(start));
            throw;
        }
    }

    private static ProductSalesSummaryDto ToDto(ProductSalesSummary s) =>
        new(s.ProductId, s.ProductName, s.Sku, s.CategoryName, s.TotalQuantitySold, s.TotalRevenue, s.LastSoldAtUtc);
}
```

Register it in `AddApplication`: `services.AddScoped<IProductSalesReportService, ProductSalesReportService>();`

## Infrastructure

### Persistence/DataAccessGuard.cs (error handling shared by all repositories)

```csharp
using System.Data.Common;
using Catalog.Application.Common.Exceptions;
using Microsoft.EntityFrameworkCore.Storage;
using Microsoft.Extensions.Logging;

namespace Catalog.Infrastructure.Persistence;

/// <summary>
/// Wraps repository database calls: logs provider failures with context and rethrows them as <see cref="DataAccessException"/>.
/// </summary>
internal static class DataAccessGuard
{
    /// <summary>Executes a database operation with consistent error handling.</summary>
    /// <typeparam name="T">The result type.</typeparam>
    /// <param name="operation">The database call.</param>
    /// <param name="logger">The repository logger.</param>
    /// <param name="resource">The entity or view name.</param>
    /// <param name="operationName">The repository method name.</param>
    /// <returns>The operation result.</returns>
    /// <exception cref="DataAccessException">Thrown when the provider fails, times out or exhausts retries.</exception>
    public static async Task<T> ExecuteAsync<T>(Func<Task<T>> operation, ILogger logger, string resource, string operationName)
    {
        try
        {
            return await operation().ConfigureAwait(false);
        }
        catch (Exception ex) when (ex is DbException or TimeoutException or RetryLimitExceededException)
        {
            logger.LogError(ex, "Database failure in {Operation} on {Resource}", operationName, resource);
            throw new DataAccessException($"A database error occurred while executing {operationName} on {resource}.", ex);
        }
    }
}
```

### Persistence/ReadOnly/ReadOnlyDbContext.cs (SaveChanges blocked)

```csharp
using Catalog.Domain.Reporting;
using Catalog.Infrastructure.Persistence.ReadOnly.Configurations;
using Microsoft.EntityFrameworkCore;

namespace Catalog.Infrastructure.Persistence.ReadOnly;

/// <summary>
/// Read-only EF Core context over SQL Server views. Any attempt to save changes throws.
/// </summary>
/// <param name="options">The context options configured in DI.</param>
public sealed class ReadOnlyDbContext(DbContextOptions<ReadOnlyDbContext> options) : DbContext(options)
{
    private const string ReadOnlyMessage = "ReadOnlyDbContext is read-only. SaveChanges is not permitted.";

    /// <summary>Gets the product sales summary view.</summary>
    public DbSet<ProductSalesSummary> ProductSalesSummaries => Set<ProductSalesSummary>();

    /// <inheritdoc />
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Map ALL views: applies only the configurations in the ReadOnly.Configurations namespace.
        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(ReadOnlyDbContext).Assembly,
            type => type.Namespace == typeof(ProductSalesSummaryConfiguration).Namespace);

        base.OnModelCreating(modelBuilder);
    }

    // SaveChanges() and SaveChangesAsync(CancellationToken) delegate to these overloads, so all four are blocked.

    /// <inheritdoc />
    /// <exception cref="InvalidOperationException">Always thrown; this context is read-only.</exception>
    public override int SaveChanges(bool acceptAllChangesOnSuccess) =>
        throw new InvalidOperationException(ReadOnlyMessage);

    /// <inheritdoc />
    /// <exception cref="InvalidOperationException">Always thrown; this context is read-only.</exception>
    public override Task<int> SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken cancellationToken = default) =>
        throw new InvalidOperationException(ReadOnlyMessage);
}
```

> Defence in depth: the SQL login used by `ReadOnlyConnection` must have only `db_datareader` (or `SELECT` on the views). If the source is an Always On secondary replica, add `ApplicationIntent=ReadOnly` to the connection string.

### Persistence/ReadOnly/Configurations/ProductSalesSummaryConfiguration.cs (view mapping)

```csharp
using Catalog.Domain.Reporting;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Catalog.Infrastructure.Persistence.ReadOnly.Configurations;

/// <summary>
/// Maps <see cref="ProductSalesSummary"/> to <c>dbo.vw_ProductSalesSummary</c>.
/// </summary>
public sealed class ProductSalesSummaryConfiguration : IEntityTypeConfiguration<ProductSalesSummary>
{
    /// <inheritdoc />
    public void Configure(EntityTypeBuilder<ProductSalesSummary> builder)
    {
        builder.ToView("vw_ProductSalesSummary", "dbo");
        builder.HasNoKey(); // Use HasKey(v => v.ProductId) instead if the view guarantees uniqueness.

        builder.Property(v => v.ProductId).HasColumnName("ProductId");
        builder.Property(v => v.ProductName).HasColumnName("ProductName").HasMaxLength(200);
        builder.Property(v => v.Sku).HasColumnName("Sku").HasMaxLength(50);
        builder.Property(v => v.CategoryName).HasColumnName("CategoryName").HasMaxLength(100);
        builder.Property(v => v.TotalQuantitySold).HasColumnName("TotalQuantitySold");
        builder.Property(v => v.TotalRevenue).HasColumnName("TotalRevenue").HasPrecision(18, 2);
        builder.Property(v => v.LastSoldAtUtc).HasColumnName("LastSoldAtUtc");
    }
}
```

Rules for view mappings:
- There is one configuration per view, and every view used by the app has one. Map columns explicitly with `HasColumnName` so a renamed column fails loudly.
- EF migrations **never** create or alter views mapped with `ToView`. If the app owns the view, create it in an `AppDbContext` migration with `migrationBuilder.Sql("CREATE OR ALTER VIEW ...")` and a matching `Down`.
- `AppDbContext` must only apply its own configurations: `ApplyConfigurationsFromAssembly(assembly, t => t.Namespace == typeof(ProductConfiguration).Namespace)`.

### Persistence/ReadOnly/Repositories/ReadOnlyRepository.cs

```csharp
using System.Linq.Expressions;
using Catalog.Domain.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Catalog.Infrastructure.Persistence.ReadOnly.Repositories;

/// <summary>
/// Base implementation of <see cref="IReadOnlyRepository{TReadModel}"/>. Every method is untracked and error-guarded.
/// </summary>
/// <typeparam name="TReadModel">The read model type.</typeparam>
/// <param name="context">The read-only context.</param>
/// <param name="loggerFactory">The logger factory.</param>
public abstract class ReadOnlyRepository<TReadModel>(ReadOnlyDbContext context, ILoggerFactory loggerFactory)
    : IReadOnlyRepository<TReadModel>
    where TReadModel : class
{
    private readonly ReadOnlyDbContext _context = context ?? throw new ArgumentNullException(nameof(context));

    /// <summary>Gets the logger for the concrete repository.</summary>
    protected ILogger Logger { get; } = (loggerFactory ?? throw new ArgumentNullException(nameof(loggerFactory))).CreateLogger(typeof(TReadModel).Name + "Repository");

    /// <summary>Gets an untracked query over the view.</summary>
    protected IQueryable<TReadModel> Query => _context.Set<TReadModel>().AsNoTracking();

    /// <inheritdoc />
    public virtual Task<IReadOnlyList<TReadModel>> FindAsync(Expression<Func<TReadModel, bool>> predicate, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(predicate);
        return ExecuteAsync<IReadOnlyList<TReadModel>>(
            async () => await Query.Where(predicate).ToListAsync(cancellationToken).ConfigureAwait(false),
            nameof(FindAsync));
    }

    /// <inheritdoc />
    public virtual Task<TReadModel?> FirstOrDefaultAsync(Expression<Func<TReadModel, bool>> predicate, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(predicate);
        return ExecuteAsync(() => Query.FirstOrDefaultAsync(predicate, cancellationToken), nameof(FirstOrDefaultAsync));
    }

    /// <inheritdoc />
    public virtual Task<int> CountAsync(Expression<Func<TReadModel, bool>>? predicate = null, CancellationToken cancellationToken = default) =>
        ExecuteAsync(
            () => predicate is null ? Query.CountAsync(cancellationToken) : Query.CountAsync(predicate, cancellationToken),
            nameof(CountAsync));

    /// <inheritdoc />
    public virtual Task<(IReadOnlyList<TReadModel> Items, int TotalCount)> GetPagedAsync<TKey>(
        Expression<Func<TReadModel, bool>>? predicate,
        Expression<Func<TReadModel, TKey>> orderBy,
        int pageNumber,
        int pageSize,
        CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(orderBy);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(pageNumber);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(pageSize);

        return ExecuteAsync<(IReadOnlyList<TReadModel>, int)>(async () =>
        {
            var query = predicate is null ? Query : Query.Where(predicate);
            var total = await query.CountAsync(cancellationToken).ConfigureAwait(false);
            var items = await query.OrderBy(orderBy)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false);
            return (items, total);
        }, nameof(GetPagedAsync));
    }

    /// <summary>Runs a database call through <see cref="DataAccessGuard"/>.</summary>
    /// <typeparam name="T">The result type.</typeparam>
    /// <param name="operation">The database call.</param>
    /// <param name="operationName">The calling method name.</param>
    /// <returns>The result.</returns>
    protected Task<T> ExecuteAsync<T>(Func<Task<T>> operation, string operationName) =>
        DataAccessGuard.ExecuteAsync(operation, Logger, typeof(TReadModel).Name, operationName);
}
```

### Persistence/ReadOnly/Repositories/ProductSalesSummaryRepository.cs

```csharp
using Catalog.Domain.Reporting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace Catalog.Infrastructure.Persistence.ReadOnly.Repositories;

/// <summary>
/// EF Core implementation of <see cref="IProductSalesSummaryRepository"/>.
/// </summary>
/// <param name="context">The read-only context.</param>
/// <param name="loggerFactory">The logger factory.</param>
public sealed class ProductSalesSummaryRepository(ReadOnlyDbContext context, ILoggerFactory loggerFactory)
    : ReadOnlyRepository<ProductSalesSummary>(context, loggerFactory), IProductSalesSummaryRepository
{
    /// <inheritdoc />
    public Task<ProductSalesSummary?> GetByProductIdAsync(int productId, CancellationToken cancellationToken = default) =>
        ExecuteAsync(
            () => Query.FirstOrDefaultAsync(v => v.ProductId == productId, cancellationToken), // parameterized: @__productId_0
            nameof(GetByProductIdAsync));

    /// <inheritdoc />
    public Task<IReadOnlyList<ProductSalesSummary>> GetTopSellersAsync(int top, CancellationToken cancellationToken = default)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(top);
        return ExecuteAsync<IReadOnlyList<ProductSalesSummary>>(
            async () => await Query
                .OrderByDescending(v => v.TotalRevenue)
                .ThenBy(v => v.ProductId)
                .Take(top)
                .ToListAsync(cancellationToken)
                .ConfigureAwait(false),
            nameof(GetTopSellersAsync));
    }
}
```

If raw SQL is ever needed, use only the interpolated, parameterized APIs: `Query.FromSql($"SELECT * FROM dbo.vw_ProductSalesSummary WHERE CategoryName = {category}")`. **Never** use `FromSqlRaw` or `ExecuteSqlRaw` with concatenated or interpolated user input.

### Auditing/AuditLogger.cs

```csharp
using Catalog.Application.Common;
using Catalog.Application.Common.Auditing;
using Microsoft.Extensions.Logging;

namespace Catalog.Infrastructure.Auditing;

/// <summary>
/// Writes structured audit records under the <c>Audit</c> source context (routed to logs/audit-*.log).
/// </summary>
/// <param name="currentUser">The caller identity.</param>
/// <param name="loggerFactory">The logger factory.</param>
public sealed class AuditLogger(ICurrentUser currentUser, ILoggerFactory loggerFactory) : IAuditLogger
{
    /// <summary>The source context used to route audit records to their own sink.</summary>
    public const string Category = "Audit";

    private readonly ICurrentUser _currentUser = currentUser ?? throw new ArgumentNullException(nameof(currentUser));
    private readonly ILogger _logger = (loggerFactory ?? throw new ArgumentNullException(nameof(loggerFactory))).CreateLogger(Category);

    /// <inheritdoc />
    public void LogAccess(string operation, string resource, object? criteria, int resultCount, TimeSpan elapsed) =>
        _logger.LogInformation(
            "AUDIT {Outcome} {Operation} on {Resource} by {User} with {@Criteria} returned {ResultCount} rows in {ElapsedMs:0.0} ms",
            "Success", operation, resource, _currentUser.UserName, criteria, resultCount, elapsed.TotalMilliseconds);

    /// <inheritdoc />
    public void LogFailure(string operation, string resource, object? criteria, Exception exception, TimeSpan elapsed) =>
        _logger.LogWarning(
            "AUDIT {Outcome} {Operation} on {Resource} by {User} with {@Criteria} failed after {ElapsedMs:0.0} ms: {ErrorType}",
            "Failure", operation, resource, _currentUser.UserName, criteria, elapsed.TotalMilliseconds, exception.GetType().Name);
}
```

### DI registration: add to `AddInfrastructure`

```csharp
var readOnlyConnectionString = configuration.GetConnectionString("ReadOnlyConnection")
    ?? throw new InvalidOperationException("Connection string 'ReadOnlyConnection' is not configured.");

services.AddDbContextPool<ReadOnlyDbContext>((serviceProvider, options) =>
{
    var db = serviceProvider.GetRequiredService<IOptions<DatabaseOptions>>().Value;

    options.UseSqlServer(readOnlyConnectionString, sql =>
    {
        sql.CommandTimeout(db.CommandTimeoutSeconds);          // 30 s from appsettings
        sql.EnableRetryOnFailure(db.MaxRetryCount, TimeSpan.FromSeconds(db.MaxRetryDelaySeconds), errorNumbersToAdd: null);
    });

    options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
    options.EnableDetailedErrors(db.EnableDetailedErrors);
    options.EnableSensitiveDataLogging(db.EnableSensitiveDataLogging);
}, poolSize: dbPoolSize);

services.AddScoped<IAuditLogger, AuditLogger>();
services.AddScoped<IProductSalesSummaryRepository, ProductSalesSummaryRepository>();
```

`dbPoolSize` is read once from configuration in `AddInfrastructure` (see infrastructure-layer.md). With two contexts in one assembly, EF commands need `--context AppDbContext`. `ReadOnlyDbContext` never has migrations.

## Api

```csharp
using Catalog.Application.Common;

namespace Catalog.Api.Services;

/// <summary>Resolves the caller from the current HTTP request.</summary>
/// <param name="httpContextAccessor">The HTTP context accessor.</param>
public sealed class HttpCurrentUser(IHttpContextAccessor httpContextAccessor) : ICurrentUser
{
    private readonly IHttpContextAccessor _accessor = httpContextAccessor ?? throw new ArgumentNullException(nameof(httpContextAccessor));

    /// <inheritdoc />
    public string UserName => _accessor.HttpContext?.User.Identity?.Name ?? "anonymous";
}
```

Register it in `Program.cs`: `builder.Services.AddHttpContextAccessor(); builder.Services.AddScoped<ICurrentUser, HttpCurrentUser>();`

```csharp
using Catalog.Application.Reporting;
using Catalog.Application.Reporting.Dtos;
using Microsoft.AspNetCore.Mvc;

namespace Catalog.Api.Controllers;

/// <summary>Read-only reporting endpoints backed by database views.</summary>
/// <param name="reportService">The reporting service.</param>
[ApiController]
[Route("api/reports")]
[Produces("application/json")]
public sealed class ReportsController(IProductSalesReportService reportService) : ControllerBase
{
    private readonly IProductSalesReportService _reportService = reportService ?? throw new ArgumentNullException(nameof(reportService));

    /// <summary>Gets the best-selling products.</summary>
    /// <param name="top">The number of rows (clamped to Pagination:MaxPageSize).</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The top sellers.</returns>
    [HttpGet("product-sales/top")]
    [ProducesResponseType<IReadOnlyList<ProductSalesSummaryDto>>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<IReadOnlyList<ProductSalesSummaryDto>>> GetTopSellers([FromQuery] int top = 10, CancellationToken cancellationToken = default) =>
        Ok(await _reportService.GetTopSellersAsync(top, cancellationToken));

    /// <summary>Gets the sales summary for one product.</summary>
    /// <param name="productId">The product id.</param>
    /// <param name="cancellationToken">The request cancellation token.</param>
    /// <returns>The summary.</returns>
    [HttpGet("product-sales/{productId:int}")]
    [ProducesResponseType<ProductSalesSummaryDto>(StatusCodes.Status200OK)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status404NotFound)]
    [ProducesResponseType<ProblemDetails>(StatusCodes.Status503ServiceUnavailable)]
    public async Task<ActionResult<ProductSalesSummaryDto>> GetByProductId(int productId, CancellationToken cancellationToken) =>
        Ok(await _reportService.GetByProductIdAsync(productId, cancellationToken));
}
```

The controller has no write endpoints. POST, PUT and DELETE must never be exposed for view-backed resources.

## Tests that prove the read-only guarantees

```csharp
[TestMethod]
public async Task SaveChangesAsync_OnReadOnlyContext_Throws()
{
    await using var context = CreateReadOnlyContext(); // real SQL Server (Testcontainers) or any provider
    var act = () => context.SaveChangesAsync();
    await act.Should().ThrowAsync<InvalidOperationException>().WithMessage("*read-only*");
}

[TestMethod]
public async Task AllViews_AreQueryable()
{
    // Proves every mapped view exists and its columns match the mapping.
    await using var context = CreateReadOnlyContext();
    foreach (var entityType in context.Model.GetEntityTypes())
    {
        entityType.GetViewName().Should().NotBeNull($"{entityType.ClrType.Name} must be mapped with ToView");
    }

    await context.ProductSalesSummaries.Take(1).ToListAsync();
}
```
