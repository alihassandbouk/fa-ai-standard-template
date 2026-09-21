# Domain Layer (Core)

Project: `{Solution}.Domain`. It has **no NuGet dependencies** and uses the BCL only.

```
{Solution}.Domain/
  Common/
    BaseEntity.cs
    DomainException.cs
    IRepository.cs
    IUnitOfWork.cs
  Categories/
    Category.cs
    ICategoryRepository.cs
  Products/
    Product.cs
    IProductRepository.cs
```

The examples use `Catalog` as `{Solution}`.

## Common/BaseEntity.cs

```csharp
namespace Catalog.Domain.Common;

/// <summary>
/// Base type for all persisted entities. Provides identity and audit timestamps.
/// </summary>
public abstract class BaseEntity
{
    /// <summary>Gets the database-generated identifier.</summary>
    public int Id { get; private set; }

    /// <summary>Gets the UTC timestamp when the entity was created. Set by the persistence layer.</summary>
    public DateTime CreatedAtUtc { get; private set; }

    /// <summary>Gets the UTC timestamp of the last update, if any. Set by the persistence layer.</summary>
    public DateTime? UpdatedAtUtc { get; private set; }
}
```

> The audit properties have private setters. The Infrastructure `AuditableEntityInterceptor` sets them through EF Core's change tracker, so domain code can never tamper with them.

## Common/DomainException.cs

```csharp
namespace Catalog.Domain.Common;

/// <summary>
/// Thrown when a domain invariant or business rule is violated.
/// </summary>
/// <param name="message">A description of the violated rule.</param>
public sealed class DomainException(string message) : Exception(message);
```

## Common/IRepository.cs (base repository contract)

```csharp
using System.Linq.Expressions;

namespace Catalog.Domain.Common;

/// <summary>
/// Generic repository contract providing common data access operations for an entity.
/// Changes are persisted by <see cref="IUnitOfWork.SaveChangesAsync"/>, not by the repository.
/// </summary>
/// <typeparam name="TEntity">The entity type.</typeparam>
public interface IRepository<TEntity> where TEntity : BaseEntity
{
    /// <summary>Gets a <b>tracked</b> entity by id (use when you intend to modify it).</summary>
    /// <param name="id">The entity identifier.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The entity, or <c>null</c> when not found.</returns>
    Task<TEntity?> GetByIdAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>Gets all entities as a read-only, untracked list.</summary>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>All entities.</returns>
    Task<IReadOnlyList<TEntity>> GetAllAsync(CancellationToken cancellationToken = default);

    /// <summary>Finds untracked entities matching a predicate (translated to SQL).</summary>
    /// <param name="predicate">The filter expression.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The matching entities.</returns>
    Task<IReadOnlyList<TEntity>> FindAsync(
        Expression<Func<TEntity, bool>> predicate,
        CancellationToken cancellationToken = default);

    /// <summary>Determines whether any entity matches the predicate.</summary>
    /// <param name="predicate">The filter expression.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns><c>true</c> if at least one entity matches.</returns>
    Task<bool> AnyAsync(
        Expression<Func<TEntity, bool>> predicate,
        CancellationToken cancellationToken = default);

    /// <summary>Counts entities, optionally filtered by a predicate.</summary>
    /// <param name="predicate">An optional filter expression.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The number of matching entities.</returns>
    Task<int> CountAsync(
        Expression<Func<TEntity, bool>>? predicate = null,
        CancellationToken cancellationToken = default);

    /// <summary>Marks a new entity for insertion.</summary>
    /// <param name="entity">The entity to add.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    Task AddAsync(TEntity entity, CancellationToken cancellationToken = default);

    /// <summary>Marks an entity as modified.</summary>
    /// <param name="entity">The entity to update.</param>
    void Update(TEntity entity);

    /// <summary>Marks an entity for deletion.</summary>
    /// <param name="entity">The entity to remove.</param>
    void Remove(TEntity entity);
}
```

## Common/IUnitOfWork.cs

```csharp
namespace Catalog.Domain.Common;

/// <summary>
/// Commits all pending changes tracked across repositories as a single transaction.
/// </summary>
public interface IUnitOfWork
{
    /// <summary>Persists all pending changes to the database.</summary>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The number of state entries written.</returns>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
```

## Categories/Category.cs

```csharp
using Catalog.Domain.Common;
using Catalog.Domain.Products;

namespace Catalog.Domain.Categories;

/// <summary>
/// A product category.
/// </summary>
public sealed class Category : BaseEntity
{
    private readonly List<Product> _products = [];

    /// <summary>Required by EF Core.</summary>
    private Category()
    {
    }

    /// <summary>Creates a new category.</summary>
    /// <param name="name">The category name.</param>
    /// <exception cref="DomainException">Thrown when the name is empty.</exception>
    public Category(string name) => Rename(name);

    /// <summary>Gets the category name.</summary>
    public string Name { get; private set; } = string.Empty;

    /// <summary>Gets the products in this category.</summary>
    public IReadOnlyCollection<Product> Products => _products.AsReadOnly();

    /// <summary>Renames the category.</summary>
    /// <param name="name">The new name.</param>
    /// <exception cref="DomainException">Thrown when the name is empty.</exception>
    public void Rename(string name)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new DomainException("Category name is required.");
        }

        Name = name.Trim();
    }
}
```

## Products/Product.cs (entity model)

