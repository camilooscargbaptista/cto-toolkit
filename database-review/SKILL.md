---
name: database-review
allowed-tools: Read, Grep, Glob, Bash
description: "**Database Design & SQL Review**: Expert guide for schema design, database migrations, query optimization, indexing strategy, and database performance. Covers relational (PostgreSQL, MySQL) and NoSQL (MongoDB, DynamoDB, Redis). Use whenever the user mentions 'database', 'schema', 'migration', 'SQL', 'query optimization', 'slow query', 'index', 'N+1', 'normalization', 'denormalization', 'PostgreSQL', 'MySQL', 'MongoDB', 'DynamoDB', 'Redis', 'ORM', 'TypeORM', 'Prisma', 'Sequelize', 'query plan', 'EXPLAIN', 'deadlock', 'connection pool', or asks about database design, data modeling, or performance tuning."
---

# Database Design & SQL Review

You are a senior database engineer helping with schema design, query optimization, migration safety, and data modeling decisions. Every database decision has long-term consequences — optimize for correctness first, then performance.

## Schema Design Principles

### Naming Conventions

```sql
-- Tables: plural, snake_case
CREATE TABLE order_items (...)
CREATE TABLE user_addresses (...)

-- Columns: snake_case, descriptive
id                  -- PK (or user_id for clarity in joins)
created_at          -- timestamps always with _at suffix
updated_at
deleted_at          -- soft delete
is_active           -- booleans with is_/has_ prefix
total_amount_cents  -- money in cents, explicit unit in name
email_address       -- full name, not just 'email' if ambiguous

-- Indexes: ix_{table}_{columns}
CREATE INDEX ix_orders_user_id ON orders(user_id);
CREATE INDEX ix_orders_status_created ON orders(status, created_at);

-- Foreign keys: fk_{table}_{referenced_table}
CONSTRAINT fk_orders_users FOREIGN KEY (user_id) REFERENCES users(id)

-- Unique constraints: uq_{table}_{columns}
CONSTRAINT uq_users_email UNIQUE (email_address)
```

### Data Types (PostgreSQL)

| Use Case | Type | Not |
|----------|------|-----|
| Primary key | `uuid` or `bigint` | `int` (runs out) |
| Money | `bigint` (cents) or `numeric(19,4)` | `float`/`double` (precision loss) |
| Timestamps | `timestamptz` | `timestamp` (no timezone = bugs) |
| Short text | `varchar(N)` with limit | `text` without validation |
| Long text | `text` | `varchar(10000)` |
| Boolean | `boolean` | `smallint` or `char(1)` |
| JSON data | `jsonb` | `json` (no indexing) |
| IP address | `inet` | `varchar` |
| Enum-like | `varchar` + CHECK or enum type | Magic numbers |
| Status | `varchar` with CHECK constraint | `int` (unreadable) |

### Normalization Guidelines

**Normalize first, denormalize with evidence.** Start at 3NF and only denormalize when you have measured performance data showing it's necessary.

**When to denormalize:**
- Read-heavy workloads where joins are measured bottleneck
- Reporting/analytics tables (materialized views, CQRS read models)
- Caching layers (Redis, Elasticsearch)
- Event data / audit logs (store complete snapshot)

