---
name: sprint-planning
description: "**Sprint & Release Planning**: Helps with sprint planning, backlog grooming, story estimation, release planning, and roadmap creation. Use this skill whenever the user wants to plan a sprint, groom the backlog, write user stories, estimate tasks, plan a release, create a roadmap, prioritize features, or structure a planning meeting. Trigger when the user mentions 'sprint', 'backlog', 'story points', 'estimation', 'velocity', 'roadmap', 'release plan', 'prioritization', 'epic', 'user story', or asks about how to organize upcoming work."
category: management
preferred-model: sonnet
min-confidence: 0.4
triggers: {}
depends-on: [engineering-metrics]
estimated-tokens: 3000
tags: [sprint, planning, agile, scrum, estimation]
---

# Sprint & Release Planning

This skill helps you run effective planning processes — from writing good user stories to building quarterly roadmaps. Adapt the level of formality to your team's size and culture.

**Before producing any planning output, read `../quality-standard/SKILL.md` and apply its self-verification protocol, decomposition rules, and edge case prompting.**

## User Story Writing

A well-written story communicates intent without over-prescribing implementation. Every story MUST be production-ready with no ambiguity or missing acceptance criteria.

### Format
```
As a [type of user],
I want to [action/capability],
so that [benefit/value].
```

### Mandatory Story Requirements

Every story MUST include ALL of the following before it enters a sprint:

1. **Acceptance Criteria (minimum 3 scenarios)** in Given-When-Then format
   - Happy path scenario (the normal case)
   - At least one error/failure scenario
   - At least one edge case or boundary scenario

2. **Definition of Done checklist** (concrete, testable items)
   - Code reviewed
   - Tests written and passing
   - Acceptance criteria verified
   - Documentation updated
   - No console errors/warnings
   - (Add team-specific items)

3. **Dependencies** (explicit list)
   - Other stories that must complete first
   - External APIs or services required
   - Data or configuration changes needed
   - Third-party integrations

4. **Estimated Complexity** (S/M/L or story points)
   - Use Fibonacci: 1, 2, 3, 5, 8, 13
   - If >8, story is too large — split it

5. **Story Quality Checklist (INVEST)**
   - **I**ndependent — Minimal coupling to other stories
   - **N**egotiable — Implementation approach is flexible
   - **V**aluable — Delivers measurable user or business value
   - **E**stimable — Team can estimate within a confidence range
   - **S**mall — Completable in ≤1 sprint
   - **T**estable — Acceptance criteria are verifiable

### Complete Example: Add PIX Payment Method

```
Title: Add PIX payment method to checkout flow

As a Brazilian customer,
I want to pay with PIX at checkout,
so that I can use my preferred, instant payment method without credit card fees.

## Acceptance Criteria

### Happy Path
Given a customer with a valid PIX key in their payment methods,
When they select PIX at checkout and complete the payment flow,
Then the payment processes instantly, they receive an order confirmation email
within 2 minutes, and the order status shows "Paid" in their account.

### Error Case: Invalid PIX Key
Given a customer enters an invalid PIX key during payment,
When they submit the payment form,
Then the system displays "Invalid PIX key format" error message,
highlights the input field in red, and suggests the correct format (email, phone, CPF, or random key).

### Edge Case: Duplicate Payment Attempt (Race Condition)
Given a customer has submitted a PIX payment but clicks "Submit" again immediately,
When the system processes both requests concurrently,
Then only one charge is applied, a duplicate prevention lock is acquired,
and the customer is informed "Payment already processing—do not refresh."

### Boundary Case: Large Transaction Amount
Given a customer attempts to pay R$50,000 via PIX,
When the transaction exceeds the PIX single-transfer limit (R$4,992),
Then the system displays "Amount exceeds PIX limit" and offers to split into multiple transfers
or suggests alternative payment methods.

### Boundary Case: Very Quick Payment
Given a customer completes PIX payment verification in <100ms,
When the webhook callback arrives from the payment processor,
Then the order status updates to "Paid" without race conditions
and the confirmation email is queued correctly.

## Definition of Done
- [ ] PIX payment method integrated with payment processor (Stripe/PagSeguro/equivalent)
- [ ] Checkout UI updated to show PIX as option with logo
- [ ] All 5 acceptance criteria scenarios tested (manual + automated)
- [ ] Idempotency keys implemented to prevent duplicate charges
- [ ] Webhook handler for payment status updates tested with 50+ mock scenarios
- [ ] Error messages user-friendly and match brand tone
- [ ] No console errors/warnings in Chrome DevTools
- [ ] Documentation updated: README, API docs, payment flow diagram
- [ ] Database migrations tested on staging
- [ ] Metrics added: PIX transaction success rate, average completion time
- [ ] Backwards-compatible with existing payment methods
- [ ] Security review: no sensitive PIX keys stored in logs
- [ ] Load tested with 100+ concurrent PIX transactions

## Dependencies
- Payment processor account with PIX support enabled
- Webhook signing key from payment provider
- Legal/compliance review (PIX is regulated in Brazil)
- Frontend form validation library already in place
- Database schema supports new `payment_method` type

## Estimated Complexity
M (5 story points)
- Medium because: new payment provider integration + webhook handling + race condition handling
- Not small due to concurrency complexity
- Not large because PIX API is simpler than some alternatives
```

