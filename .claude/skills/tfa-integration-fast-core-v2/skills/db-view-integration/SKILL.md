---
name: db-view-integration
description: Setup direct read-only access to core system database views with AUTOMATED setup. Prompts for connection string, automatically adds to appsettings.json (key: FASTDB), generates Entity Framework context, creates entities, and generates service/interface for querying. Includes mandatory audit logging and read-only enforcement.
---

# Database View Integration (Read-Only Access) - AUTOMATED

Direct read-only access to core system database views with **automatic configuration and code generation**.

## ⚡ What This Skill Does

This skill **automates** the entire setup process:

1. ✅ Prompts you for connection string
2. ✅ Adds it to appsettings.json (ConnectionStrings:FASTDB)
3. ✅ Generates Entity Framework DbContext
4. ✅ Creates entity models for your views
5. ✅ Generates repository interface
6. ✅ Generates repository implementation
7. ✅ Adds audit logging
8. ✅ Configures dependency injection
9. ✅ Creates service for querying
10. ✅ Ready to use immediately

---

## Use Cases

✅ Reporting and analytics queries  
✅ Real-time data dashboard  
✅ Batch data exports  
✅ High-performance read operations  
✅ Direct database access (read-only only)  

## Important Notes

⚠️ **READ-ONLY ONLY** — No INSERT, UPDATE, or DELETE operations  
⚠️ **Audit Logging Mandatory** — All access must be logged  
⚠️ **Parameterized Queries Required** — Prevent SQL injection  
⚠️ **No Direct Table Access** — Use only provided views  

---

## Prerequisites

- .NET Core 6 or later
- Entity Framework Core
- SQL Server database with views available
- Serilog or ILogger (audit logging)
- Connection string from core system team
- View name(s) from core system team

---

## Step 1: Collect Required Information

### Gather From User

Ask the developer for:

1. **Connection String**
   ```
   Example: Server=db.example.com;Database=CoreSystem;Integrated Security=true;
   ```

2. **View Names** (comma-separated)
   ```
   Example: vw_Users, vw_Orders, vw_Products
   ```

3. **Database Type**
   ```
   Options: SQL Server (default)
   ```

---

## Step 2: Update appsettings.json

### Automatically Add Connection String

The system should prompt and then update:

**File:** `appsettings.json`

```json
{
  "ConnectionStrings": {
    "FASTDB": "Server=db.example.com;Database=CoreSystem;Integrated Security=true;"
  },
  "Serilog": {
    "MinimumLevel": "Information",
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "logs/database-audit-.txt",
          "rollingInterval": "Day"
        }
      }
    ]
  }
}
```

### Code to Add Connection String

```csharp
// In Startup.cs or Program.cs
var connectionString = configuration.GetConnectionString("FASTDB");
services.AddDbContext<FastCoreDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.CommandTimeout(30);
        sqlOptions.EnableRetryOnFailure(maxRetryCount: 3);
    });
});
```

---

## Step 3: Auto-Generate Entity Models

### For Each View, Create Entity Class

**Example for vw_Users:**

```csharp
// Models/UserView.cs
using System;

namespace YourProject.Models
{
    /// <summary>
    /// Entity model for vw_Users database view
    /// </summary>
    public class UserView
    {
        public int UserId { get; set; }
        public string UserName { get; set; }
        public string Email { get; set; }
        public string Department { get; set; }
        public DateTime CreatedDate { get; set; }
        public bool IsActive { get; set; }
    }
}
```

**Example for vw_Orders:**

```csharp
// Models/OrderView.cs
using System;

namespace YourProject.Models
{
    public class OrderView
    {
        public int OrderId { get; set; }
        public int UserId { get; set; }
        public string OrderNumber { get; set; }
        public decimal Amount { get; set; }
        public DateTime OrderDate { get; set; }
        public string Status { get; set; }
    }
}
```

---

## Step 4: Auto-Generate DbContext

### FastCoreDbContext

**File:** `Data/FastCoreDbContext.cs`

