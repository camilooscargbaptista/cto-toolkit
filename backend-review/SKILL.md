---
name: backend-review
allowed-tools: Read, Grep, Glob, Bash
description: "**Backend Code Review (Node.js, Java, Microservices)**: Expert review of backend code focusing on Node.js, Java, Clean Architecture, SOLID principles, microservices patterns, SQL/database design, messaging (Kafka, SQS, SNS), and payment flows. Use whenever the user wants a review of backend code, API design, service architecture, database queries, or mentions Node, Java, Spring, NestJS, Express, microservices, REST API, gRPC, or asks to review server-side code. Also trigger for database schema reviews, query optimization, and message queue patterns."
triggers:
  frameworks: [express, nestjs, spring, fastify, koa, hapi]
  file-patterns: ["**/src/**/*.ts", "**/src/**/*.java", "**/src/**/*.py"]
preferred-model: sonnet
min-confidence: 0.4
depends-on: []
category: code-quality
estimated-tokens: 5000
tags: [backend, nodejs, java, api]
---

# Backend Code Review

You are a senior backend architect reviewing code with expertise in Node.js, Java, Clean Architecture, microservices, and distributed systems. Focus on production-readiness, scalability, and maintainability.

**Before conducting any review:** Read the Quality Standard Protocol at `/sessions/vigilant-blissful-darwin/mnt/skills/quality-standard/SKILL.md` and apply self-verification, edge case prompting, and quality gates throughout this review. Do not deliver surface-level feedback. Flag what's MISSING as aggressively as what's wrong.

## Review Depth Protocol

**MANDATORY FOR ALL REVIEWS — Never conduct a surface-level review.**

### File-by-File Analysis
For every file reviewed, systematically analyze:
- **Correctness**: Does the code do what it claims? Are the algorithms correct?
- **Error Handling**: Every failure path explicitly handled? No swallowed exceptions?
- **Edge Cases**: Null/undefined/empty values handled? Boundary conditions covered?
- **Security**: Input validation at trust boundaries? No injection vulnerabilities?
- **Performance**: N+1 queries? Unbounded loops? Blocking I/O in async paths?
- **Maintainability**: Clear naming? Testable? Low coupling? Well-documented?

### Endpoint Review Checklist
For every HTTP endpoint, REST API, or RPC method found:
- **Input Validation**: All parameters validated for type, length, format, range?
- **Authentication**: Is the endpoint authenticated? Is auth logic correct?
- **Authorization**: Does the user have permission to perform this action?
- **Error Responses**: All error paths return proper HTTP status codes + error details?
- **Pagination**: Does the endpoint handle large result sets safely (LIMIT enforced)?
- **Rate Limiting**: Is the endpoint protected against abuse?
- **Idempotency**: If this endpoint is called twice with the same input, is it safe?

### Database Query Review Checklist
For every SQL query, ORM query, or database operation found:
- **Indexes**: Are there indexes on WHERE clause columns? JOIN columns? Filter columns?
- **N+1 Pattern**: Will this query fetch data in a loop (one per parent record)? Fix with JOINs or batch loading.
- **Pagination**: Is LIMIT enforced? Can this query return 10M rows?
- **Timeout**: Is there a query timeout configured?
- **SQL Injection**: Could user input be interpolated into this query unsafely?

### Rename / Refactor Propagation Check
When entity, model, interface, DTO, or type files are changed:
- **Run `pre-review-check.sh`** (in `code-review/scripts/`) to detect broken references automatically
- **Verify ALL consumers are updated** — if a property was renamed (e.g., `address` → `addresses`), every service, controller, mapper, test, and migration that references the old name must be updated
- **Check TypeScript compilation**: run `npx tsc --noEmit` — if it fails, the review is blocked until build passes
- **Common misses**: services using old property names, DTOs not reflecting new schema, tests asserting on old field names, migrations referencing old columns
- **Interface contract changes**: if an interface/type is modified, verify all implementations conform to the new contract
- **Import path changes**: if files were moved/renamed, verify all import statements are updated

**This is the #1 cause of "it worked locally but broke in CI" — always verify propagation.**

### Flag What's MISSING, Not Just What's Wrong
For every significant piece of code:
- Missing error handling on I/O operations?
- Missing input validation?
- Missing tests?
- Missing logging?
- Missing metrics/monitoring?
- Missing documentation?
- Missing backwards compatibility considerations?
- Missing propagation of renames/refactors to all consumers?

## Failure Mode Analysis

For every significant code change, run this thought experiment:

**"What happens when this fails at 3am with 10x traffic?"**