### Good vs Bad Stories

**Bad**: "Implement search functionality" (no acceptance criteria, no scope bounds)
**Good**: "As a customer, I want to search products by name and category, so that I can quickly find what I'm looking for."

**Bad**: "Fix the login bug" (vague, no reproduction steps)
**Good**: "As a user who forgot their password, I want the reset email to arrive within 2 minutes, so that I'm not stuck waiting (currently takes 10+ minutes due to queue backlog)." + acceptance criteria for timing, error cases, and delivery confirmation.

## Task Decomposition

Once a story is accepted, break it into concrete tasks. Every task must be independently executable, testable, and completable in ≤4 hours.

### Task Format

```
Task ID: [T1], [T2], etc.
Task: [Imperative verb] [specific action]
File(s): [Exact paths of files to create or modify]
Details: [Step-by-step implementation instructions]
Acceptance: [How to verify this task is complete — includes test commands]
Depends on: [List of task IDs this depends on, or "none"]
```

### Decomposition Rules

- **Max 4 hours per task** — If it takes longer, split it
- **Each task is independently testable** — Can be verified without waiting for dependent tasks
- **Clear input → output** — Task specifies exactly what goes in and what comes out
- **Ordered by dependency** — List tasks so prerequisites are done first
- **No "figuring out"** — If you're unsure how to do it, that's a separate spike task

### Spike / Investigation Task Format

When uncertainty exists, create a spike BEFORE the implementation task:

```
Spike: Investigate [specific question]
Timebox: [hours, typically 2-4]
Output: [what the spike produces — decision doc, PoC, test results]
Decision Criteria: [what determines which path forward you take]
```

### Complete Example: PIX Payment Method Task Breakdown

For the story "Add PIX payment method to checkout flow" (5 points), here's the task decomposition:

