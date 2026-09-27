# Application Layer (Services, DTOs)

Project: `{Solution}.Application`. It references Domain only. 

NuGet packages:
- `Microsoft.Extensions.Logging.Abstractions`
- `Microsoft.Extensions.DependencyInjection.Abstractions`
- `Microsoft.Extensions.Options.ConfigurationExtensions`
- `Microsoft.Extensions.Options.DataAnnotations`

```
{Solution}.Application/
  DependencyInjection.cs
  Common/
    PagedResult.cs
    PaginationOptions.cs
    Exceptions/
      NotFoundException.cs
      ConflictException.cs
      DataAccessException.cs   # thrown by repositories on DB failure (see read-only-views.md)
  Products/
    IProductService.cs
    ProductService.cs
    ProductMappings.cs
    Dtos/
      ProductDto.cs
      CreateProductRequest.cs
      UpdateProductRequest.cs
```

## Common

```csharp
namespace Catalog.Application.Common;

/// <summary>
/// A page of results with paging metadata.
/// </summary>
/// <typeparam name="T">The item type.</typeparam>
/// <param name="Items">The items on this page.</param>
/// <param name="PageNumber">The 1-based page number.</param>
/// <param name="PageSize">The page size.</param>
/// <param name="TotalCount">The total number of matching items.</param>
public sealed record PagedResult<T>(IReadOnlyList<T> Items, int PageNumber, int PageSize, int TotalCount)
{
    /// <summary>Gets the total number of pages.</summary>
    public int TotalPages => PageSize == 0 ? 0 : (int)Math.Ceiling(TotalCount / (double)PageSize);
}
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace Catalog.Application.Common;

/// <summary>
/// Paging limits bound from the <c>Pagination</c> section of appsettings.
/// </summary>
public sealed class PaginationOptions
{
    /// <summary>The configuration section name.</summary>
    public const string SectionName = "Pagination";

    /// <summary>Gets the page size used when none is requested.</summary>
    [Range(1, 1000)]
    public int DefaultPageSize { get; init; } = 20;

    /// <summary>Gets the maximum page size a client may request.</summary>
    [Range(1, 1000)]
    public int MaxPageSize { get; init; } = 100;
}
```

```csharp
namespace Catalog.Application.Common.Exceptions;

/// <summary>Thrown when a requested resource does not exist.</summary>
/// <param name="resource">The resource type name.</param>
/// <param name="key">The key that was looked up.</param>
public sealed class NotFoundException(string resource, object key)
    : Exception($"{resource} with key '{key}' was not found.");

/// <summary>Thrown when an operation conflicts with the current state (e.g. duplicate key).</summary>
/// <param name="message">A description of the conflict.</param>
public sealed class ConflictException(string message) : Exception(message);
```

(Put each exception in its own file in real code.)

## DTOs

```csharp
namespace Catalog.Application.Products.Dtos;

/// <summary>
/// Product data returned to clients.
/// </summary>
public sealed record ProductDto(
    int Id,
    string Name,
    string Sku,
    string? Description,
    decimal Price,
    int StockQuantity,
    bool IsActive,
    int CategoryId,
    string? CategoryName,
    DateTime CreatedAtUtc,
    DateTime? UpdatedAtUtc);
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace Catalog.Application.Products.Dtos;

/// <summary>
/// Request to create a product.
/// </summary>
public sealed record CreateProductRequest
{
    /// <summary>Gets the product name.</summary>
    [Required, StringLength(200, MinimumLength = 1)]
    public required string Name { get; init; }

    /// <summary>Gets the unique SKU.</summary>
    [Required, StringLength(50, MinimumLength = 1)]
    public required string Sku { get; init; }

    /// <summary>Gets the optional description.</summary>
    [StringLength(2000)]
    public string? Description { get; init; }

    /// <summary>Gets the unit price.</summary>
    [Range(typeof(decimal), "0.01", "9999999999999999.99")]
    public decimal Price { get; init; }

    /// <summary>Gets the initial stock quantity.</summary>
    [Range(0, int.MaxValue)]
    public int StockQuantity { get; init; }

    /// <summary>Gets the category id.</summary>
    [Range(1, int.MaxValue)]
    public int CategoryId { get; init; }
}
```

