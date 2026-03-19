# Payment Security & Data Design Checklist

## Mandatory Payment Checks

### 1. Money Type Safety
**Critical:** All monetary values MUST use integer or decimal types. NEVER use floating point.

**Why:** Floating point is imprecise. `0.1 + 0.2 != 0.3`. Financial calculations must be exact.

**What to check:**
- Currency amounts stored as `Integer` (cents) or `BigDecimal` (with 2 scale for USD)
- No `Double` or `Float` for money
- Database column type is `DECIMAL(19,2)` or `BIGINT` (not `DOUBLE`)
- All calculations use `.add()`, `.subtract()`, `.multiply()` with proper rounding mode
- Rounding only at presentation/settlement, not during intermediate calculations

**Example:**
```java
// ❌ WRONG
double chargeAmount = 29.99; // 0.1 + 0.2 problems
db.execute("INSERT INTO charges (amount) VALUES (" + chargeAmount + ")");

// ✅ CORRECT
BigDecimal chargeAmount = new BigDecimal("29.99");
db.execute("INSERT INTO charges (amount, currency) VALUES (?, ?)",
    chargeAmount.scaleByPowerOfTen(-2).longValue(), "USD");

// ✅ CORRECT (cents as integer)
long amountCents = 2999; // $29.99
db.execute("INSERT INTO charges (amount_cents, currency) VALUES (?, ?)",
    amountCents, "USD");
```

### 2. Idempotency Keys
**Critical:** Every payment operation MUST be idempotent using unique request IDs.

**Why:** Network failures cause retries. Without idempotency, duplicate charges happen.

**What to check:**
- Idempotency key generated on client, sent with every payment request
- Idempotency key stored in database (immutable)
- Duplicate requests return cached response, don't re-charge
- Idempotency key persists across retries (not regenerated)

**Example:**
```java
// ❌ WRONG: No idempotency
@PostMapping("/charge")
public ChargeResponse charge(@RequestBody ChargeRequest req) {
    return stripeApi.charge(req.amount); // Retry = double charge
}

// ✅ CORRECT: Idempotency key
@PostMapping("/charge")
public ChargeResponse charge(@RequestBody ChargeRequest req) {
    String idempotencyKey = req.idempotencyKey;

    // Check if already processed
    Charge existing = chargeRepository.findByIdempotencyKey(idempotencyKey);
    if (existing != null) {
        return mapper.toResponse(existing); // Return cached result
    }

    // Process new charge
    Charge charge = stripeApi.charge(
        req.amount,
        idempotencyKey // Pass to payment gateway
    );
    chargeRepository.save(charge);
    return mapper.toResponse(charge);
}
```

### 3. Double-Entry Bookkeeping for Ledger
**Critical:** Every financial transaction MUST be recorded as debit and credit.

**Why:** Prevents phantom transactions, enables reconciliation, required for audit.

**What to check:**
- Every charge creates two ledger entries: debit (user) and credit (platform)
- Sum of all debits = sum of all credits
- Ledger entries are immutable (never updated, only inserted)
- Reversal/refund creates new entries, not deletion of original

**Example:**
```sql
-- ✅ CORRECT: Double-entry for charge
INSERT INTO ledger (tx_id, account_id, amount, type, description) VALUES
    ('charge-1', 'user-123', -2999, 'DEBIT', 'Charge for Order #456'),
    ('charge-1', 'platform', 2999, 'CREDIT', 'Charge from user 123');

-- ✅ CORRECT: Double-entry for refund (new entries, not deletion)
INSERT INTO ledger (tx_id, account_id, amount, type, description) VALUES
    ('refund-1', 'user-123', 2999, 'CREDIT', 'Refund for Order #456'),
    ('refund-1', 'platform', -2999, 'DEBIT', 'Refund to user 123');

-- Invariant: SELECT SUM(amount) FROM ledger WHERE type = 'DEBIT'
--            = SELECT SUM(amount) FROM ledger WHERE type = 'CREDIT'
```

### 4. Proper Retry Logic with Exponential Backoff
**Critical:** Network failures MUST retry with backoff, not fail immediately.

**What to check:**
- Exponential backoff (not fixed delay): 1s, 2s, 4s, 8s... (with jitter)
- Max retries limited (typically 3-5)
- Only retryable errors are retried (timeout, 503, connection reset)
- Non-retryable errors (400, 401, 403) fail immediately
- Idempotency key ensures safe retries