```
## Spike: Investigate PIX Rate Limiting and Webhook Security
Timebox: 3 hours
Output: Decision document on webhook signature verification, rate limit handling, and idempotency strategy
Decision Criteria:
  - Can we use payment processor's webhook library, or must we implement custom signature validation?
  - What is the max request retry frequency from the payment processor?
  - Should idempotency keys be stored in Redis or database?

## Task T1: Create PIX Payment Method Database Schema
Task: Add PIX payment method type to database schema
File(s):
  - migrations/[timestamp]_add_pix_payment_method.sql
  - app/models/payment_method.py (or equivalent)
Details:
  1. Add enum value "pix" to payment_method_type column (if not exists)
  2. Add pix_key column (string, 255 chars, indexed)
  3. Add pix_key_type column (enum: email, phone, cpf, random_key)
  4. Add webhook_idempotency_key column for deduplication
  5. Run migration against local dev database
  6. Verify schema with `\d payment_methods` or equivalent
Acceptance:
  - Migration runs without errors
  - Schema includes all 4 new columns
  - Indexes created on pix_key and idempotency_key
Depends on: none

## Task T2: Integrate Payment Processor PIX API Client
Task: Implement PIX payment processor API client with idempotency
File(s):
  - app/services/payment_processor_client.py
  - tests/unit/test_payment_processor_client.py
Details:
  1. Add PIX charge creation method: `create_pix_charge(amount, pix_key, idempotency_key)`
  2. Implement exponential backoff retry logic (max 3 retries, 1s→2s→4s)
  3. Add request/response logging (no sensitive keys in logs)
  4. Implement idempotency header per payment processor's spec
  5. Unit test: successful charge creation
  6. Unit test: payment processor API returns 500 (verify retry logic)
  7. Unit test: duplicate request with same idempotency key (verify no double-charge)
Acceptance:
  - All unit tests passing
  - No API keys or sensitive data in logs
  - Integration test creates real test charge on staging API
Depends on: T1

## Task T3: Implement Webhook Handler for PIX Payment Confirmation
Task: Build secure webhook endpoint to handle payment status callbacks
File(s):
  - app/routes/webhooks.py (or create if doesn't exist)
  - tests/integration/test_pix_webhook.py
Details:
  1. Create POST /webhooks/payment-processor endpoint
  2. Verify webhook signature using payment processor's public key
  3. Extract payment_id, status (paid/failed/pending) from webhook payload
  4. Check idempotency_key to prevent duplicate processing
  5. Update order status in database: order.status = "paid" if status == "paid"
  6. Trigger email queue: send_order_confirmation(order_id)
  7. Log webhook events (timestamp, status, order_id, no sensitive data)
  8. Return 200 OK immediately (async processing)
  9. Integration test: send mock webhook with valid signature → order updates
  10. Integration test: send duplicate webhook with same idempotency key → no double-processing
  11. Integration test: send webhook with invalid signature → 401 Unauthorized
Acceptance:
  - All integration tests passing
  - Webhook validates signature correctly
  - Idempotency prevents duplicate order confirmations
  - Error logging captures failure scenarios
Depends on: T1, T2

## Task T4: Update Checkout UI to Show PIX Payment Option
Task: Add PIX selection and key input form to checkout flow
File(s):
  - frontend/src/pages/Checkout.jsx (or equivalent)
  - frontend/src/components/PaymentMethodSelector.jsx
  - frontend/src/styles/pix_payment.css
  - frontend/tests/PaymentMethodSelector.test.jsx
Details:
  1. Add PIX option to payment method radio button group (next to Credit Card, etc.)
  2. Create conditional form fields that appear when PIX is selected:
     - Dropdown: "PIX Key Type" (Email, Phone, CPF, Random Key)
     - Input field: "PIX Key" with placeholder and validation
  3. Add real-time validation (format checking per key type)
  4. Display error message in red if validation fails
  5. Add icon/logo for PIX (download from payment processor brand guidelines)
  6. Disable submit button until form is valid
  7. Add screen reader labels for accessibility
  8. Unit test: PIX key validation (valid email, valid phone, invalid format)
  9. Unit test: form submission disabled when PIX key is invalid
  10. Visual test: screenshot of PIX form (desktop + mobile)
Acceptance:
  - Form displays correctly on desktop and mobile
  - Validation shows/hides error messages correctly
  - Accessibility scan passes (WCAG 2.1 AA)
  - All unit tests passing
Depends on: T2

## Task T5: Implement PIX Payment Processing in Checkout API
Task: Add backend checkout endpoint logic to process PIX payments
File(s):
  - app/routes/checkout.py (POST /checkout)
  - app/services/checkout_service.py
  - tests/integration/test_checkout_pix.py
Details:
  1. In checkout endpoint, check payment_method == "pix"
  2. Extract and validate pix_key and pix_key_type from request
  3. Generate unique idempotency key: uuid.uuid4()
  4. Call payment processor client: create_pix_charge() [T2]
  5. Save order with status "pending_payment" and idempotency_key
  6. Return response with pix_qr_code (or payment_url) to frontend
  7. Integration test: successful PIX charge creation
  8. Integration test: duplicate checkout request (same idempotency key) returns same pix_qr_code
  9. Integration test: invalid pix_key returns 400 Bad Request with clear error
  10. Load test: simulate 50 concurrent PIX checkouts (verify no race conditions)
Acceptance:
  - Integration tests passing
  - QR code returned to frontend
  - Order saved with correct status and idempotency key
  - Load test shows <100ms response time at 50 concurrent requests
Depends on: T1, T2, T4

## Task T6: Add Monitoring, Metrics, and Logging
Task: Instrument PIX payment flow with observability
File(s):
  - app/services/pix_metrics.py (or add to existing metrics.py)
  - app/logging_config.py
Details:
  1. Add metrics:
     - `pix_transaction_total` (counter, tagged by status: success/failed/pending)
     - `pix_transaction_duration_ms` (histogram)
     - `pix_webhook_processing_time_ms` (histogram)
     - `pix_idempotency_duplicate_count` (counter)
  2. Add structured logs (JSON format):
     - Log: PIX charge created (order_id, amount, timestamp, idempotency_key — NO full key in logs)
     - Log: Webhook received and processed (order_id, status, timestamp)
     - Log: Webhook signature validation failed (reason, no payload)
  3. Set up alerts:
     - Alert if PIX webhook processing time > 5 seconds (investigate processor slowness)
     - Alert if duplicate webhook rate > 5% (potential retry storm)
  4. Verify metrics appear in monitoring dashboard
Acceptance:
  - Metrics queryable in monitoring system
  - No sensitive data in logs
  - Alerts configured and tested with mock scenarios
  - Dashboard shows PIX transaction success rate
Depends on: T2, T3, T5

## Task T7: Document PIX Payment Flow and Integration
Task: Write documentation for PIX integration
File(s):
  - docs/payment-methods/pix.md
  - docs/api/webhooks.md (update)
  - README.md (update payment methods section)
Details:
  1. Write high-level architecture diagram (user → checkout → processor → webhook → order)
  2. Document API endpoint: POST /checkout with pix payload example
  3. Document webhook schema: what fields are sent, how to verify signature
  4. Add troubleshooting section: common errors and solutions
  5. Add rate limits and retry strategy
  6. Add security considerations (no storing full PIX keys, idempotency strategy)
  7. Update README to list PIX as supported payment method
Acceptance:
  - Documentation is complete and accurate
  - Code examples run without errors
  - Links to related sections verified
Depends on: T1-T6 (documentation only, can start earlier)
```