```csharp
using System.ComponentModel.DataAnnotations;

namespace Catalog.Application.Products.Dtos;

/// <summary>
/// Request to update a product. The SKU is immutable.
/// </summary>
public sealed record UpdateProductRequest
{
    /// <summary>Gets the product name.</summary>
    [Required, StringLength(200, MinimumLength = 1)]
    public required string Name { get; init; }

    /// <summary>Gets the optional description.</summary>
    [StringLength(2000)]
    public string? Description { get; init; }

    /// <summary>Gets the unit price.</summary>
    [Range(typeof(decimal), "0.01", "9999999999999999.99")]
    public decimal Price { get; init; }

    /// <summary>Gets the stock quantity.</summary>
    [Range(0, int.MaxValue)]
    public int StockQuantity { get; init; }

    /// <summary>Gets the category id.</summary>
    [Range(1, int.MaxValue)]
    public int CategoryId { get; init; }

    /// <summary>Gets a value indicating whether the product is active.</summary>
    public bool IsActive { get; init; } = true;
}
```

## ProductMappings.cs

Use manual mapping extensions: they are explicit, fast and need no reflection. Only introduce a mapper library if the project already uses one.

```csharp
using Catalog.Application.Products.Dtos;
using Catalog.Domain.Products;

namespace Catalog.Application.Products;

/// <summary>
/// Maps between <see cref="Product"/> entities and DTOs.
/// </summary>
public static class ProductMappings
{
    /// <summary>Maps a product entity to a <see cref="ProductDto"/>.</summary>
    /// <param name="product">The product entity.</param>
    /// <returns>The DTO.</returns>
    public static ProductDto ToDto(this Product product)
    {
        ArgumentNullException.ThrowIfNull(product);

        return new ProductDto(
            product.Id,
            product.Name,
            product.Sku,
            product.Description,
            product.Price,
            product.StockQuantity,
            product.IsActive,
            product.CategoryId,
            product.Category?.Name,
            product.CreatedAtUtc,
            product.UpdatedAtUtc);
    }

    /// <summary>Creates a new product entity from a create request.</summary>
    /// <param name="request">The create request.</param>
    /// <returns>The new entity.</returns>
    public static Product ToEntity(this CreateProductRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);
        return new Product(request.Name, request.Sku, request.Description, request.Price, request.StockQuantity, request.CategoryId);
    }
}
```

## IProductService.cs

```csharp
using Catalog.Application.Common;
using Catalog.Application.Products.Dtos;

namespace Catalog.Application.Products;

/// <summary>
/// Product use cases.
/// </summary>
public interface IProductService
{
    /// <summary>Gets a product by id.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The product.</returns>
    /// <exception cref="Common.Exceptions.NotFoundException">Thrown when the product does not exist.</exception>
    Task<ProductDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>Gets a page of products.</summary>
    /// <param name="pageNumber">The 1-based page number.</param>
    /// <param name="pageSize">The requested page size (clamped to configured limits).</param>
    /// <param name="categoryId">An optional category filter.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The page of products.</returns>
    Task<PagedResult<ProductDto>> GetPagedAsync(int pageNumber, int? pageSize, int? categoryId, CancellationToken cancellationToken = default);

    /// <summary>Creates a product.</summary>
    /// <param name="request">The create request.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The created product.</returns>
    /// <exception cref="Common.Exceptions.ConflictException">Thrown when the SKU already exists.</exception>
    /// <exception cref="Common.Exceptions.NotFoundException">Thrown when the category does not exist.</exception>
    Task<ProductDto> CreateAsync(CreateProductRequest request, CancellationToken cancellationToken = default);

    /// <summary>Updates a product.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="request">The update request.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The updated product.</returns>
    /// <exception cref="Common.Exceptions.NotFoundException">Thrown when the product or category does not exist.</exception>
    Task<ProductDto> UpdateAsync(int id, UpdateProductRequest request, CancellationToken cancellationToken = default);

    /// <summary>Deletes a product.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <exception cref="Common.Exceptions.NotFoundException">Thrown when the product does not exist.</exception>
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}
```