**When NOT to denormalize:**
- "It might be slow" (measure first)
- To avoid writing a join (joins are fine, they're what SQL is for)
- For convenience in the ORM

## Migration Safety

### Safe Migration Checklist

```markdown
- [ ] Migration is backward-compatible (old code works with new schema)
- [ ] No table locks on large tables during peak hours
- [ ] Tested on staging with production-like data volume
- [ ] Rollback migration exists and has been tested
- [ ] Data migration separated from schema migration
- [ ] Index creation uses CONCURRENTLY (PostgreSQL)
- [ ] No NOT NULL on existing column without default value
- [ ] Estimated execution time documented
```

### Safe vs Unsafe Operations

| Operation | Safe? | Notes |
|-----------|-------|-------|
| Add nullable column | Yes | No lock, instant |
| Add column with default (PG 11+) | Yes | Metadata-only in modern PG |
| Add NOT NULL to existing column | Dangerous | Scans entire table, locks |
| Drop column | Careful | App must not reference it first |
| Rename column | Dangerous | Breaks running app code |
| Add index | Use CONCURRENTLY | `CREATE INDEX CONCURRENTLY` |
| Drop index | Yes | But verify no queries need it |
| Change column type | Dangerous | Full table rewrite |
| Add foreign key | Careful | Validates existing data (lock) |

### Multi-Step Migration Pattern

For dangerous changes, use multiple deployments:

```
Step 1 (Deploy 1): Add new column (nullable)
Step 2 (Deploy 2): Backfill data, update app to write to both columns
Step 3 (Deploy 3): Switch app to read from new column
Step 4 (Deploy 4): Add NOT NULL constraint, drop old column
```

This avoids downtime and allows rollback at any step.

## Query Optimization

### Reading EXPLAIN Plans

```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT o.id, o.total_amount_cents, u.name
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'pending'
  AND o.created_at > NOW() - INTERVAL '7 days'
ORDER BY o.created_at DESC
LIMIT 20;
```

**What to look for:**
- `Seq Scan` on large tables → needs an index
- `Nested Loop` with high row estimates → consider `Hash Join`
- `Sort` with high cost → add index matching ORDER BY
- `Rows Removed by Filter` is high → index not selective enough
- `Buffers: shared read` is high → data not in cache, consider query scope

### Indexing Strategy

```sql
-- Basic: columns used in WHERE
CREATE INDEX ix_orders_status ON orders(status);

-- Composite: columns used together in WHERE + ORDER BY
-- Column order matters: most selective first, or match query pattern
CREATE INDEX ix_orders_status_created ON orders(status, created_at DESC);

-- Covering index: includes columns from SELECT to avoid table lookup
CREATE INDEX ix_orders_cover ON orders(status, created_at DESC)
  INCLUDE (total_amount_cents, user_id);

-- Partial index: index only relevant rows (smaller, faster)
CREATE INDEX ix_orders_pending ON orders(created_at DESC)
  WHERE status = 'pending';

-- Expression index: for computed lookups
CREATE INDEX ix_users_email_lower ON users(LOWER(email_address));

-- GIN index for JSONB
CREATE INDEX ix_products_metadata ON products USING GIN(metadata);
```

### Common Performance Anti-Patterns

**N+1 Queries**
```
BAD:  Fetch 100 orders, then 100 separate queries for each user
GOOD: JOIN orders with users in one query, or batch load user_ids IN (...)
```

**SELECT ***
```
BAD:  SELECT * FROM orders (fetches all columns including large text/blob)
GOOD: SELECT id, status, total_amount_cents FROM orders (only what you need)
```

**Missing pagination**
```
BAD:  SELECT * FROM orders WHERE user_id = 123 (could return millions)
GOOD: SELECT ... LIMIT 20 OFFSET 0 (or cursor-based pagination)
```

**Cursor-based pagination (better for large datasets):**
```sql
-- Instead of OFFSET (slow for large offsets):
SELECT * FROM orders WHERE user_id = 123 ORDER BY id LIMIT 20 OFFSET 10000;

-- Use cursor (fast regardless of position):
SELECT * FROM orders
WHERE user_id = 123 AND id > :last_seen_id
ORDER BY id LIMIT 20;
```

**Functions on indexed columns**
```sql
-- BAD: index on created_at won't be used
WHERE DATE(created_at) = '2024-01-01'

-- GOOD: range query uses the index
WHERE created_at >= '2024-01-01' AND created_at < '2024-01-02'
```

**Implicit type casting**
```sql
-- BAD: if user_id is bigint, string forces cast
WHERE user_id = '12345'

-- GOOD: match the type
WHERE user_id = 12345
```

## Connection Management

### Connection Pool Sizing

```
Recommended: connections = (CPU cores * 2) + effective_spindle_count

For cloud/SSD:
- Small app (1-2 instances): pool_size = 10-20
- Medium app (3-5 instances): pool_size = 5-10 per instance
- Large app (10+ instances): use PgBouncer/ProxySQL

Total connections = pool_size × instances
PostgreSQL default max_connections = 100
```

### Connection Pool Best Practices

- Always use connection pooling (never open/close per query)
- Set both min and max pool size
- Configure idle timeout (release unused connections)
- Monitor pool utilization (exhaustion = timeout errors)
- For serverless (Lambda): use RDS Proxy or PgBouncer
- Set statement timeout to prevent runaway queries

## NoSQL Considerations

### When to Use NoSQL

| Use Case | Best Choice | Why |
|----------|------------|-----|
| Relational data, transactions | PostgreSQL | ACID, joins, mature |
| Key-value cache | Redis | Sub-millisecond, TTL |
| Document store, flexible schema | MongoDB | Schema evolution, nesting |
| High-throughput, predictable latency | DynamoDB | Auto-scaling, single-digit ms |
| Full-text search | Elasticsearch | Inverted index, relevance scoring |
| Time-series data | TimescaleDB / InfluxDB | Optimized for time-range queries |
| Graph relationships | Neo4j | Relationship traversal |

### DynamoDB Design

```
Single-table design for DynamoDB:
- Think about access patterns FIRST, schema second
- Design partition key for even distribution
- Use sort key for range queries within a partition
- GSI for alternative access patterns
- Avoid scan operations (full table read)
```

## Review Checklist

```markdown
## Schema Review
- [ ] Appropriate data types (no floats for money, timestamptz for times)
- [ ] Primary keys defined (uuid or bigint)
- [ ] Foreign keys with appropriate ON DELETE behavior
- [ ] NOT NULL on columns that should never be null
- [ ] CHECK constraints for enums/ranges
- [ ] Unique constraints where business rules require it
- [ ] Indexes for common query patterns

## Query Review
- [ ] EXPLAIN ANALYZE checked for expensive queries
- [ ] No N+1 patterns
- [ ] No SELECT * in application queries
- [ ] Pagination present for list queries
- [ ] No functions on indexed columns in WHERE
- [ ] Appropriate JOIN types used

## Migration Review
- [ ] Backward-compatible with current app version
- [ ] No long-running locks on large tables
- [ ] CONCURRENTLY used for index creation
- [ ] Rollback tested
- [ ] Data backfill separated from schema change
```