This task breakdown ensures:
- No task takes >4 hours
- Each task is testable in isolation
- Dependencies are explicit and ordered
- Implementation is unambiguous
- Junior developers can execute without asking clarifying questions

## Sprint Planning Meeting

### Prep (before the meeting)
1. Product owner has a prioritized backlog with refined stories
2. Top stories have acceptance criteria and basic technical context
3. Team's velocity from last 3 sprints is known
4. Carry-over items from last sprint are identified

### Meeting Structure (2 hours max for a 2-week sprint)

**Part 1: What (30 min)**
- Product owner presents sprint goal and top-priority stories
- Team asks clarifying questions
- Align on what "done" means for each story

**Part 2: How (60 min)**
- Team breaks stories into tasks
- Estimation (story points or t-shirt sizes)
- Identify dependencies and risks
- Team commits to a realistic sprint backlog

**Part 3: Commitment (15 min)**
- Review the sprint goal
- Confirm total points are within velocity range
- Flag any concerns or blockers
- Everyone agrees they can commit

### Estimation Guide

Use Fibonacci (1, 2, 3, 5, 8, 13) or T-shirt sizes (XS, S, M, L, XL).

| Points | Meaning | Example |
|--------|---------|---------|
| 1 | Trivial, well-understood | Fix a typo, update a config |
| 2 | Small, straightforward | Add a field to an existing form |
| 3 | Medium, some complexity | New API endpoint with validation |
| 5 | Significant, multiple components | Feature with frontend + backend + tests |
| 8 | Large, uncertainty involved | New integration with external service |
| 13 | Very large — consider splitting | Full authentication flow from scratch |

If a story is >8 points, push to break it down. Stories that are too large hide complexity and create surprises mid-sprint.

## Release Planning

### Release Checklist
```markdown
# Release [Version] — [Date]

## Pre-Release
- [ ] All stories in "Done" column meet acceptance criteria
- [ ] QA sign-off on regression test suite
- [ ] Performance testing completed (load test results linked)
- [ ] Security review completed (if applicable)
- [ ] Database migrations tested on staging
- [ ] Feature flags configured for gradual rollout
- [ ] Rollback plan documented and tested
- [ ] Release notes drafted

## Deploy
- [ ] Staging deployment successful
- [ ] Smoke tests passing on staging
- [ ] Production deployment initiated
- [ ] Canary metrics monitored (15 min)
- [ ] Full rollout completed
- [ ] Post-deploy smoke tests passing

## Post-Release
- [ ] Monitoring dashboards reviewed (1 hour)
- [ ] Release notes published
- [ ] Stakeholders notified
- [ ] Retrospective scheduled
```