## ProductService.cs

```csharp
using Catalog.Application.Common;
using Catalog.Application.Common.Exceptions;
using Catalog.Application.Products.Dtos;
using Catalog.Domain.Categories;
using Catalog.Domain.Common;
using Catalog.Domain.Products;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Catalog.Application.Products;

/// <summary>
/// Implements product use cases by orchestrating repositories and the unit of work.
/// </summary>
/// <param name="productRepository">The product repository.</param>
/// <param name="categoryRepository">The category repository.</param>
/// <param name="unitOfWork">The unit of work.</param>
/// <param name="paginationOptions">Paging limits from configuration.</param>
/// <param name="logger">The logger.</param>
public sealed class ProductService(
    IProductRepository productRepository,
    ICategoryRepository categoryRepository,
    IUnitOfWork unitOfWork,
    IOptions<PaginationOptions> paginationOptions,
    ILogger<ProductService> logger) : IProductService
{
    private readonly IProductRepository _productRepository = productRepository ?? throw new ArgumentNullException(nameof(productRepository));
    private readonly ICategoryRepository _categoryRepository = categoryRepository ?? throw new ArgumentNullException(nameof(categoryRepository));
    private readonly IUnitOfWork _unitOfWork = unitOfWork ?? throw new ArgumentNullException(nameof(unitOfWork));
    private readonly PaginationOptions _pagination = paginationOptions?.Value ?? throw new ArgumentNullException(nameof(paginationOptions));
    private readonly ILogger<ProductService> _logger = logger ?? throw new ArgumentNullException(nameof(logger));

    /// <inheritdoc />
    public async Task<ProductDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        _logger.LogDebug("Retrieving product {ProductId}", id);

        var product = await _productRepository.GetWithCategoryAsync(id, cancellationToken).ConfigureAwait(false);
        if (product is null)
        {
            _logger.LogWarning("Product {ProductId} not found", id);
            throw new NotFoundException(nameof(Product), id);
        }

        return product.ToDto();
    }

    /// <inheritdoc />
    public async Task<PagedResult<ProductDto>> GetPagedAsync(
        int pageNumber,
        int? pageSize,
        int? categoryId,
        CancellationToken cancellationToken = default)
    {
        var page = Math.Max(1, pageNumber);
        var size = Math.Clamp(pageSize ?? _pagination.DefaultPageSize, 1, _pagination.MaxPageSize);

        _logger.LogDebug(
            "Retrieving products page {PageNumber} (size {PageSize}, category {CategoryId})",
            page, size, categoryId);

        var (items, totalCount) = await _productRepository
            .GetPagedAsync(page, size, categoryId, cancellationToken)
            .ConfigureAwait(false);

        return new PagedResult<ProductDto>(items.Select(p => p.ToDto()).ToList(), page, size, totalCount);
    }

    /// <inheritdoc />
    public async Task<ProductDto> CreateAsync(CreateProductRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);

        using var scope = _logger.BeginScope(new Dictionary<string, object> { ["Sku"] = request.Sku });
        _logger.LogInformation("Creating product {Sku} in category {CategoryId}", request.Sku, request.CategoryId);

        await EnsureCategoryExistsAsync(request.CategoryId, cancellationToken).ConfigureAwait(false);

        if (await _productRepository.GetBySkuAsync(request.Sku, cancellationToken).ConfigureAwait(false) is not null)
        {
            _logger.LogWarning("Product creation rejected: SKU {Sku} already exists", request.Sku);
            throw new ConflictException($"A product with SKU '{request.Sku}' already exists.");
        }

        var product = request.ToEntity();
        await _productRepository.AddAsync(product, cancellationToken).ConfigureAwait(false);
        await _unitOfWork.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Created product {ProductId} with SKU {Sku}", product.Id, product.Sku);

        return await GetByIdAsync(product.Id, cancellationToken).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task<ProductDto> UpdateAsync(int id, UpdateProductRequest request, CancellationToken cancellationToken = default)
    {
        ArgumentNullException.ThrowIfNull(request);
        _logger.LogInformation("Updating product {ProductId}", id);

        var product = await _productRepository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false)
            ?? throw new NotFoundException(nameof(Product), id);

        if (product.CategoryId != request.CategoryId)
        {
            await EnsureCategoryExistsAsync(request.CategoryId, cancellationToken).ConfigureAwait(false);
            product.ChangeCategory(request.CategoryId);
        }

        product.UpdateDetails(request.Name, request.Description, request.Price);
        product.SetStock(request.StockQuantity);
        if (request.IsActive)
        {
            product.Activate();
        }
        else
        {
            product.Deactivate();
        }

        // Tracked entity: no need to call Update(); the change tracker detects modifications.
        await _unitOfWork.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Updated product {ProductId}", id);
        return await GetByIdAsync(id, cancellationToken).ConfigureAwait(false);
    }

    /// <inheritdoc />
    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Deleting product {ProductId}", id);

        var product = await _productRepository.GetByIdAsync(id, cancellationToken).ConfigureAwait(false)
            ?? throw new NotFoundException(nameof(Product), id);

        _productRepository.Remove(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken).ConfigureAwait(false);

        _logger.LogInformation("Deleted product {ProductId}", id);
    }

    private async Task EnsureCategoryExistsAsync(int categoryId, CancellationToken cancellationToken)
    {
        if (!await _categoryRepository.AnyAsync(c => c.Id == categoryId, cancellationToken).ConfigureAwait(false))
        {
            _logger.LogWarning("Category {CategoryId} not found", categoryId);
            throw new NotFoundException(nameof(Category), categoryId);
        }
    }
}
```