**Example:**
```java
public ChargeResponse chargeWithRetry(String idempotencyKey, BigDecimal amount) {
    int maxRetries = 3;
    int delayMs = 1000;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
            return stripe.charge(amount, idempotencyKey);
        } catch (StripeTimeoutException e) {
            if (attempt == maxRetries) throw e;

            int jitter = new Random().nextInt(delayMs / 2);
            Thread.sleep(delayMs + jitter);
            delayMs *= 2; // Exponential backoff
        } catch (StripeInvalidCardException e) {
            // Non-retryable, fail immediately
            throw e;
        }
    }
}
```

### 5. Audit Trail for Every Transaction
**Critical:** Every charge, refund, and correction MUST be logged immutably.

**What to check:**
- Audit log table with: timestamp, user, action, amount, status, error message
- Audit logs are immutable (insert-only, no updates/deletes)
- Timestamps are precise (milliseconds)
- User context (who triggered the transaction) recorded
- Error details logged for failed attempts

### 6. Currency Handling
**Critical:** Multi-currency apps MUST validate and track currency.

**What to check:**
- Amount and currency always stored together
- Currency conversion only at well-defined boundaries
- Conversion rates logged with timestamp
- No implicit USD assumptions (check code for hardcoded amounts)
- FX risk acknowledged in calculations

### 7. PCI DSS Compliance Considerations
**Critical:** Credit card data MUST NOT be stored.

**What to check:**
- No storing credit card full numbers, CVV, or magnetic stripe data
- Card data tokenized immediately (use Stripe, Square, or similar)
- PCI scope minimized (preferably out-of-scope via payment processor)
- Passwords and security answers NEVER logged
- HTTPS enforced on all payment pages

### 8. Webhook Signature Verification
**Critical:** Payment processor webhooks MUST be verified before trusting.

**Why:** Attacker can POST fake webhook events to mark payments as complete.

**What to check:**
- Webhook signature verified using processor's public key
- Timestamp checked (replay attack prevention)
- Event ID deduplicated (idempotent processing)
- No processing webhook without signature check

**Example:**
```java
// ❌ WRONG: Trust webhook without verification
@PostMapping("/webhook/stripe")
public void handleStripeWebhook(@RequestBody StripeEvent event) {
    if (event.getType().equals("charge.succeeded")) {
        charge.setStatus("COMPLETED"); // Attacker can forge this!
    }
}

// ✅ CORRECT: Verify signature
@PostMapping("/webhook/stripe")
public void handleStripeWebhook(@RequestBody String payload,
                                  @RequestHeader("Stripe-Signature") String sig) {
    if (!stripeSignatureVerifier.verify(payload, sig, webhookSecret)) {
        throw new InvalidSignatureException();
    }

    StripeEvent event = mapper.readValue(payload, StripeEvent.class);
    if (event.getType().equals("charge.succeeded")) {
        charge.setStatus("COMPLETED");
    }
}
```

---

## SQL & Database Review Checklist

### Indexes
- [ ] Columns in WHERE clauses have indexes
- [ ] JOIN columns have indexes
- [ ] SELECT columns in WHERE/JOIN are indexed
- [ ] No unused indexes (bloat)
- [ ] Composite indexes ordered by selectivity (most selective first)
- [ ] EXPLAIN shows index usage for critical queries

### N+1 Queries
- [ ] ORM eager loading configured (`.include()`, `.fetch()`)
- [ ] Batch queries instead of loop queries
- [ ] No lazy loading inside loops
- [ ] COUNT(*) and aggregate queries use indexes

### SELECT Performance
- [ ] No `SELECT *` in production queries
- [ ] Only needed columns selected
- [ ] String columns have max length (not unbounded)
- [ ] BLOB/CLOB not in WHERE clause

### Pagination
- [ ] List endpoints have LIMIT (default max 100)
- [ ] Offset pagination or cursor-based
- [ ] No `OFFSET 1000000` (slow on large tables)
- [ ] Sort order stable for pagination consistency

### Query Timeout
- [ ] All queries have timeout (5-30s depending on SLA)
- [ ] Timeout configured at connection pool and query level
- [ ] Long-running reports use separate read replica

### SQL Injection Prevention
- [ ] All user input parameterized (? placeholders)
- [ ] No string concatenation in SQL
- [ ] ORM used or parameterized queries

---