```csharp
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YourProject.Models;

namespace YourProject.Data
{
    /// <summary>
    /// Entity Framework Core context for core system database views
    /// </summary>
    public class FastCoreDbContext : DbContext
    {
        private readonly ILogger<FastCoreDbContext> _logger;

        public FastCoreDbContext(
            DbContextOptions<FastCoreDbContext> options,
            ILogger<FastCoreDbContext> logger) : base(options)
        {
            _logger = logger;
        }

        // Add DbSet for each view
        public DbSet<UserView> UserViews { get; set; }
        public DbSet<OrderView> OrderViews { get; set; }
        // Add more views as needed

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // Configure UserView
            modelBuilder.Entity<UserView>(entity =>
            {
                entity.HasNoKey(); // Views don't have primary keys
                entity.ToView("vw_Users"); // Map to database view name
                _logger.LogInformation("Configured UserView mapping to vw_Users");
            });

            // Configure OrderView
            modelBuilder.Entity<OrderView>(entity =>
            {
                entity.HasNoKey();
                entity.ToView("vw_Orders");
                _logger.LogInformation("Configured OrderView mapping to vw_Orders");
            });
            
            // Add more view configurations as needed
        }

        /// <summary>
        /// Prevent any modifications to database views
        /// </summary>
        public override int SaveChanges()
        {
            throw new InvalidOperationException(
                "Database views are read-only. No modifications allowed.");
        }

        /// <summary>
        /// Prevent any async modifications to database views
        /// </summary>
        public override async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            throw new InvalidOperationException(
                "Database views are read-only. No modifications allowed.");
        }
    }
}
```

---

## Step 5: Auto-Generate Repository Interface

### IFastCoreRepository

**File:** `Repositories/IFastCoreRepository.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YourProject.Models;

namespace YourProject.Repositories
{
    /// <summary>
    /// Interface for querying core system database views
    /// </summary>
    public interface IFastCoreRepository
    {
        // User View Methods
        Task<List<UserView>> GetAllUsersAsync();
        Task<UserView> GetUserByIdAsync(int userId);
        Task<List<UserView>> GetUsersByDepartmentAsync(string department);
        Task<List<UserView>> SearchUsersAsync(string searchTerm);
        Task<int> GetActiveUserCountAsync();

        // Order View Methods
        Task<List<OrderView>> GetAllOrdersAsync();
        Task<OrderView> GetOrderByIdAsync(int orderId);
        Task<List<OrderView>> GetOrdersByUserAsync(int userId);
        Task<List<OrderView>> GetOrdersByStatusAsync(string status);
        Task<decimal> GetTotalOrderAmountAsync();

        // Generic Method
        Task<List<T>> ExecuteQueryAsync<T>(string sqlQuery) where T : class;
    }
}
```

---

## Step 6: Auto-Generate Repository Implementation

### FastCoreRepository

