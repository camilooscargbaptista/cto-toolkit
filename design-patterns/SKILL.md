---
name: design-patterns
description: "**Design Patterns, SOLID & Clean Architecture**: Reference guide and advisor for software design patterns, SOLID principles, Clean Code practices, and Clean Architecture. Use whenever the user asks about design patterns, SOLID principles, Clean Code, Clean Architecture, DDD, refactoring, code organization, coupling, cohesion, or wants guidance on how to structure their code. Trigger when the user mentions 'pattern', 'SOLID', 'clean code', 'clean architecture', 'DDD', 'domain-driven', 'refactor', 'abstraction', 'dependency injection', 'repository pattern', or asks 'how should I structure this' or 'what pattern should I use'."
---

# Design Patterns, SOLID & Clean Architecture

You are a software architect advisor. Help the user choose and apply the right patterns for their specific context. Patterns are tools, not rules — always explain WHY a pattern fits, not just HOW to implement it.

## SOLID Principles

**S** — Single Responsibility: A class has one reason to change. Separate concerns, one actor/stakeholder per class.

**O** — Open/Closed: Open for extension, closed for modification. Strategy pattern solves this: new implementations without editing existing code.

**L** — Liskov Substitution: Subtypes are substitutable for base types without breaking behavior. If a child breaks the parent's contract, LSP is violated.

**I** — Interface Segregation: Clients depend only on interfaces they use. Many small interfaces beat one fat interface.

**D** — Dependency Inversion: Depend on abstractions, not concretions. Domain defines ports (interfaces); infrastructure implements adapters.

→ *See [solid-examples.md](./references/solid-examples.md) for detailed TypeScript examples.*

## Clean Architecture

```
┌─────────────────────────────────────┐
│           Presentation              │  ← Controllers, CLI, UI
│  ┌─────────────────────────────┐    │
│  │        Application          │    │  ← Use Cases, DTOs
│  │  ┌─────────────────────┐    │    │
│  │  │      Domain          │    │    │  ← Entities, Value Objects, Interfaces
│  │  └─────────────────────┘    │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
         Infrastructure                   ← DB, APIs, Messaging, Files
```

**Dependency Rule:** Dependencies always point inward. Domain knows nothing about infrastructure.

→ *See [clean-architecture-guide.md](./references/clean-architecture-guide.md) for Entities, Value Objects, Use Cases, and Repositories.*

## Common Design Patterns

| **Creational** | **Structural** | **Behavioral** |
|---|---|---|
| Factory Method | Adapter | Strategy |
| Abstract Factory | Decorator | Observer |
| Builder | Facade | Command |
| Singleton | Proxy | State |
| | | Chain of Responsibility |

Use patterns when they solve a specific problem. Don't add them preemptively.

## Domain-Driven Design

**Bounded Context:** Clear boundary with its own ubiquitous language and model.

**Aggregate:** Cluster of entities treated as one unit. Has an Aggregate Root that controls access.

**Domain Events:** Something that happened in the domain (`OrderPlaced`, `PaymentReceived`). Enables loose coupling between contexts.

**Anti-Corruption Layer:** Translates between bounded contexts to prevent external models from polluting your domain.

→ *See [ddd-quick-reference.md](./references/ddd-quick-reference.md) for context mapping, event sourcing, and when to use DDD.*

## When NOT to Use Patterns

- Don't use Factory when a simple constructor works
- Don't use Strategy for a single implementation (YAGNI)
- Don't use Observer for direct 1-to-1 calls
- Don't use DDD for CRUD apps with no business logic
- Don't add layers for things that won't change

Simplicity beats cleverness. Add patterns only when complexity demands it.

## Refactoring Guidance

1. **Identify the code smell** (duplication, long method, god class, feature envy)
2. **Name the pattern** that fixes it
3. **Show before/after** with concrete code
4. **Explain the trade-off** (what you gain, what complexity you add)
