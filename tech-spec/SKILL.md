---
name: tech-spec
description: "**Technical Specification Document**: Creates detailed technical specs (RFCs, design docs) for features, systems, and integrations. Use this skill whenever the user wants to write a tech spec, design doc, RFC, technical proposal, system design, or API specification. Also trigger when the user says 'spec out', 'design document', 'technical plan', 'how should we build', 'system design for', or wants to plan the implementation of a feature before coding. Trigger even for informal requests like 'I need to think through how to build X' or 'help me plan the architecture for Y'."
category: documentation
preferred-model: sonnet
min-confidence: 0.4
triggers: {}
depends-on: [design-patterns]
estimated-tokens: 5000
tags: [tech-spec, rfc, proposal, design-doc]
---

# Technical Specification Document

A tech spec is the bridge between "what we want to build" and "how we'll build it." It forces clarity before code is written, surfaces risks early, and creates alignment across the team.

**Quality Directive**: Before producing or reviewing a tech spec, read the [quality-standard](../quality-standard/SKILL.md) skill. Apply the **self-verification protocol** (completeness, precision, consistency, executability), **edge case prompting** (data, concurrency, failure modes, security, operational), and **anti-pattern awareness** (solutions without problems, hand-wavy security, optimistic migrations, missing error paths, hidden scope creep). Use the Spec Self-Review Checklist and Anti-Patterns sections at the end of this document before submitting specs for review.

## Spec Structure