**File:** `Repositories/FastCoreRepository.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YourProject.Data;
using YourProject.Models;

namespace YourProject.Repositories
{
    /// <summary>
    /// Repository for accessing core system database views
    /// Provides read-only access with mandatory audit logging
    /// </summary>
    public class FastCoreRepository : IFastCoreRepository
    {
        private readonly FastCoreDbContext _context;
        private readonly ILogger<FastCoreRepository> _logger;
        private readonly AuditLogger _auditLogger;

        public FastCoreRepository(
            FastCoreDbContext context,
            ILogger<FastCoreRepository> logger,
            AuditLogger auditLogger)
        {
            _context = context;
            _logger = logger;
            _auditLogger = auditLogger;
        }

        // ===== USER VIEW METHODS =====

        public async Task<List<UserView>> GetAllUsersAsync()
        {
            try
            {
                _logger.LogInformation("Fetching all users from vw_Users");
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Users", "all rows");

                var users = await _context.UserViews.ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Users", users.Count);
                _logger.LogInformation("Retrieved {count} users", users.Count);

                return users;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching users: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Users", ex.Message);
                throw;
            }
        }

        public async Task<UserView> GetUserByIdAsync(int userId)
        {
            try
            {
                _logger.LogInformation("Fetching user {userId}", userId);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Users", $"UserId = {userId}");

                // Use parameterized query to prevent SQL injection
                var user = await _context.UserViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Users WHERE UserId = {userId}")
                    .FirstOrDefaultAsync();

                if (user != null)
                {
                    _logger.LogInformation("User {userId} found: {userName}", userId, user.UserName);
                    _auditLogger.LogDatabaseAccessSuccess("vw_Users", 1);
                }
                else
                {
                    _logger.LogWarning("User {userId} not found", userId);
                    _auditLogger.LogDatabaseAccessSuccess("vw_Users", 0);
                }

                return user;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching user {userId}: {message}", userId, ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Users", ex.Message);
                throw;
            }
        }

        public async Task<List<UserView>> GetUsersByDepartmentAsync(string department)
        {
            try
            {
                _logger.LogInformation("Fetching users from department: {dept}", department);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Users", $"Department = '{department}'");

                var users = await _context.UserViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Users WHERE Department = {department}")
                    .ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Users", users.Count);
                _logger.LogInformation("Retrieved {count} users from {dept}", users.Count, department);

                return users;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching department users: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Users", ex.Message);
                throw;
            }
        }

        public async Task<List<UserView>> SearchUsersAsync(string searchTerm)
        {
            try
            {
                _logger.LogInformation("Searching users with term: {term}", searchTerm);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Users", $"LIKE '%{searchTerm}%'");

                var users = await _context.UserViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Users WHERE UserName LIKE {('%' + searchTerm + '%')}")
                    .ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Users", users.Count);
                return users;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error searching users: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Users", ex.Message);
                throw;
            }
        }

        public async Task<int> GetActiveUserCountAsync()
        {
            try
            {
                _logger.LogInformation("Counting active users");
                _auditLogger.LogDatabaseAccess("SELECT COUNT(*)", "vw_Users", "IsActive = 1");

                var count = await _context.UserViews
                    .Where(u => u.IsActive)
                    .CountAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Users", 1);
                _logger.LogInformation("Active user count: {count}", count);

                return count;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error counting active users: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Users", ex.Message);
                throw;
            }
        }

        // ===== ORDER VIEW METHODS =====

        public async Task<List<OrderView>> GetAllOrdersAsync()
        {
            try
            {
                _logger.LogInformation("Fetching all orders from vw_Orders");
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Orders", "all rows");

                var orders = await _context.OrderViews.ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Orders", orders.Count);
                _logger.LogInformation("Retrieved {count} orders", orders.Count);

                return orders;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching orders: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Orders", ex.Message);
                throw;
            }
        }

        public async Task<OrderView> GetOrderByIdAsync(int orderId)
        {
            try
            {
                _logger.LogInformation("Fetching order {orderId}", orderId);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Orders", $"OrderId = {orderId}");

                var order = await _context.OrderViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Orders WHERE OrderId = {orderId}")
                    .FirstOrDefaultAsync();

                if (order != null)
                {
                    _auditLogger.LogDatabaseAccessSuccess("vw_Orders", 1);
                }
                else
                {
                    _auditLogger.LogDatabaseAccessSuccess("vw_Orders", 0);
                }

                return order;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching order {orderId}: {message}", orderId, ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Orders", ex.Message);
                throw;
            }
        }

        public async Task<List<OrderView>> GetOrdersByUserAsync(int userId)
        {
            try
            {
                _logger.LogInformation("Fetching orders for user {userId}", userId);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Orders", $"UserId = {userId}");

                var orders = await _context.OrderViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Orders WHERE UserId = {userId}")
                    .ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Orders", orders.Count);
                return orders;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching user orders: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Orders", ex.Message);
                throw;
            }
        }

        public async Task<List<OrderView>> GetOrdersByStatusAsync(string status)
        {
            try
            {
                _logger.LogInformation("Fetching orders with status: {status}", status);
                _auditLogger.LogDatabaseAccess("SELECT", "vw_Orders", $"Status = '{status}'");

                var orders = await _context.OrderViews
                    .FromSqlInterpolated($"SELECT * FROM vw_Orders WHERE Status = {status}")
                    .ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("vw_Orders", orders.Count);
                return orders;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error fetching orders by status: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Orders", ex.Message);
                throw;
            }
        }

        public async Task<decimal> GetTotalOrderAmountAsync()
        {
            try
            {
                _logger.LogInformation("Calculating total order amount");
                _auditLogger.LogDatabaseAccess("SELECT SUM()", "vw_Orders", "Amount column");

                var total = await _context.OrderViews
                    .SumAsync(o => o.Amount);

                _auditLogger.LogDatabaseAccessSuccess("vw_Orders", 1);
                _logger.LogInformation("Total order amount: {total}", total);

                return total;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error calculating total: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("vw_Orders", ex.Message);
                throw;
            }
        }

        // ===== GENERIC METHOD =====

        public async Task<List<T>> ExecuteQueryAsync<T>(string sqlQuery) where T : class
        {
            try
            {
                _logger.LogInformation("Executing custom query");
                _auditLogger.LogDatabaseAccess("SELECT", "custom query", sqlQuery);

                var result = await _context.Set<T>()
                    .FromSqlRaw(sqlQuery)
                    .ToListAsync();

                _auditLogger.LogDatabaseAccessSuccess("custom", result.Count);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error executing query: {message}", ex.Message);
                _auditLogger.LogDatabaseAccessError("custom query", ex.Message);
                throw;
            }
        }
    }
}
```