```csharp
using Catalog.Domain.Categories;
using Catalog.Domain.Common;

namespace Catalog.Domain.Products;

/// <summary>
/// A sellable product. Encapsulates its pricing and stock invariants.
/// </summary>
public sealed class Product : BaseEntity
{
    /// <summary>Required by EF Core.</summary>
    private Product()
    {
    }

    /// <summary>Creates a new active product.</summary>
    /// <param name="name">The product name.</param>
    /// <param name="sku">The unique stock keeping unit.</param>
    /// <param name="description">An optional description.</param>
    /// <param name="price">The unit price (must be positive).</param>
    /// <param name="stockQuantity">The initial stock (must not be negative).</param>
    /// <param name="categoryId">The owning category id.</param>
    /// <exception cref="DomainException">Thrown when any invariant is violated.</exception>
    public Product(string name, string sku, string? description, decimal price, int stockQuantity, int categoryId)
    {
        if (string.IsNullOrWhiteSpace(sku))
        {
            throw new DomainException("Product SKU is required.");
        }

        Sku = sku.Trim().ToUpperInvariant();
        CategoryId = categoryId;
        IsActive = true;
        UpdateDetails(name, description, price);
        SetStock(stockQuantity);
    }

    /// <summary>Gets the product name.</summary>
    public string Name { get; private set; } = string.Empty;

    /// <summary>Gets the unique stock keeping unit.</summary>
    public string Sku { get; private set; } = string.Empty;

    /// <summary>Gets the optional description.</summary>
    public string? Description { get; private set; }

    /// <summary>Gets the unit price.</summary>
    public decimal Price { get; private set; }

    /// <summary>Gets the quantity in stock.</summary>
    public int StockQuantity { get; private set; }

    /// <summary>Gets a value indicating whether the product can be sold.</summary>
    public bool IsActive { get; private set; }

    /// <summary>Gets the owning category id.</summary>
    public int CategoryId { get; private set; }

    /// <summary>Gets the owning category (loaded on demand).</summary>
    public Category? Category { get; private set; }

    /// <summary>Updates name, description and price.</summary>
    /// <param name="name">The new name.</param>
    /// <param name="description">The new description.</param>
    /// <param name="price">The new price (must be positive).</param>
    /// <exception cref="DomainException">Thrown when any invariant is violated.</exception>
    public void UpdateDetails(string name, string? description, decimal price)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new DomainException("Product name is required.");
        }

        if (price <= 0)
        {
            throw new DomainException("Product price must be greater than zero.");
        }

        Name = name.Trim();
        Description = description?.Trim();
        Price = price;
    }

    /// <summary>Sets the stock quantity.</summary>
    /// <param name="quantity">The new quantity (must not be negative).</param>
    /// <exception cref="DomainException">Thrown when the quantity is negative.</exception>
    public void SetStock(int quantity)
    {
        if (quantity < 0)
        {
            throw new DomainException("Stock quantity cannot be negative.");
        }

        StockQuantity = quantity;
    }

    /// <summary>Moves the product to another category.</summary>
    /// <param name="categoryId">The target category id.</param>
    public void ChangeCategory(int categoryId) => CategoryId = categoryId;

    /// <summary>Deactivates the product so it can no longer be sold.</summary>
    public void Deactivate() => IsActive = false;

    /// <summary>Re-activates the product.</summary>
    public void Activate() => IsActive = true;
}
```

## Entity repository interfaces

```csharp
using Catalog.Domain.Common;

namespace Catalog.Domain.Products;

/// <summary>
/// Product-specific data access operations in addition to the generic repository.
/// </summary>
public interface IProductRepository : IRepository<Product>
{
    /// <summary>Gets an untracked product by SKU.</summary>
    /// <param name="sku">The SKU (case-insensitive).</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The product, or <c>null</c> when not found.</returns>
    Task<Product?> GetBySkuAsync(string sku, CancellationToken cancellationToken = default);

    /// <summary>Gets an untracked product including its category.</summary>
    /// <param name="id">The product id.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The product, or <c>null</c> when not found.</returns>
    Task<Product?> GetWithCategoryAsync(int id, CancellationToken cancellationToken = default);

    /// <summary>Gets a page of untracked products (with category), optionally filtered by category.</summary>
    /// <param name="pageNumber">The 1-based page number.</param>
    /// <param name="pageSize">The page size.</param>
    /// <param name="categoryId">An optional category filter.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns>The page items and the total count of matching products.</returns>
    Task<(IReadOnlyList<Product> Items, int TotalCount)> GetPagedAsync(
        int pageNumber,
        int pageSize,
        int? categoryId,
        CancellationToken cancellationToken = default);
}
```

```csharp
using Catalog.Domain.Common;

namespace Catalog.Domain.Categories;

/// <summary>
/// Category-specific data access operations.
/// </summary>
public interface ICategoryRepository : IRepository<Category>
{
    /// <summary>Determines whether a category with the given name exists.</summary>
    /// <param name="name">The category name.</param>
    /// <param name="cancellationToken">A token to cancel the operation.</param>
    /// <returns><c>true</c> if it exists.</returns>
    Task<bool> NameExistsAsync(string name, CancellationToken cancellationToken = default);
}
```

## Rules

- There are no `[Required]`, `[MaxLength]` or `[Table]` attributes on entities. Persistence mapping belongs in Infrastructure configurations.
- Use private setters, a private parameterless constructor for EF, and public constructors and methods that validate invariants.
- Collections are exposed as `IReadOnlyCollection<T>` over a private `List<T>` backing field, which EF maps by convention.
- Repository interfaces expose domain concepts (`GetBySkuAsync`). Never expose `IQueryable` or EF types.