## DependencyInjection.cs

```csharp
using Catalog.Application.Common;
using Catalog.Application.Products;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Catalog.Application;

/// <summary>
/// Registers Application services.
/// </summary>
public static class DependencyInjection
{
    /// <summary>Adds Application services to the container.</summary>
    /// <param name="services">The service collection.</param>
    /// <param name="configuration">The application configuration.</param>
    /// <returns>The same service collection for chaining.</returns>
    public static IServiceCollection AddApplication(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddOptions<PaginationOptions>()
            .Bind(configuration.GetSection(PaginationOptions.SectionName))
            .ValidateDataAnnotations()
            .ValidateOnStart();

        services.AddScoped<IProductService, ProductService>();

        return services;
    }
}
```

## Rules

- Services depend on **Domain interfaces** only (`IProductRepository`, `IUnitOfWork`), never on `AppDbContext`.
- Each write use case calls `SaveChangesAsync` **once**.
- Services always return DTOs or `PagedResult<TDto>`, never entities.
- Throw `NotFoundException` or `ConflictException` for expected failures. Let `DomainException` from entities propagate.
- Service unit test example (MSTest + Moq + FluentAssertions):

```csharp
[TestMethod]
public async Task CreateAsync_DuplicateSku_ThrowsConflictAndDoesNotSave()
{
    // Arrange
    var products = new Mock<IProductRepository>();
    var categories = new Mock<ICategoryRepository>();
    var uow = new Mock<IUnitOfWork>();
    categories.Setup(c => c.AnyAsync(It.IsAny<Expression<Func<Category, bool>>>(), It.IsAny<CancellationToken>())).ReturnsAsync(true);
    products.Setup(p => p.GetBySkuAsync("ABC", It.IsAny<CancellationToken>()))
        .ReturnsAsync(new Product("Existing", "ABC", null, 1m, 0, 1));
    var sut = new ProductService(products.Object, categories.Object, uow.Object,
        Options.Create(new PaginationOptions()), NullLogger<ProductService>.Instance);
    var request = new CreateProductRequest { Name = "New", Sku = "ABC", Price = 5m, CategoryId = 1 };

    // Act
    var act = () => sut.CreateAsync(request);

    // Assert
    await act.Should().ThrowAsync<ConflictException>();
    uow.Verify(u => u.SaveChangesAsync(It.IsAny<CancellationToken>()), Times.Never);
}
```