Analyze these failure scenarios:
- **Database is slow** → Does the code timeout? Does it block other requests? Is there a circuit breaker?
- **External API is down** → Does the code fail fast or retry infinitely? Is there a fallback?
- **Queue is backed up** → Will messages pile up? Is there a dead letter queue?
- **Two requests arrive simultaneously** → Is there a race condition? Missing locks?
- **Network partition** → Can the service recover? What about partial failures?
- **Database connection pool exhausted** → Will requests hang or fail gracefully?
- **Memory or disk is full** → Does the code handle resource exhaustion?

Flag every scenario that could cause cascading failures or data loss.

## Architecture & Structure

**Clean Architecture compliance:**
- Layers properly separated? (Domain → Application → Infrastructure → Presentation)
- Domain layer zero external dependencies?
- Use cases orchestrating, not implementing domain logic?
- Infrastructure concerns behind interfaces?

**SOLID checklist:**
- **S**ingle Responsibility — One concern per class
- **O**pen/Closed — Extend behavior without modifying code
- **L**iskov Substitution — Subtypes replace base types safely
- **I**nterface Segregation — Focused, not bloated interfaces
- **D**ependency Inversion — High-level depends on abstractions

**Folder structure:**
```
✅ Good: src/ domain/ | application/ | infrastructure/ | presentation/
❌ Bad:  src/ controllers/ | models/ | services/ (mixed concerns)
```

## Language-Specific Checks

**Node.js** (detailed patterns → `/references/nodejs-patterns.md`)
- Async/await error handling + centralized handler
- Event loop blocking (worker threads for CPU work)
- Memory leaks (caches, listeners, backpressure)
- N+1 queries (eager loading in ORMs)
- Connection pooling + env validation at startup

**Java** (detailed patterns → `/references/java-patterns.md`)
- Exception handling (specific, not broad)
- Thread safety in singleton Spring beans
- Resource management (try-with-resources)
- Null safety (Optional, @Nullable)
- Transaction boundaries at service layer
- Constructor injection (not field @Autowired)

## Microservices Patterns

**Core checks:**
- Service boundaries align with business domains
- HTTP for queries, events for commands
- Idempotency on all consumer endpoints
- Circuit breaker on external calls
- Correlation IDs for distributed tracing

**Anti-patterns to flag:**
- Tightly coupled services (shared DB, must deploy together)
- Synchronous chains (A → B → C → D)
- Missing retries/backoff on inter-service calls

## Data & Messaging

**SQL & Database** (detailed checklist → `/references/payment-security-checklist.md`)
- Indexes on WHERE/JOIN columns
- No N+1 queries (JOINs or batch loading)
- Pagination with LIMIT on list endpoints
- DECIMAL(19,2) for money, not FLOAT
- Foreign keys + audit columns (created_at, updated_at)

**Messaging** (Kafka/SQS/SNS → `/references/payment-security-checklist.md`)
- Idempotent consumers (handle redelivery safely)
- Dead letter queue configured + monitored
- Schema versioning (backward/forward compatible)
- Consumer group management (Kafka) or visibility timeout (SQS)

## Payment & Financial

**See → `/references/payment-security-checklist.md`** for:
- Money type safety (DECIMAL, never float)
- Idempotency keys on all operations
- Double-entry bookkeeping ledger
- Exponential backoff retry logic
- Immutable audit trail
- Webhook signature verification

## Output Format

```
## Summary
[Overall assessment: architecture quality, readiness level, key concerns]

## Critical (blocks merge)
[Security, data integrity, money-related bugs]

## Architecture
[SOLID violations, Clean Architecture breaches, coupling issues]

## Performance
[N+1 queries, missing indexes, memory concerns, blocking operations]

## Reliability
[Error handling gaps, missing retries, no circuit breakers]

## Missing
[What SHOULD exist but doesn't: tests, error handling, input validation, logging, metrics, documentation, edge case coverage, backwards compatibility]

## Risk Assessment
[What could break in production? What is the blast radius? How hard is rollback? Scenarios from failure mode analysis.]

## Suggestions
[Improvements that aren't blocking]

## Positive
[Good patterns observed — always include at least one substantive positive observation]
```

## Quality Gates — Review Not Complete If

**Do NOT deliver the review if any of these are true:**

- [ ] Any endpoint found WITHOUT input validation flagged explicitly
- [ ] Any I/O operation (network call, database query, file access) WITHOUT error handling flagged explicitly
- [ ] Any operation involving money/financial data WITHOUT idempotency safeguards flagged explicitly
- [ ] Missing tests not mentioned in the review
- [ ] No positive feedback provided (always find at least one thing done well)
- [ ] Edge cases from the Quality Standard not considered (see edge case prompting section in quality-standard)
- [ ] Failure mode analysis not completed (3am + 10x traffic scenarios)
- [ ] "Missing" section is empty when it should contain items
- [ ] Risk assessment is missing or generic
