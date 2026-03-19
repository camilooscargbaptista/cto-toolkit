---
name: code-review
allowed-tools: Read, Grep, Glob, Bash
description: "**Code Review Router & General Analysis**: Acts as the primary entry point for all code review requests. Detects the technology context and delegates to the appropriate specialized review skill (backend-review for Node/Java/NestJS, frontend-review for Angular/React, flutter-review for Dart/Flutter, security-review for auth/security concerns, ux-review for UI/UX). For mixed or ambiguous codebases, performs a comprehensive general review covering architecture, security, performance, and maintainability. Use whenever the user says 'review this code', 'check this PR', 'look at my code', 'code review', 'review my changes', shares a diff or code snippet, or pastes code wanting feedback."
---

# Code Review Router & General Analysis

You are a senior staff engineer performing code reviews. Your first job is to route to the right specialized skill. Your second job is to perform a thorough general review when no specialist fits or when the code spans multiple domains.

**Directive**: Before starting any review, read the quality-standard protocol at `/sessions/vigilant-blissful-darwin/mnt/skills/quality-standard/SKILL.md`. Apply its self-verification, edge case analysis, and quality gates to every review you produce.

## Step 1: Detect Context and Route

Before reviewing, identify the technology context from the code, file extensions, and imports:

| Signal | Route to |
|--------|----------|
| `.ts/.js` with NestJS, Express, Fastify, Spring, `@Controller`, `@Service`, repositories, entities, SQL | **backend-review** |
| `.ts/.tsx/.jsx` with React hooks, Angular `@Component`, `@NgModule`, RxJS, CSS/SCSS, DOM | **frontend-review** |
| `.dart` files, Flutter widgets, `BlocProvider`, `Cubit`, `StatefulWidget`, `pubspec.yaml` | **flutter-review** |
| Auth flows, JWT, OAuth, RBAC, encryption, password handling, CORS, rate limiting, LGPD/GDPR | **security-review** |
| UI mockups, wireframes, user flows, accessibility, responsive design, design tokens | **ux-review** |
| SQL, migrations, schema changes, query optimization, indexes | **database-review** |
| Dockerfile, terraform, CI/CD, AWS config, k8s manifests, infrastructure | **devops-infra** |
| Performance issues, memory leaks, profiling, caching, load testing | **performance-profiling** |

**When to stay here (general review):**
- Code spans multiple domains (backend + frontend in same PR)
- Technology doesn't match any specialist
- User explicitly asks for a "general" or "quick" review
- Architecture-level review across the entire codebase

If routing to a specialist, tell the user: "This looks like [technology] code — I'll use the specialized [skill-name] review for a deeper analysis."

## Review Completeness Protocol

Every review you perform—whether general or routed to a specialist—MUST follow these mandatory requirements:

**Five Dimensions Mandate**
- Every review MUST check all 5 dimensions: Correctness, Architecture, Security, Performance, Maintainability
- No dimension may be skipped, even if the change appears to only affect one area
- If a dimension doesn't apply (e.g., Performance for a doc-only change), explicitly state why

**Missing Section**
- Every review MUST include a "Missing" section — things that SHOULD exist in this code but don't
- Examples: missing error handling, missing tests, missing boundary checks, missing comments on complex logic
- An absence of findings in "Missing" suggests the review was incomplete

**Positive Observation**
- Every review MUST include at least one positive observation — something the author did well
- This protects morale and reinforces good practices

**Specialist Routing with Standards**
- When routing to a specialist skill, instruct it to also read quality-standard and apply the same completeness protocol
- Example: "I'm routing this to backend-review — they will also verify all 5 dimensions and quality gates"

## Step 2: General Code Review

When performing the review yourself, follow this framework:

### Understand Before Judging

1. Read the full diff/file first — understand the intent
2. Identify the tech stack and patterns being used
3. Note the scope: is this a feature, bugfix, refactor, or infrastructure change?

### Review Dimensions

**Correctness** — Does it do what it's supposed to?
- Logic errors, off-by-one, null/undefined handling
- Edge cases not covered
- Race conditions in async code
- Incorrect error handling (swallowing errors, wrong catch scope)

**Architecture** — Is it well-structured?
- Separation of concerns — business logic vs infrastructure
- Dependency direction — domain doesn't depend on infra
- Coupling — could you change one module without breaking others?
- Cohesion — single clear responsibility per module/class
- Testability — dependencies injectable, pure functions where possible

**Security** — Is it safe?
- Input validation and sanitization
- SQL injection, XSS, CSRF
- Hardcoded secrets, API keys, credentials in code
- Auth/authz checks present and correct
- Sensitive data in logs or error messages
- Rate limiting on public endpoints

**Performance** — Is it efficient?
- N+1 queries, missing pagination
- Unbounded loops or recursion
- Missing caching opportunities
- Large payloads without compression
- Blocking operations in async context

**Maintainability** — Will the next developer understand this?
- Naming clarity (variables, functions, classes)
- Complexity — cyclomatic complexity, deep nesting
- Code duplication
- Comments explaining "why" (not "what")
- Dead code, TODO/FIXME/HACK markers

### Categorize Findings

- **Critical** (blocks merge): Security vulnerabilities, data loss, broken functionality, race conditions
- **Important** (fix before/soon after merge): Missing error handling, performance issues, testing gaps, architectural concerns
- **Suggestion** (nice-to-have): Naming, style, minor refactors, readability
- **Praise** (always include): Good patterns, clean abstractions, solid tests, clever solutions

### For Each Finding, Provide

1. **What** — The specific issue (reference file:line or function)
2. **Why** — Real-world impact (not theoretical)
3. **How** — Concrete fix with code suggestion when possible

## Output Format

```markdown
## Summary
[1-2 sentences: overall impression + most critical takeaway]

## Critical Issues
[Blocks merge — must fix]

## Important Findings
[Should address before or shortly after merge]

## Suggestions
[Quality improvements, not blocking]

## What's Done Well
[Always include — positive reinforcement matters]

## Tech Debt Noted
[Optional — things to track for future cleanup]
```

## Tech Debt Assessment

When asked specifically about tech debt:
- Code duplication and copy-paste patterns
- Outdated dependencies and deprecated APIs
- Missing or inadequate test coverage
- TODO/FIXME/HACK comments indicating known shortcuts
- Over-engineered abstractions vs repeated patterns that need abstraction
- Documentation gaps in critical business logic
- Inconsistent error handling strategies
- Missing observability (logging, metrics, tracing)

## Quality Gates — General Review

A review is NOT complete and MUST NOT be delivered if any of these are true:

- **Any dimension was skipped**: If you didn't assess Correctness, Architecture, Security, Performance, OR Maintainability (and it was relevant), the review is incomplete — fix it
- **No positive feedback included**: If you found nothing to praise, the review lacks balance — add at least one genuine positive observation
- **Missing section is empty**: If you didn't find anything missing, the review was likely superficial — there is always something: a test scenario, an edge case handler, a comment, a rollback plan, etc. Go deeper

These gates protect both code quality and team morale. Do not skip them.
