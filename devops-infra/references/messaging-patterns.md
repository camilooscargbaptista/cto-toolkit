# Messaging Patterns & Strategies

## Kafka Architecture Decisions

### Partitions
- **Decision point** — Start with: `number_of_consumers × 2`
- **Scaling** — Increase partitions as throughput grows (cannot decrease)
- **Consumer assignment** — One consumer per partition (1:1 ratio for max parallelism)
- **Hot partitions** — Monitor; rebalance key distribution if uneven

### Replication Factor
- **Production** — Always 3 (tolerates 2 broker failures)
- **Development** — 1 is acceptable (single point of failure acceptable)
- **Set at creation** — Cannot change after topic creation
- **Cost** — 3x storage overhead vs. 1x, but guarantees data durability

### Retention Policy
- **Time-based** — `retention.ms` (default 7 days)
- **Size-based** — `retention.bytes` (default unlimited)
- **Tiered storage** — Move old data to cheaper storage (S3)
- **Compaction** — Use for changelog/state topics (keep latest value per key)

### Consumer Groups
- **Semantics** — Multiple consumers in same group = load balanced
- **Independent consumers** — Different groups for different use cases
- **Group ID** — Standardize: `{service-name}-{environment}-{purpose}`
- **Offsets** — Stored in `__consumer_offsets` topic; retention = 1 day

### Schema Registry
- **Message contracts** — Define schemas with Avro, JSON Schema, or Protobuf
- **Versioning** — Backwards/forwards compatibility enforced
- **Registry URL** — All producers/consumers point to same registry
- **Validation** — Reject messages that violate schema on publish

---

## SQS/SNS Patterns

### Fan-Out: SNS → Multiple SQS Queues

```
Publisher → SNS Topic
              ↓
         ┌────┴────┐
         ↓         ↓
      SQS Q1     SQS Q2     (multiple subscribers)
         ↓         ↓
      Service A  Service B
```

**Use case:** One event, multiple consumers (e.g., order created → inventory, billing, notification)

**Implementation:**
1. Publish to SNS topic
2. Subscribe SQS queues to the topic
3. Each queue receives independent copy
4. Each service processes at own pace

### Dead Letter Queue (DLQ)

```
Primary Queue
    ↓
[Process] → Success
    ↓
[Process] → Failure (retry)
    ↓
[Process] → Failure (retry) → Move to DLQ
              (maxReceiveCount exceeded)
                    ↓
              [Alert/Monitor]
              [Manual intervention]
```

**Configuration:**
```json
{
  "RedrivePolicy": {
    "deadLetterTargetArn": "arn:aws:sqs:region:account:dlq-name",
    "maxReceiveCount": 3
  }
}
```

**Monitoring:**
- Alert when DLQ message age > 5 minutes
- Weekly report of DLQ messages
- Automated retry job with exponential backoff

### Visibility Timeout

- **Purpose** — Prevents concurrent processing of same message
- **Duration** — Should be `> (max processing time + overhead)`
- **Formula** — `max_processing_time × 1.5` (safety margin)
- **Example** — Message takes 30s to process → visibility timeout = 45s
- **Too short** — Duplicate processing
- **Too long** — Slower failure detection

### Long Polling

**Disabled (Short Polling):**
- Consumer polls every 1 second
- Empty responses waste API calls
- Higher cost

**Enabled (Long Polling):**
```bash
aws sqs receive-message \
  --queue-url <url> \
  --wait-time-seconds 20
```
- Consumer waits up to 20 seconds for message
- Immediate return on message arrival
- 90% reduction in API calls
- **Enable by default** in production

### FIFO Queues

**Standard Queue:**
- **Throughput** — Unlimited
- **Ordering** — Best effort (not guaranteed)
- **Deduplication** — Not built-in
- **Cost** — $0.40 per million requests
- **Use** — Most cases