```markdown
# [Feature/System Name] — Technical Specification

**Author**: [Name]
**Reviewers**: [Names]
**Status**: Draft | In Review | Approved | Implemented
**Created**: [Date]
**Last Updated**: [Date]

## 1. Overview
[2-3 sentences explaining what this is and why we're building it.
Should be understandable by any engineer on the team.]

## 2. Goals & Non-Goals

### Goals
- [What this project WILL accomplish — be specific and measurable]

### Non-Goals
- [What this project explicitly WILL NOT do — prevents scope creep]

## 3. Background
[Context needed to understand the design. Current system state,
user pain points, business requirements, relevant metrics.]

## 4. Detailed Design

### 4.1 Architecture Overview
[High-level diagram or description of how components interact.
Include a Mermaid diagram when helpful.]

### 4.2 Data Model
[Database schema changes, new tables/collections, key relationships.
Show the actual schema, not just prose descriptions.]

### 4.3 API Design
[New or modified endpoints. Include request/response examples.
For internal APIs, define the interface contract.]

### 4.4 Key Algorithms / Business Logic
[Any non-trivial logic that needs careful thought.
Pseudocode or flowcharts for complex flows.]

### 4.4 Error Handling

**MANDATORY: Error Handling Matrix**

| Error Type | Detection | Response | Recovery |
|---|---|---|---|
| [network timeout] | [how detected: timeout exception after X ms] | [immediate action: retry with exponential backoff] | [user experience: show timeout message after 3 retries] |
| [invalid input] | [how detected: validation schema fails] | [immediate action: log validation error, reject request] | [recovery: return specific error code to caller] |
| [database connection fail] | [how detected: connection pool exhaustion] | [immediate action: circuit breaker opens] | [recovery: fallback to read-only cache, escalate alert] |
| [auth failure] | [how detected: token validation fails] | [immediate action: reject request, log attempt] | [recovery: require fresh login, audit trail] |
| [rate limit exceeded] | [how detected: request count exceeds threshold] | [immediate action: queue or reject] | [recovery: backoff retry with jitter] |
| [external API slow] | [how detected: latency > p99 threshold] | [immediate action: timeout at X ms] | [recovery: degrade gracefully, use cached data if available] |

### 4.5 Data Flow Diagrams

**MANDATORY**: Provide at least one diagram showing:
- Input sources (user, API, events, scheduled jobs)
- Processing steps (validation, transformation, business logic, external calls)
- Output destinations (database, cache, queue, external API, user response)
- Where errors can occur and how they propagate
- Concurrency points and potential race conditions

Use Mermaid flowchart or sequence diagram format. Include in the diagram:
- The exact order of operations
- Which operations can fail independently
- What state is persisted at each step
- How partial failures are handled

## 5. Security Considerations

**MANDATORY: Security Checklist** — All items must be explicitly addressed (✓ implemented, or ○ N/A with justification):

- [ ] **Authentication**: Which services/endpoints require auth? What method (OAuth, JWT, API key, mutual TLS)? Token expiration and refresh? Service-to-service auth?
- [ ] **Authorization**: How are permissions checked? Role-based, attribute-based, or resource-based? Who decides access? IDOR prevention (can user A access user B's resource)?
- [ ] **Encryption**: Data at rest (database, cache, backups)? Data in transit (TLS version, certificate validation)? Key management (rotation, storage, access)?
- [ ] **Input Validation**: All untrusted inputs validated at trust boundary? Schema validation, type checking, length limits, format validation (regex)? SQL injection, XSS, command injection, template injection prevention?
- [ ] **PII Handling**: What is classified as PII (emails, phone, SSN, location, etc.)? Where is it stored? Who can access it? Retention policy? Anonymization/pseudonymization strategy?
- [ ] **Audit Logging**: Which actions are audited? What is logged (who, what, when, where, outcome)? Where are audit logs stored and how long retained? Who has access?
- [ ] **OWASP Top 10 Check**: A1 Broken Access Control, A2 Cryptographic Failures, A3 Injection, A4 Insecure Design, A5 Security Misconfiguration, A6 Vulnerable & Outdated Components, A7 Authentication Failures, A8 Data Integrity Failures, A9 Logging & Monitoring Failures, A10 SSRF. Which apply? How addressed?
- [ ] **Rate Limiting & Abuse Prevention**: Per-user, per-IP, or per-resource limits? Enforcement mechanism? Bypass or whitelisting logic?
- [ ] **Secrets Management**: How are credentials, API keys, database passwords stored? Never in code or environment variables without encryption. Use secret vault. Rotation policy?

## 6. Performance & Scalability

**MANDATORY: Load Estimation & Performance Targets** — All of the following must be populated with specific numbers:

### 6.1 Load & Capacity Planning

| Metric | Target | Rationale |
|---|---|---|
| **Expected RPS** | [e.g., 1,000 RPS peak] | [source: user growth forecast, production historical data] |
| **Concurrent Users** | [e.g., 10,000 concurrent] | [source: peak hour calculation] |
| **Data Volume** | [e.g., 1M records/day ingestion] | [source: growth rate, retention policy] |
| **Storage Required (Year 1)** | [e.g., 500 GB] | [source: average record size × volume × retention months] |

### 6.2 Latency & Throughput Targets

| Metric | Target | SLA |
|---|---|---|
| **p50 latency** | [e.g., 50 ms] | [e.g., 95% of requests] |
| **p99 latency** | [e.g., 200 ms] | [e.g., 99% of requests] |
| **Throughput (queries/sec)** | [e.g., 5,000 QPS] | [e.g., sustained] |
| **Error rate** | [e.g., < 0.1%] | [e.g., 99.9% availability] |

### 6.3 Database Query Performance

**MANDATORY**: For each critical query/operation, specify:
- Query pattern (SELECT/INSERT/UPDATE)
- Expected execution time ([e.g., < 10 ms](e.g., < 10 ms))
- Index strategy (which columns indexed)
- Estimated row scan count (prevent N+1, unbounded queries)
- Example query with EXPLAIN PLAN

**Minimum Requirements**:
- [ ] Max result set size per query (include LIMIT)
- [ ] Estimated query count per user request (prevent 10+ queries per endpoint)
- [ ] Caching strategy for expensive queries (TTL, invalidation)

### 6.4 Payload & Network Analysis

| Component | Size | Frequency | Impact |
|---|---|---|---|
| [e.g., user profile fetch] | [e.g., 5 KB] | [e.g., per request] | [e.g., 5 MB/sec at peak] |
| [e.g., image upload] | [e.g., max 10 MB] | [e.g., occasional] | [e.g., handled async] |

### 6.5 Caching Strategy

- [ ] What data is cached (queries, API responses, session data)?
- [ ] Cache TTL for each data type (seconds/minutes/hours)?
- [ ] Cache invalidation strategy (TTL expiry, event-driven, batch cleanup)?
- [ ] Cache key naming convention?
- [ ] Fallback if cache is unavailable?
- [ ] Estimated cache hit rate (%), memory footprint (MB)?

### 6.6 Bottleneck Analysis & Mitigation

- [ ] CPU-bound operations (optimization, parallelization)?
- [ ] I/O-bound operations (connection pooling, batching, async)?
- [ ] Database bottlenecks (indexing, partitioning, read replicas)?
- [ ] Network bottlenecks (compression, pagination, lazy loading)?
- [ ] Third-party API constraints (rate limits, SLA)?

## 7. Observability
[Key metrics to track, alerting thresholds, logging strategy,
dashboards needed, SLIs/SLOs if applicable.]

## 8. Migration / Rollout Plan
[How to deploy safely. Feature flags? Gradual rollout?
Database migration strategy? Backward compatibility?
Rollback plan if things go wrong?]

## 9. Testing Strategy
[Unit test approach, integration test plan, E2E scenarios,
load testing requirements, manual QA checklist.]

## 10. Dependencies & Risks

### 10.1 External Dependencies

| Service | Version | SLA | Fallback Strategy |
|---|---|---|---|
| [e.g., Stripe API] | [e.g., v1.2] | [e.g., 99.9%] | [e.g., queue for retry, manual review] |
| [e.g., Redis] | [e.g., 7.0] | [e.g., 99.95%] | [e.g., fallback to in-memory cache] |

### 10.2 Team Dependencies

| Team/Person | Dependency | Timeline | Risk |
|---|---|---|---|
| [e.g., Backend team] | [e.g., new API endpoint] | [e.g., 2 weeks] | [e.g., blocks our QA schedule] |
| [e.g., Database team] | [e.g., schema migration approval] | [e.g., 1 week] | [e.g., downtime window limited] |

### 10.3 Risk Matrix

**MANDATORY**: For each identified risk, populate all columns:

| Risk | Probability (H/M/L) | Impact (H/M/L) | Severity | Mitigation Strategy | Owner | Deadline |
|---|---|---|---|---|---|---|
| [e.g., Third-party API latency increases during peak traffic] | [e.g., M] | [e.g., H] | [e.g., HIGH] | [e.g., Implement circuit breaker, load testing with degraded API performance] | [e.g., @john] | [e.g., 2 weeks before launch] |
| [e.g., Database replication lag causes stale reads] | [e.g., L] | [e.g., H] | [e.g., MEDIUM] | [e.g., Read from primary for critical operations, eventual consistency acceptable for analytics] | [e.g., @jane] | [e.g., 1 week] |
| [e.g., New infrastructure requires capacity planning] | [e.g., H] | [e.g., M] | [e.g., MEDIUM] | [e.g., Provision 2x expected load, auto-scaling policy] | [e.g., @infra-team] | [e.g., 3 weeks] |
| [e.g., Security review uncovers critical issues] | [e.g., M] | [e.g., H] | [e.g., HIGH] | [e.g., Reserve time for fixes, early security review (2 weeks pre-launch)] | [e.g., @security] | [e.g., 4 weeks before launch] |

**Risk Scoring**:
- **CRITICAL**: H × H (blocks launch, immediate action required)
- **HIGH**: H × M or M × H (must be resolved before production)
- **MEDIUM**: M × M, H × L, or L × H (resolve before launch, monitor post-launch)
- **LOW**: M × L or L × M or L × L (document, monitor)

## 11. Timeline & Milestones
[Rough breakdown of work phases. Not a project plan —
just enough to show the scope is reasonable.]

## 12. Open Questions
[Things that still need answers. Tag the person who can answer.]

## Appendix
[Reference materials, benchmarks, research, related specs.]
```

