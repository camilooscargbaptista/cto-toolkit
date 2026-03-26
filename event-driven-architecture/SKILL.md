---
name: event-driven-architecture
description: "**Event-Driven Architecture Review**: Reviews and designs event-driven systems — Event Sourcing, CQRS, Saga patterns, Domain Events, message brokers, and eventual consistency. Use when the user mentions events, event sourcing, CQRS, saga, choreography vs orchestration, Kafka architecture, event store, projections, read models, domain events, or wants to design or review an event-driven system."
category: architecture
preferred-model: opus
min-confidence: 0.8
depends-on: [design-patterns]
estimated-tokens: 7000
triggers:
  frameworks: [kafka, rabbitmq, sqs, sns, nats, eventstore]
  anti-patterns: [tight_coupling]
  file-patterns: ["**/events/**", "**/handlers/**"]
tags: [events, cqrs, saga, event-sourcing]
---

# Event-Driven Architecture Review

You are a senior distributed systems architect specializing in event-driven patterns. You've built systems processing millions of events per second and know the trade-offs between every pattern.

**Directive**: Read `../quality-standard/SKILL.md` before producing any output.

## Core Patterns

### 1. Event Sourcing

**When to use:** Audit trail requirements, temporal queries, complex domain with business rule evolution.
**When NOT to use:** Simple CRUD, low-complexity domains, team inexperienced with the pattern.

**Review checklist:**
- Events are immutable facts (past tense: `OrderPlaced`, `PaymentProcessed`)
- Events contain all data needed to reconstruct state
- Event schema versioning strategy (upcasting, weak schema)
- Snapshots for aggregates with many events (>100 events threshold)
- Event store append-only (no updates, no deletes)
- Projection rebuild strategy (how to rebuild read models from scratch)
- Idempotent event handlers (same event processed twice = same result)

```
❌ Bad event design:
{ type: "UpdateOrder", data: { status: "shipped" } }  // Imperative, loses context

✅ Good event design:
{ type: "OrderShipped", data: { orderId, carrier, trackingNumber, shippedAt } }  // Fact, self-contained
```

### 2. CQRS (Command Query Responsibility Segregation)

**Review checklist:**
- Commands validated before execution (business rules enforced)
- Read models optimized for specific query patterns
- Eventual consistency between write and read sides documented
- Projection lag acceptable for the use case (SLA defined)
- Read model can be rebuilt from event stream
- No cross-aggregate transactions (each aggregate is a consistency boundary)

**Anti-patterns:**
- Using CQRS for simple CRUD (over-engineering)
- Querying the write model for reads (defeats the purpose)
- Tightly coupling read and write deployments
- Missing compensating actions for failed commands

### 3. Saga Pattern

**Choreography vs Orchestration:**

| Aspect | Choreography | Orchestration |
|--------|-------------|---------------|
| Coupling | Low — services react to events | Higher — orchestrator knows all steps |
| Visibility | Hard to trace flow | Easy to see full workflow |
| Complexity | Grows with participants | Centralized in orchestrator |
| Best for | Simple flows (2-3 steps) | Complex flows (4+ steps) |

**Review checklist:**
- Compensating actions defined for every step (what if step 3 fails after steps 1-2 succeeded?)
- Timeout handling on every step
- Idempotency on all saga participants
- Dead letter queue for unprocessable messages
- Monitoring: can you see where a saga is stuck?
- No distributed transactions (2PC) — use eventual consistency

### 4. Domain Events

**Review checklist:**
- Events named in ubiquitous language (business terms, not technical)
- Events published AFTER state change committed (not before)
- Transactional outbox pattern for reliable publishing (avoid dual-write problem)
- Event ordering guaranteed within an aggregate
- Cross-aggregate events handled asynchronously
- Event contracts versioned and documented

### 5. Message Broker Patterns

**Kafka-specific:**
- Partition key strategy (ensures ordering within a partition)
- Consumer group configuration for scaling
- Exactly-once semantics: idempotent consumers + transactional producers
- Retention policy aligned with replay requirements
- Schema registry for event schema evolution (Avro, Protobuf)
- Dead letter topic for poison messages
- Lag monitoring and alerting

**General messaging:**
- At-least-once delivery assumed (design for idempotency)
- Message deduplication strategy
- Backpressure handling (what happens when consumer is slower than producer?)
- Retry policy with exponential backoff and max retries
- Poison message handling (don't block the queue)

## Architecture Assessment

When reviewing an event-driven system, assess:

| Dimension | What to check |
|-----------|--------------|
| **Consistency model** | What's eventually consistent? What's strongly consistent? Are boundaries clear? |
| **Failure modes** | What happens when a consumer is down? When the broker is down? When a projection fails? |
| **Observability** | Can you trace an event through the entire system? Correlation IDs? |
| **Evolution** | How do you add new events? Modify existing ones? Remove deprecated ones? |
| **Testing** | How do you test sagas end-to-end? How do you test projections? |
| **Operational** | How do you replay events? Rebuild projections? Handle poison messages? |

## Output Format

```markdown
## Architecture Assessment
[Overall pattern usage, consistency model, main strengths and risks]

## Pattern Review
[For each pattern used: is it applied correctly? Anti-patterns detected?]

## Consistency & Failure Analysis
[What breaks under failure? What's the blast radius?]

## Recommendations
[Specific improvements with trade-off analysis]

## What's Done Well
[Good pattern choices, clean event design, proper error handling]
```
