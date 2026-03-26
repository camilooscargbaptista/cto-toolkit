---
name: csharp-dotnet-review
description: "Review .NET/C# code: ASP.NET Core, EF Core, Minimal APIs, Azure patterns and performance"
triggers:
  frameworks: [dotnet, aspnet, efcore, blazor]
  file-patterns: ["**/*.cs", "**/*.csproj"]
preferred-model: sonnet
min-confidence: 0.4
depends-on: []
category: code-quality
estimated-tokens: 5000
tags: [csharp, dotnet, aspnet]
---

# C# / .NET Code Review

## When to Use
- Reviewing C#/.NET code (ASP.NET Core, EF Core, Minimal APIs)
- Evaluating .NET architecture patterns (Clean Architecture, CQRS, MediatR)
- Azure service integration review

## Review Checklist

### Architecture & Patterns
- [ ] Clean Architecture: Domain independent of infrastructure
- [ ] Dependency Injection used throughout (no `new Service()`)
- [ ] CQRS separation when appropriate (Commands vs Queries)
- [ ] MediatR or similar for decoupled handlers
- [ ] Repository pattern for data access abstraction
- [ ] Options pattern for configuration (`IOptions<T>`)

### C# Best Practices
- [ ] `async/await` used correctly (no `.Result` or `.Wait()`)
- [ ] `CancellationToken` propagated through async chains
- [ ] `IDisposable` implemented for unmanaged resources
- [ ] `null` handled with nullable reference types (`?`, `??`, `?.`)
- [ ] Records used for immutable DTOs
- [ ] `sealed` classes where inheritance not needed
- [ ] `readonly` for immutable fields
- [ ] Pattern matching instead of type casting

### EF Core
- [ ] No N+1 queries (use `.Include()` or `.AsSplitQuery()`)
- [ ] `AsNoTracking()` for read-only queries
- [ ] Indexes defined on frequently queried columns
- [ ] Migrations tested and reversible
- [ ] Connection pooling configured
- [ ] Query filters for soft delete / multi-tenancy

### Security
- [ ] `[Authorize]` on all protected endpoints
- [ ] Input validation with data annotations or FluentValidation
- [ ] Anti-forgery tokens for forms
- [ ] CORS configured restrictively
- [ ] User secrets / Azure Key Vault for credentials
- [ ] No SQL string concatenation (parameterized queries)

### Performance
- [ ] Response caching where appropriate
- [ ] `IMemoryCache` or `IDistributedCache` for hot data
- [ ] Minimal API for high-throughput endpoints
- [ ] `System.Text.Json` configured (not Newtonsoft unless needed)
- [ ] Pagination on list endpoints
- [ ] Background tasks via `IHostedService` / Hangfire

## Output Format
```markdown
## .NET Review: [Component]
**Health Score**: X/10

### Critical Issues
- [Issue with fix]

### Improvements
- [Suggestion with example]

### Architecture Notes
- [Pattern observations]
```