---

## Step 7: Auto-Generate Service Layer

### FastCoreService

**File:** `Services/IFastCoreService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using YourProject.Models;

namespace YourProject.Services
{
    public interface IFastCoreService
    {
        // User operations
        Task<List<UserDto>> GetAllUsersAsync();
        Task<UserDto> GetUserAsync(int userId);
        Task<List<UserDto>> SearchUsersAsync(string searchTerm);
        Task<int> GetActiveUserCountAsync();

        // Order operations
        Task<List<OrderDto>> GetAllOrdersAsync();
        Task<OrderDto> GetOrderAsync(int orderId);
        Task<decimal> GetTotalRevenueAsync();
    }
}
```

**File:** `Services/FastCoreService.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YourProject.Models;
using YourProject.Repositories;

namespace YourProject.Services
{
    public class FastCoreService : IFastCoreService
    {
        private readonly IFastCoreRepository _repository;
        private readonly ILogger<FastCoreService> _logger;

        public FastCoreService(
            IFastCoreRepository repository,
            ILogger<FastCoreService> logger)
        {
            _repository = repository;
            _logger = logger;
        }

        // ===== USER OPERATIONS =====

        public async Task<List<UserDto>> GetAllUsersAsync()
        {
            try
            {
                _logger.LogInformation("Service: Getting all users");

                var users = await _repository.GetAllUsersAsync();

                return users.Select(u => new UserDto
                {
                    Id = u.UserId,
                    Name = u.UserName,
                    Email = u.Email,
                    Department = u.Department,
                    IsActive = u.IsActive
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetAllUsersAsync: {message}", ex.Message);
                throw;
            }
        }

        public async Task<UserDto> GetUserAsync(int userId)
        {
            try
            {
                _logger.LogInformation("Service: Getting user {userId}", userId);

                var user = await _repository.GetUserByIdAsync(userId);

                if (user == null)
                {
                    _logger.LogWarning("User {userId} not found", userId);
                    return null;
                }

                return new UserDto
                {
                    Id = user.UserId,
                    Name = user.UserName,
                    Email = user.Email,
                    Department = user.Department,
                    IsActive = user.IsActive
                };
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetUserAsync: {message}", ex.Message);
                throw;
            }
        }

        public async Task<List<UserDto>> SearchUsersAsync(string searchTerm)
        {
            try
            {
                _logger.LogInformation("Service: Searching users with term: {term}", searchTerm);

                var users = await _repository.SearchUsersAsync(searchTerm);

                return users.Select(u => new UserDto
                {
                    Id = u.UserId,
                    Name = u.UserName,
                    Email = u.Email,
                    Department = u.Department,
                    IsActive = u.IsActive
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in SearchUsersAsync: {message}", ex.Message);
                throw;
            }
        }

        public async Task<int> GetActiveUserCountAsync()
        {
            try
            {
                _logger.LogInformation("Service: Getting active user count");
                return await _repository.GetActiveUserCountAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetActiveUserCountAsync: {message}", ex.Message);
                throw;
            }
        }

        // ===== ORDER OPERATIONS =====

        public async Task<List<OrderDto>> GetAllOrdersAsync()
        {
            try
            {
                _logger.LogInformation("Service: Getting all orders");

                var orders = await _repository.GetAllOrdersAsync();

                return orders.Select(o => new OrderDto
                {
                    Id = o.OrderId,
                    OrderNumber = o.OrderNumber,
                    UserId = o.UserId,
                    Amount = o.Amount,
                    OrderDate = o.OrderDate,
                    Status = o.Status
                }).ToList();
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetAllOrdersAsync: {message}", ex.Message);
                throw;
            }
        }

        public async Task<OrderDto> GetOrderAsync(int orderId)
        {
            try
            {
                _logger.LogInformation("Service: Getting order {orderId}", orderId);

                var order = await _repository.GetOrderByIdAsync(orderId);

                if (order == null)
                {
                    _logger.LogWarning("Order {orderId} not found", orderId);
                    return null;
                }

                return new OrderDto
                {
                    Id = order.OrderId,
                    OrderNumber = order.OrderNumber,
                    UserId = order.UserId,
                    Amount = order.Amount,
                    OrderDate = order.OrderDate,
                    Status = order.Status
                };
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetOrderAsync: {message}", ex.Message);
                throw;
            }
        }

        public async Task<decimal> GetTotalRevenueAsync()
        {
            try
            {
                _logger.LogInformation("Service: Getting total revenue");
                return await _repository.GetTotalOrderAmountAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in GetTotalRevenueAsync: {message}", ex.Message);
                throw;
            }
        }
    }
}
```