## Schema Review Checklist

### Normalization
- [ ] No repeating groups (ATOMIC table structure)
- [ ] Intentional denormalization documented with trade-off
- [ ] No data duplication (single source of truth)

### Foreign Keys & Constraints
- [ ] Foreign keys defined for all relationships
- [ ] Cascade rules appropriate (DELETE CASCADE justified)
- [ ] ON UPDATE CASCADE avoided (avoid update storms)

### Data Types
- [ ] DECIMAL(19,2) for money, not FLOAT
- [ ] BIGINT for IDs (UUID or auto-increment 64-bit)
- [ ] VARCHAR length reasonable (not unlimited)
- [ ] BOOLEAN for true/false (not 0/1 strings)
- [ ] TIMESTAMP for dates (not DATE, to preserve time)

### Migration Safety
- [ ] No locking full tables (ALTER TABLE uses ALGORITHM=INPLACE)
- [ ] Migrations are backward-compatible (can rollback)
- [ ] No dropping columns/tables in same migration as code changes
- [ ] Rollback procedure tested

### Audit Columns
- [ ] `created_at` TIMESTAMP (set on insert)
- [ ] `updated_at` TIMESTAMP (updated on any change)
- [ ] `deleted_at` TIMESTAMP for soft deletes (if applicable)
- [ ] No querying without checking `deleted_at IS NULL`

---

## Messaging Review (Kafka, SQS, SNS)

### Idempotent Consumers
- [ ] Messages processed only once despite redelivery
- [ ] Deduplication based on message ID
- [ ] Operations are idempotent (safe to run twice)
- [ ] Example: INSERT ... ON CONFLICT / UPSERT pattern

**Example:**
```java
// ❌ WRONG: Not idempotent
@KafkaListener(topics = "payments")
public void processPayment(PaymentMessage msg) {
    chargeRepository.save(new Charge(msg.amount)); // Duplicate if redelivered
}

// ✅ CORRECT: Idempotent
@KafkaListener(topics = "payments")
public void processPayment(PaymentMessage msg) {
    chargeRepository.save(new Charge(msg.id, msg.amount));
    // Database constraint: UNIQUE(message_id) ensures no duplicates
}
```

### Dead Letter Queue (DLQ)
- [ ] Failed messages sent to DLQ after retries exhausted
- [ ] DLQ monitored for alerts
- [ ] DLQ messages manually inspectable and replayable

### Message Schema Versioning
- [ ] Schema versioned (v1, v2 in message type)
- [ ] Backward compatibility: new consumers handle old messages
- [ ] Forward compatibility: old consumers skip unknown fields
- [ ] No breaking changes without coordination

### Error Handling
- [ ] No messages silently dropped
- [ ] Processing errors logged with full context
- [ ] Retryable errors queued to DLQ with delay
- [ ] Non-retryable errors fail fast

### Consumer Groups (Kafka)
- [ ] Consumer group name meaningful and stable
- [ ] Partition count matches expected parallelism
- [ ] Consumer lag monitored
- [ ] Offset commits idempotent

### Visibility Timeout (SQS)
- [ ] Timeout long enough for processing (typically 30s)
- [ ] On failure, message returned to queue before timeout
- [ ] On success, message deleted immediately
- [ ] No processing messages after timeout expires

### Fan-Out Pattern (SNS → SQS)
- [ ] SNS topic subscribers correctly filter by message type
- [ ] SQS queue has Dead Letter Queue configured
- [ ] Queue permissions allow SNS to publish
- [ ] Message attributes preserved in delivery

**Example:**
```json
{
  "TopicArn": "arn:aws:sns:us-east-1:123456789012:payments",
  "Subscription": "arn:aws:sns:us-east-1:123456789012:payments:00000000-0000-0000-0000-000000000000",
  "Protocol": "sqs",
  "Endpoint": "arn:aws:sqs:us-east-1:123456789012:charge-queue",
  "RedrivePolicy": {
    "deadLetterTargetArn": "arn:aws:sqs:us-east-1:123456789012:charge-dlq"
  },
  "FilterPolicy": {
    "event_type": ["charge.succeeded", "charge.failed"]
  }
}
```

### Message Ordering
- [ ] If ordering required, documented and enforced
- [ ] Partition key consistent for order (Kafka)
- [ ] SQS FIFO used if strict ordering needed
- [ ] Outage plan if order cannot be guaranteed