## Writing Principles

- **Start with the "why."** The Overview and Background should convince the reader this work matters before diving into how.

- **Be precise about interfaces.** Anywhere two systems or teams interact, define the contract explicitly. Ambiguity in interfaces becomes bugs in production.

- **Show, don't tell.** Use code snippets, schema definitions, sequence diagrams (Mermaid), and concrete examples instead of vague descriptions.

- **Address the scary parts head-on.** The sections on security, performance, and migration are where most specs are weakest — and where most production incidents originate. Give them serious thought.

- **Non-goals are as important as goals.** They prevent scope creep and set clear expectations. If something is commonly assumed to be in scope but isn't, call it out as a non-goal.

- **Open questions are a feature, not a bug.** A spec that claims to have all the answers is suspicious. List unknowns explicitly and assign owners to resolve them.

## Adapting the Template

Not every spec needs every section. For a small feature, you might skip Migration Plan and Observability. For an API-only change, you might expand API Design and shrink Architecture Overview. Use judgment — the goal is to cover what matters for this specific project, not to fill in every heading.

For quick features (1-2 day implementations), use a lightweight version with just: Overview, Goals/Non-Goals, Design, and Testing Strategy.

---

## Spec Self-Review Checklist

**Before submitting a tech spec for review, verify every item below. If any item cannot be checked, the spec is incomplete.**

### Clarity & Completeness