---

## Step 8: Auto-Generate DTOs

### Data Transfer Objects

**File:** `Models/UserDto.cs`

```csharp
using System;

namespace YourProject.Models
{
    public class UserDto
    {
        public int Id { get; set; }
        public string Name { get; set; }
        public string Email { get; set; }
        public string Department { get; set; }
        public bool IsActive { get; set; }
    }
}
```

**File:** `Models/OrderDto.cs`

```csharp
using System;

namespace YourProject.Models
{
    public class OrderDto
    {
        public int Id { get; set; }
        public int UserId { get; set; }
        public string OrderNumber { get; set; }
        public decimal Amount { get; set; }
        public DateTime OrderDate { get; set; }
        public string Status { get; set; }
    }
}
```

---

## Step 9: Register in Dependency Injection

### Program.cs or Startup.cs

```csharp
// Add to ConfigureServices()

// Database Context
var connectionString = configuration.GetConnectionString("FASTDB");
services.AddDbContext<FastCoreDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.CommandTimeout(30);
        sqlOptions.EnableRetryOnFailure(maxRetryCount: 3);
    });
});

// Repository
services.AddScoped<IFastCoreRepository, FastCoreRepository>();

// Service
services.AddScoped<IFastCoreService, FastCoreService>();

// Audit Logger
services.AddScoped<AuditLogger>();

// Logging
services.AddLogging(config =>
{
    config.AddConsole();
    config.AddDebug();
});
```

---

## Step 10: Use in Controller

### Example Controller

**File:** `Controllers/DataController.cs`