## Roadmap Planning

### Prioritization Framework: RICE

Score each initiative:
- **R**each — How many users/customers affected per quarter?
- **I**mpact — How much does it move the metric? (3=massive, 2=high, 1=medium, 0.5=low, 0.25=minimal)
- **C**onfidence — How sure are you about reach and impact? (100%=high, 80%=medium, 50%=low)
- **E**ffort — Person-months to complete

**RICE Score = (Reach x Impact x Confidence) / Effort**

Higher score = higher priority. This doesn't replace judgment but makes trade-offs explicit and comparable.

### Quarterly Roadmap Template
```markdown
# Q[X] [Year] Engineering Roadmap

## Theme: [One-line description of the quarter's focus]

## Committed (high confidence, resourced)
1. [Initiative] — [Team] — [Goal/Metric]
2. [Initiative] — [Team] — [Goal/Metric]

## Planned (medium confidence, tentatively resourced)
3. [Initiative] — [Team] — [Goal/Metric]
4. [Initiative] — [Team] — [Goal/Metric]

## Exploratory (low confidence, needs scoping)
5. [Initiative] — [Owner for scoping]

## Tech Debt / Platform
- [Item] — [Justification]

## Not Doing This Quarter (and why)
- [Item] — [Reason]
```

The "Not Doing" section is as important as the committed items — it sets expectations and prevents scope creep.

## Quality Gates

These are hard stops. A story cannot enter a sprint, and a sprint cannot start, if any of these gates fail.

### Story Not Ready for Sprint If

A story MUST NOT be assigned to a sprint if ANY of these are true:

- [ ] **Missing acceptance criteria** — Fewer than 3 scenarios, or scenarios not in Given-When-Then format
- [ ] **No error handling scenario** — Story doesn't describe what happens when something goes wrong
- [ ] **No edge case considered** — No boundary, race condition, or timeout scenario
- [ ] **Missing dependencies** — No list of other stories, APIs, or data required
- [ ] **No estimation** — Story has no complexity rating (S/M/L or story points)
- [ ] **Unclear scope** — Story is vague ("improve performance", "refactor code") without measurable outcomes
- [ ] **No Definition of Done** — Story lacks concrete checklist of what "done" means
- [ ] **Unclear success criteria** — How will you know when this story is actually complete?

If any are missing, return the story to the backlog with feedback. Do not pull it into sprint planning.

### Sprint Not Ready to Start If

The sprint ceremony cannot conclude with commitment if ANY of these are false:

- [ ] **All stories estimated** — Every story in the sprint has a complexity rating
- [ ] **Sprint goal defined** — Product owner articulated a one-sentence goal for the sprint
- [ ] **Team velocity checked** — Compare sprint points to last 3 sprints' velocity; flag if sprint is overcommitted
- [ ] **Dependencies mapped** — No critical story blocks another; external dependencies are tracked
- [ ] **Risks identified** — Team called out 3-5 potential blockers (API changes, data migration complexity, new vendor integration, etc.)
- [ ] **Capacity verified** — Account for planned time off, on-call duties, and meetings; reduce sprint target accordingly
- [ ] **Definition of Done agreed** — Team confirms what "done" means for each story
- [ ] **No surprises at 3am** — Team has briefly war-gamed the top 2-3 stories to surface unknowns

If any are false, resolve them before committing. Do not start a sprint with unresolved questions.

### Commit Decision Framework

Before the sprint "goes live," the product owner and tech lead should answer:

1. **Can the team execute?** Are all stories decomposed and dependencies clear?
2. **Is there risk?** What breaks if we deploy without finishing one story?
3. **Is the goal clear?** Can everyone articulate why this sprint matters?
4. **Is the load realistic?** Will the team be heroes at the end, or buried?

If the answer to any is unclear, the sprint is not ready. Invest 30 more minutes to fix it.