- [ ] **Every interface between systems is explicitly defined** — No "TBD", "TBA", or "to be determined". Include request/response format, error codes, timeouts, retry behavior.
- [ ] **Error handling covers all failure modes** — At minimum: network failure, timeout, invalid input, authentication failure, rate limit, third-party API down, database unavailable.
- [ ] **Data model shows actual field names, types, and constraints** — Not just prose. Include exact schema (SQL DDL, Protobuf, JSON Schema). Show required vs. optional, defaults, validation rules.
- [ ] **Performance section has specific numbers** — RPS target, p99 latency, query count per request, payload sizes, cache TTL, storage requirements. No vague statements like "fast" or "scalable".
- [ ] **Migration plan has rollback strategy** — How to undo the change safely. Feature flags for gradual rollout? Backward compatibility with old clients? Data cleanup strategy?
- [ ] **At least 2 design alternatives were considered** — Document why option A was chosen over option B. Trade-offs explained.
- [ ] **Open questions have assigned owners and deadlines** — Not "TBD" or "TK". Specific person responsible, decision date, and escalation path if deadline is missed.

### Soundness & Rigor

- [ ] **Security checklist is complete** — Every item marked ✓ (implemented) or ○ (N/A with reason). No hand-wavy statements like "we'll handle security later".
- [ ] **Risk matrix is populated and prioritized** — Every identified risk has probability, impact, mitigation, owner, and deadline. Critical risks have mitigation plans started.
- [ ] **Caching strategy is explicit** — What is cached, TTL for each type, invalidation mechanism, fallback if cache is down. Or documented as "no caching used" with justification.
- [ ] **Load estimation is evidence-based** — RPS and concurrent user targets derive from actual metrics (growth rate, historical data, user research), not guesses.
- [ ] **Backward compatibility is addressed** — Old clients work with new API? Old data schema is readable by new code? Deprecation timeline if breaking change?
- [ ] **Observability is defined** — Metrics to track, alert thresholds, logging strategy (what gets logged, where), dashboards needed. SLIs/SLOs specified if this is a user-facing service.

### No Red Flags

- [ ] **No anti-patterns detected** — See "Anti-Patterns in Specs" section below. Spec does not exhibit: solution looking for problem, hand-wavy security, optimistic migration, missing error paths, hidden scope creep.
- [ ] **No vague language remains** — Replaced all "should", "might", "consider", "probably", "hopefully" with specific actions or conditional logic (if X then Y).
- [ ] **No unresolved dependencies** — All external service, API, or team dependencies documented in section 10, with owner and deadline.
- [ ] **No TBDs left unsigned** — Every "to be decided" has a responsible person and deadline, or has been resolved.
- [ ] **Scope creep is explicitly managed** — Non-goals section clearly states what is NOT included. If anyone has assumed something is in scope, verify it's either a goal or a documented non-goal.

### Readability & Executability

- [ ] **A mid-level engineer can execute this spec without asking clarifying questions** — All steps are clear, all file paths are exact, all API contracts are complete, all schema changes are shown (not inferred).
- [ ] **Diagrams are present where needed** — Architecture diagram, data flow, sequence diagram for complex flows, or ER diagram for schema changes. Mermaid is acceptable.
- [ ] **Code examples are provided for non-obvious logic** — Pseudocode, SQL, JSON, configuration samples where execution would be ambiguous from text alone.
- [ ] **Terminology is consistent throughout** — Same concept always called by the same name. No switching between "user", "customer", "account" without explicit relationship.

---

## Anti-Patterns in Specs

**Flag these when detected in a spec. They are warning signs of incomplete or flawed thinking.**

### 1. "Solution Looking for a Problem"

**Signal**: The spec jumps to an implementation without clearly stating user pain.

**Bad Example**:
> "We will implement a microservice to handle payment processing, using event sourcing and CQRS pattern."

**Problem**: Why? What user problem does this solve? Why not keep payments in the monolith?

**Fix**: Start with background. "Currently, payment processing blocks the checkout flow, causing 10% of users to abandon. P99 latency is 5 seconds. Goal: P99 latency < 500ms."

**Check**:
- [ ] Section 3 (Background) clearly states the user pain point or business problem
- [ ] The design in section 4 directly addresses that pain
- [ ] Why this solution over alternatives is explained

---

### 2. "Hand-Wavy Security"

**Signal**: Security section uses vague language like "secure", "encrypt", "safe", "authentication will be handled".

**Bad Example**:
```
## 5. Security
We will use secure authentication and encrypt sensitive data.
PII will be protected according to compliance requirements.
```

**Problem**: None of this is checkable or implementable. What auth method? What encryption algorithm? Which compliance requirement?

**Fix**: Use the security checklist (Section 5 above). Every item explicitly addressed:
```
- [✓] Authentication: OAuth 2.0 with JWT tokens, exp 1 hour
- [✓] PII: Emails and phone numbers encrypted at rest (AES-256),
        audit log tracks access, GDPR deletion on user request
- [✓] OWASP A1: All user IDs in URLs validated against session principal
```