**FIFO Queue:**
- **Throughput** — 300 messages/sec (standard group), 3000 with batch
- **Ordering** — Strict (within message group)
- **Deduplication** — 5-minute window (automatic or content hash)
- **Cost** — $0.50 per million requests (25% more expensive)
- **Use** — Order processing, financial transactions (order matters)

---

## Message Idempotency Patterns

### Problem
> Same message processed twice → duplicate side effects (charge twice, insert twice)

### Solution 1: Idempotency Key (Recommended)

```python
# Publisher sends idempotency key
message = {
  "messageId": "order-12345-uuid",
  "correlationId": "correlation-uuid",
  "payload": {...}
}

# Consumer stores key on first processing
idempotency_store.set(
  key=message["messageId"],
  value={"status": "processed", "result": "..."},
  ttl=86400  # 24 hours
)

# On retry, check store first
if idempotency_store.exists(message["messageId"]):
  return idempotency_store.get(message["messageId"])["result"]
```

**Storage options:**
- Redis (fast, TTL support)
- DynamoDB (scalable, persistent)
- RDS (transactional guarantees)

### Solution 2: Business Logic Uniqueness

```sql
-- Database unique constraint ensures idempotency
INSERT INTO orders (order_id, customer_id, amount, created_at)
VALUES (?, ?, ?, NOW())
ON CONFLICT (order_id) DO UPDATE
SET updated_at = NOW();  -- Idempotent update
```

**Constraint:** `UNIQUE (order_id)` prevents duplicate inserts

### Solution 3: Exactly-Once Semantics (EOS)

**Kafka + Transactions:**
```java
producer.beginTransaction();
try {
  producer.send(topic, message);
  consumer.commitAsync();
  producer.commitTransaction();
} catch (Exception e) {
  producer.abortTransaction();
  throw e;
}
```

---

## Error Handling for Messaging

### Exponential Backoff

```
Attempt 1: Immediate
Attempt 2: Wait 2s   (2^1)
Attempt 3: Wait 4s   (2^2)
Attempt 4: Wait 8s   (2^3)
Attempt 5: Wait 16s  (2^4)
→ Send to DLQ
```

**SQS implementation:**
```python
def get_backoff_seconds(receive_count):
    if receive_count >= max_retries:
        # Send to DLQ
        return None
    return min(2 ** receive_count, 300)  # Cap at 5 minutes
```

### Retry Strategies

| Strategy | Use Case | Example |
|----------|----------|---------|
| **Immediate** | Transient errors (timeout, rate limit) | Retry 3x immediately |
| **Exponential backoff** | Service degradation | Start 1s, double each time |
| **Circuit breaker** | Cascading failures | Stop retries if >50% fail |
| **DLQ + manual** | Unrecoverable errors | Operator reviews and resubmits |

### Circuit Breaker Pattern

```
[Closed] ──failure──> [Open] ──timeout──> [Half-Open]
                       ↑                       ↓
                       └───────failure────────┘
                              (reopen)

Closed: Normal operation
Open: Fast fail, don't even try
Half-Open: Test if service recovered
```

### Monitoring & Alerting

```
Alert thresholds:
- DLQ message count > 0 (within 5 minutes)
- Processing latency p95 > 2x baseline
- Error rate > 1%
- Consumer lag > 1 million messages
- Visibility timeout exceeded > 5%

Dashboards:
- Messages processed (rate)
- Error rate by queue/topic
- DLQ message age
- Consumer lag (by consumer group)
```

### Logging Best Practices

```json
{
  "timestamp": "2026-03-18T10:30:45.123Z",
  "messageId": "msg-uuid",
  "correlationId": "correlation-uuid",
  "queue": "order-processing",
  "status": "error",
  "error": "PaymentGatewayTimeout",
  "errorDetails": "Request to payment API timed out after 30s",
  "receiveCount": 2,
  "attempt": 2,
  "processingTimeMs": 30150,
  "willRetry": true,
  "nextRetryIn": "4s"
}
```

**Correlation IDs** — Trace same logical request across services
