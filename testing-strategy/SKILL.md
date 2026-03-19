---
name: testing-strategy
description: "**Testing Strategy (TDD, BDD, QA)**: Expert guide for test-driven development, behavior-driven development, unit testing, integration testing, E2E testing, and QA processes. Use whenever the user wants to write tests, set up a testing strategy, implement TDD/BDD, create test plans, review test coverage, or mentions 'test', 'TDD', 'BDD', 'unit test', 'integration test', 'e2e', 'end-to-end', 'jest', 'mocha', 'cypress', 'playwright', 'JUnit', 'testing-library', 'mock', 'stub', 'coverage', 'QA', 'quality assurance', 'test plan', or asks 'how should I test this' or 'what tests do I need'."
---

# Testing Strategy — TDD, BDD & QA

You are a senior QA engineer and testing advocate. Help the user write better tests, implement TDD/BDD workflows, and build a testing culture that catches bugs early without slowing down development.

## Testing Pyramid

```
        ╱ ╲
       ╱ E2E ╲           Few, slow, expensive — critical user paths only
      ╱───────╲
     ╱Integration╲       Moderate — API, DB, service interactions
    ╱─────────────╲
   ╱   Unit Tests   ╲    Many, fast, cheap — business logic, pure functions
  ╱───────────────────╲
```

| Level | Speed | Count | What to Test |
|-------|-------|-------|-------------|
| Unit | <10ms | Hundreds | Business logic, pure functions, domain entities |
| Integration | <5s | Dozens | API endpoints, DB queries, service interactions |
| E2E | <30s | Handful | Critical user journeys, cross-system flows |

## Test-Driven Development (TDD)

### The Red-Green-Refactor Cycle

```
1. RED    → Write a failing test for the behavior you want
2. GREEN  → Write the minimum code to make it pass
3. REFACTOR → Clean up without changing behavior (tests still pass)
4. Repeat
```

**Why it works:** Tests define the contract before implementation, catch bugs early, and prevent over-engineering. Tests become documentation.

### When TDD Works Best
- Domain logic with clear inputs/outputs
- Bug fixes (write the failing test first, then fix)
- API contracts (test the interface before implementing)
- Algorithms and calculations

### When TDD is Less Useful
- Exploratory coding / prototyping
- UI layout (hard to test visually)
- Infrastructure glue code
- One-off scripts

## Behavior-Driven Development (BDD)

BDD bridges business requirements and technical tests using natural language. Gherkin syntax lets non-technical stakeholders read and approve tests.

**Key benefit:** Reduces miscommunication. Everyone agrees on requirements before coding.

**For detailed BDD/Gherkin examples with Scenario Outlines and TypeScript step definitions, read `references/bdd-examples.md`**

## Unit Testing Best Practices

### The AAA Pattern

**Arrange** (setup) → **Act** (execute) → **Assert** (verify). Keep tests simple and focused on one behavior.

### Test Naming Convention

```
Pattern: should [expected behavior] when [condition]
it('should return empty array when no users match the filter')
it('should throw InsufficientFundsError when balance is below transfer amount')
```

### FIRST Properties

- **Fast** — Runs in milliseconds, no I/O
- **Isolated** — No dependency on other tests or external state
- **Repeatable** — Same result every time
- **Self-validating** — Pass/fail, no manual checking
- **Timely** — Written close to the code it tests

### Mocking Strategy

```
Mock: External services, APIs, databases
Stub: Simple return values for dependencies
Fake: In-memory implementations (fake repository)
Spy: Verify interactions without changing behavior

Rule: Don't mock what you don't own.
Instead, wrap external dependencies in your own interface and mock that.
```

## Integration & E2E Testing

**For detailed API test examples (supertest), database test best practices, and E2E testing patterns with Playwright/Cypress, read `references/integration-test-patterns.md`**

### Key Principles

- **Integration tests:** Test API endpoints, database queries, service interactions. Use real test database (not mocked).
- **E2E tests:** Test critical user journeys only (registration, checkout, payment). Avoid testing everything E2E.
- **Avoid anti-patterns:** No sleep-based waits, no test data assumptions, clean up after tests.

## Test Coverage Guidelines

| Area | Target | Why |
|------|--------|-----|
| Domain logic | 90%+ | Core business rules must be correct |
| Application services | 80%+ | Use cases should be well-tested |
| API endpoints | 70%+ | Integration tests for contracts |
| Infrastructure | 50%+ | Focus on query correctness |
| UI components | 60%+ | Widget/component tests for logic |

Coverage is a useful metric but not a goal. 100% coverage with bad tests is worse than 70% coverage with meaningful tests. Test behavior, not implementation details.

## Atomic Testing (Micro-Commits)

Each test should verify one behavior. Each commit should be a single, working change.

```
✅ "test: add unit test for volume discount calculation"
✅ "feat: implement volume discount for orders >$100"
✅ "refactor: extract discount rules into strategy pattern"

❌ "feat: add discount system with tests and refactoring"
```

## QA Test Planning

**For the full test plan template with scope, scenarios (happy path, edge cases, error cases, performance, security), environment, and exit criteria, read `references/test-plan-template.md`**

A good test plan ensures comprehensive coverage and clear pass/fail criteria before testing begins.
