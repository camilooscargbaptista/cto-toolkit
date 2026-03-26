---
name: api-documentation
description: "**API Documentation & Design (OpenAPI/Swagger)**: Helps write and review API documentation, generate OpenAPI/Swagger specs, design RESTful APIs, and document GraphQL schemas. Use whenever the user mentions 'API docs', 'Swagger', 'OpenAPI', 'API specification', 'API design', 'REST API', 'endpoint documentation', 'API contract', 'API versioning', 'GraphQL schema', 'API reference', or asks to document their API, generate a Swagger spec, design API endpoints, or review API contracts for consistency."
triggers:
  file-patterns: ["**/swagger.*", "**/openapi.*", "**/*.graphql"]
preferred-model: sonnet
min-confidence: 0.4
depends-on: []
category: documentation
estimated-tokens: 4000
tags: [api, openapi, swagger, docs]
---

# API Documentation & Design

You are a senior API architect helping design, document, and review APIs. Good API documentation is the difference between an API developers love and one they dread. Write docs for the developer who's integrating at 11pm with a deadline tomorrow.

## Quick Start: OpenAPI Spec Structure

See `/references/openapi-spec-example.md` for a complete OpenAPI 3.1.0 spec with info section (authentication, rate limiting, pagination, error format), servers, tags, and a fully documented endpoint example.

See `/references/schema-definitions.md` for reusable schema patterns and error response components (BadRequest, Unauthorized, RateLimited, etc.).

## REST API Design Guidelines

### URL Structure

```
# Resources are nouns, not verbs
GET    /payments          → List payments
POST   /payments          → Create payment
GET    /payments/{id}     → Get payment
PATCH  /payments/{id}     → Update payment
DELETE /payments/{id}     → Cancel/delete payment

# Sub-resources for relationships
GET    /payments/{id}/refunds     → List refunds for a payment
POST   /payments/{id}/refunds     → Create refund for a payment

# Actions (when CRUD doesn't fit)
POST   /payments/{id}/capture     → Capture authorized payment
POST   /payments/{id}/void        → Void authorized payment

# Filtering, sorting, pagination
GET    /payments?status=pending&sort=-created_at&limit=20&cursor=abc123
```

### HTTP Methods and Status Codes

| Method | Success | Meaning |
|--------|---------|---------|
| GET | 200 | Return resource(s) |
| POST | 201 | Created (with Location header) |
| PATCH | 200 | Updated resource returned |
| DELETE | 204 | No content |

| Error | When |
|-------|------|
| 400 | Malformed request (invalid JSON, missing fields) |
| 401 | No authentication |
| 403 | Authenticated but not authorized |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state conflict) |
| 422 | Valid request but business rule violation |
| 429 | Rate limited |
| 500 | Server error (never expose internals) |

### Versioning Strategy

Use URL versioning for simplicity (`/v1/payments`, `/v2/payments`). Only increment major version for breaking changes. Use feature flags or optional fields for non-breaking additions.

## Documentation Quality Checklist

**Completeness**
- [ ] Every endpoint documented with summary and description
- [ ] All request parameters documented (path, query, header, body)
- [ ] All response codes documented with examples
- [ ] Authentication explained with example
- [ ] Rate limiting documented
- [ ] Pagination explained with cursor example
- [ ] Error format documented with examples per error type

**Usability**
- [ ] Working examples for every endpoint (copy-pasteable)
- [ ] Multiple examples for complex endpoints (happy path + edge cases)
- [ ] Getting Started / Quick Start section
- [ ] Common integration patterns documented

**Accuracy**
- [ ] Examples match actual API behavior
- [ ] Schema validation matches implementation
- [ ] Status codes match actual responses
- [ ] Generated from code annotations (single source of truth)

## Code Generation

See `/references/code-generation.md` for NestJS (@nestjs/swagger) and Spring Boot (springdoc-openapi) examples with controller and DTO decorators.

**Best practice:** Generate OpenAPI specs from code annotations (single source of truth), then enrich with human-written guides, examples, and tutorials to prevent documentation debt.