**Check**:
- [ ] Security section uses the mandatory checklist
- [ ] Every item is ✓ (implemented, with specifics) or ○ (N/A, with reason)
- [ ] No use of words like "secure", "safe", "proper", "appropriate" without specifics
- [ ] Every encryption mention includes algorithm (AES-256, SHA-256, etc.)
- [ ] Every auth mention includes method (OAuth, JWT, mTLS, API key) and lifetime

---

### 3. "Optimistic Migration"

**Signal**: Migration plan lacks rollback strategy, assumes no data loss, or has no backward compatibility plan.

**Bad Example**:
> "We will migrate the user_profiles table to a new schema. Old code will be updated to use the new schema."

**Problem**: What if migration fails halfway? What if new code has a bug? How do you roll back?

**Fix**: Section 8 (Migration) includes:
- **Rollback plan**: "If migration fails, we revert schema change and redeploy old code. Data in new columns ignored until next attempt. Estimated rollback time: 10 minutes."
- **Backward compatibility**: "Old code reads from old columns. New code writes to both old and new columns for 2 weeks (compatibility window), then new code switches to new columns only."
- **Testing**: "Canary rollout to 5% of users first, monitor error rates for 24 hours, then 25%, 50%, 100%."

**Check**:
- [ ] Rollback procedure is documented step-by-step with estimated recovery time
- [ ] Backward compatibility window is specified (weeks, months) and justified
- [ ] Feature flags or canary strategy is in place
- [ ] Data validation plan (how to verify migration succeeded)
- [ ] Replication lag or dual-write consistency strategy if applicable

---

### 4. "Missing Error Paths"

**Signal**: Design only describes the happy path. Failure modes are not designed.

**Bad Example**:
> "When the user submits the form, we call the payment API and charge the card."

**Problem**: What if the payment API is down? What if it times out after 30 seconds? What if the request is sent twice (duplicate charge)? No design for these.

**Fix**: Section 4.5 (Error Handling Matrix) covers all scenarios:

| Error | Detection | Response | Recovery |
|---|---|---|---|
| Payment API timeout | No response after 5 sec | Timeout exception → return 500 | Retry with exponential backoff; user retries on next request |
| Duplicate request | Idempotency key matches | Detect in DB before calling API | Return cached response from first attempt |
| Invalid card | API returns 400 | Log validation error, return to user | User corrects card and retries |

**Check**:
- [ ] Error Handling Matrix (section 4.5) includes at least: timeout, network failure, invalid input, auth failure, rate limit, 3rd party down
- [ ] Each error has: how it's detected, what happens immediately, what happens for user recovery
- [ ] Idempotency strategy for any operation that could be retried
- [ ] Circuit breaker or bulkhead for external API calls
- [ ] No mention of "this shouldn't happen" (defensive design assumes anything can fail)

---

### 5. "Scope Creep in Disguise"

**Signal**: Non-goals section is missing, empty, or vague. Features slip into scope throughout the doc.

**Bad Example**:
```
## 2. Goals & Non-Goals

### Goals
- Improve user experience

### Non-Goals
- (empty)
```

**Problem**: What does "improve" mean? What specifically is NOT included? Scope is undefined and will creep.

**Fix**: Be specific:
```
### Goals
- Reduce checkout latency from 5 sec (p99) to < 500 ms (p99)
- Support up to 10,000 concurrent users
- Maintain 99.95% uptime SLA

### Non-Goals
- We will NOT redesign the checkout UI (separate project)
- We will NOT add new payment methods (deferred to Q3)
- We will NOT implement recurring billing (separate project)
- We will NOT support 3D Secure authentication (not MVP)
```

**Check**:
- [ ] Goals section has measurable, specific targets (numbers, latency, throughput, uptime)
- [ ] Non-goals section explicitly lists commonly-assumed features that ARE NOT included
- [ ] No goals mentioned in any other section that aren't in section 2
- [ ] Non-goals are tested against design decisions: if feature X appears in section 4 and is not in goals, it's either a goal or should be removed

---

### Summary: How to Avoid These Anti-Patterns

1. **Start with pain**: Background and Goals sections make the "why" crystal clear before any design.
2. **Be specific**: Numbers, not adjectives. Algorithms, not buzz words. Implementation details, not hand-waving.
3. **Design for failure**: Every external dependency, every user interaction, every data transition has an error case.
4. **Plan the migration**: Rollback strategy is always included, backward compatibility is always considered, testing is always detailed.
5. **Bound the scope**: Non-goals are as important as goals. Anything not explicitly a goal should be a non-goal.