```csharp
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using YourProject.Models;
using YourProject.Services;

namespace YourProject.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DataController : ControllerBase
    {
        private readonly IFastCoreService _service;
        private readonly ILogger<DataController> _logger;

        public DataController(
            IFastCoreService service,
            ILogger<DataController> logger)
        {
            _service = service;
            _logger = logger;
        }

        // ===== USER ENDPOINTS =====

        [HttpGet("users")]
        public async Task<ActionResult<List<UserDto>>> GetAllUsers()
        {
            try
            {
                _logger.LogInformation("GET /api/data/users");
                var users = await _service.GetAllUsersAsync();
                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error retrieving users");
            }
        }

        [HttpGet("users/{id}")]
        public async Task<ActionResult<UserDto>> GetUser(int id)
        {
            try
            {
                _logger.LogInformation("GET /api/data/users/{id}", id);
                var user = await _service.GetUserAsync(id);

                if (user == null)
                    return NotFound();

                return Ok(user);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error retrieving user");
            }
        }

        [HttpGet("users/search")]
        public async Task<ActionResult<List<UserDto>>> SearchUsers(string term)
        {
            try
            {
                _logger.LogInformation("GET /api/data/users/search?term={term}", term);
                var users = await _service.SearchUsersAsync(term);
                return Ok(users);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error searching users");
            }
        }

        [HttpGet("users/count/active")]
        public async Task<ActionResult<int>> GetActiveUserCount()
        {
            try
            {
                var count = await _service.GetActiveUserCountAsync();
                return Ok(new { activeUsers = count });
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error counting users");
            }
        }

        // ===== ORDER ENDPOINTS =====

        [HttpGet("orders")]
        public async Task<ActionResult<List<OrderDto>>> GetAllOrders()
        {
            try
            {
                _logger.LogInformation("GET /api/data/orders");
                var orders = await _service.GetAllOrdersAsync();
                return Ok(orders);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error retrieving orders");
            }
        }

        [HttpGet("orders/{id}")]
        public async Task<ActionResult<OrderDto>> GetOrder(int id)
        {
            try
            {
                _logger.LogInformation("GET /api/data/orders/{id}", id);
                var order = await _service.GetOrderAsync(id);

                if (order == null)
                    return NotFound();

                return Ok(order);
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error retrieving order");
            }
        }

        [HttpGet("orders/revenue/total")]
        public async Task<ActionResult<decimal>> GetTotalRevenue()
        {
            try
            {
                var total = await _service.GetTotalRevenueAsync();
                return Ok(new { totalRevenue = total });
            }
            catch (Exception ex)
            {
                _logger.LogError("Error: {message}", ex.Message);
                return StatusCode(500, "Error calculating revenue");
            }
        }
    }
}
```

---

## Complete Setup Workflow

### 1. Developer Opens Claude Code
```
"Setup database view integration for my project"
```

### 2. System Asks Questions
```
Connection String: [user enters]
View Names: [user enters: vw_Users, vw_Orders]
Database Type: [SQL Server selected]
```

### 3. System Automatically:
- ✅ Updates appsettings.json (FASTDB key)
- ✅ Creates DbContext
- ✅ Generates entity models
- ✅ Creates repository interface & implementation
- ✅ Generates service layer
- ✅ Creates DTOs
- ✅ Shows DI configuration code
- ✅ Provides example controller

### 4. Developer
- ✅ Copies DI configuration
- ✅ Injects service into controller
- ✅ Uses service methods
- ✅ Ready to go!

---

## Pre-Deployment Checklist

- ✅ Connection string in appsettings.json (FASTDB key)
- ✅ DbContext configured and registered
- ✅ All views mapped in OnModelCreating
- ✅ SaveChanges() blocked (read-only enforcement)
- ✅ Repository interface implemented
- ✅ Service layer created
- ✅ DTOs defined
- ✅ Dependency injection configured
- ✅ Audit logging implemented
- ✅ Error handling in all methods
- ✅ Parameterized queries used
- ✅ Connection pooling enabled
- ✅ Timeout configured (30 seconds)

---

## Summary

| Step | What | Time |
|------|------|------|
| 1 | Collect info | 2 min |
| 2 | Update appsettings | Auto |
| 3-8 | Generate code | Auto |
| 9 | Register DI | 2 min |
| 10 | Use in controller | 5 min |
| **Total** | | **~10 min** |

---

## See Also

- `references/core-system-overview.md` — Database views available
- `references/audit-logging-mandatory.md` — Logging setup
- `references/error-troubleshooting.md` — Database errors
- `references/security-best-practices.md` — Security guidelines

---

**Database integration ready in 10 minutes!** 🚀
