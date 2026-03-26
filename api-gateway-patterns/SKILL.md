---
name: api-gateway-patterns
description: "API Gateway design patterns including rate limiting, authentication, versioning, BFF and circuit breaking"
triggers:
  frameworks: [kong, nginx, envoy, traefik, api-gateway]
  file-patterns: ["**/gateway/**", "**/proxy/**"]
preferred-model: sonnet
min-confidence: 0.4
depends-on: []
category: architecture
estimated-tokens: 5000
tags: [api-gateway, rate-limiting, routing]
---

# API Gateway Patterns

## When to Use
- Designing an API gateway for microservices
- Implementing rate limiting, authentication, or request routing
- Evaluating BFF (Backend for Frontend) pattern
- Adding circuit breaking to external service calls

## Gateway Architecture

```
                    ┌─────────────────────┐
                    │    API Gateway       │
                    │                     │
  Clients ────────►│  1. Rate Limiting    │
                    │  2. Authentication   │
                    │  3. Request Routing  │
                    │  4. Load Balancing   │
                    │  5. Circuit Breaking │
                    │  6. Response Caching │
                    │  7. Logging/Tracing  │
                    └────┬────┬────┬──────┘
                         │    │    │
                    ┌────┘    │    └────┐
                    ▼         ▼         ▼
              ┌──────┐  ┌──────┐  ┌──────┐
              │Svc A │  │Svc B │  │Svc C │
              └──────┘  └──────┘  └──────┘
```

## Rate Limiting Patterns

### Token Bucket (recommended)
```typescript
// Allows burst then throttles
const rateLimiter = {
  bucketSize: 100,      // Max tokens
  refillRate: 10,       // Tokens per second
  refillInterval: 1000, // ms
};
// Burst: 100 requests instantly, then 10/sec sustained
```

### Sliding Window
```typescript
// More accurate, no burst
// Count requests in last N seconds
// Redis implementation:
// ZADD rate:{userId} {timestamp} {requestId}
// ZREMRANGEBYSCORE rate:{userId} 0 {timestamp - window}
// ZCARD rate:{userId}
```

### Rate Limit by Tier
| Tier | Rate Limit | Burst |
|------|-----------|-------|
| Free | 100 req/hour | 10 req/sec |
| Basic | 1000 req/hour | 50 req/sec |
| Pro | 10000 req/hour | 200 req/sec |
| Enterprise | Custom | Custom |

### Response Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1619472000
Retry-After: 60
```

## API Versioning Strategies

| Strategy | Example | Pros | Cons |
|----------|---------|------|------|
| URL path | `/v1/users` | Simple, clear | URL pollution |
| Header | `Accept: application/vnd.api.v1+json` | Clean URLs | Hidden, harder to test |
| Query param | `/users?version=1` | Easy to switch | Messy |

**Recommendation**: URL path for public APIs, header for internal APIs.

### Deprecation Policy
```
v1: Active → Deprecated → Sunset
    │          │           │
    └──────────┘           │
      6 months minimum     │
      communication        │
                           └── Remove with 3-month warning
```

## BFF (Backend for Frontend)

```
┌────────┐     ┌─────────────┐     ┌──────────┐
│ Mobile  │────►│ Mobile BFF  │────►│          │
│ App     │     │ (optimized) │     │          │
└────────┘     └─────────────┘     │  Core    │
                                    │  Services │
┌────────┐     ┌─────────────┐     │          │
│ Web    │────►│  Web BFF    │────►│          │
│ App     │     │ (full data) │     │          │
└────────┘     └─────────────┘     └──────────┘

Mobile BFF: Less data, compressed images, offline-first
Web BFF:    Full data, SSR support, WebSocket
```

## Circuit Breaker

```typescript
enum CircuitState { CLOSED, OPEN, HALF_OPEN }

class CircuitBreaker {
  private state = CircuitState.CLOSED;
  private failureCount = 0;
  private successCount = 0;
  private lastFailureTime: Date;

  private readonly threshold = 5;        // Failures to open
  private readonly timeout = 30000;      // ms before half-open
  private readonly halfOpenMax = 3;      // Successes to close

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() - this.lastFailureTime.getTime() > this.timeout) {
        this.state = CircuitState.HALF_OPEN;
      } else {
        throw new Error('Circuit is OPEN — service unavailable');
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private onSuccess() {
    if (this.state === CircuitState.HALF_OPEN) {
      this.successCount++;
      if (this.successCount >= this.halfOpenMax) {
        this.state = CircuitState.CLOSED;
        this.failureCount = 0;
      }
    }
    this.failureCount = 0;
  }

  private onFailure() {
    this.failureCount++;
    this.lastFailureTime = new Date();
    if (this.failureCount >= this.threshold) {
      this.state = CircuitState.OPEN;
    }
  }
}
```

## Request/Response Transformation

```typescript
// Gateway aggregation — single client call, multiple services
@Get('dashboard')
async getDashboard(@User() user) {
  const [profile, stats, notifications] = await Promise.allSettled([
    this.userService.getProfile(user.id),
    this.billingService.getStats(user.companyId),
    this.notificationService.getUnread(user.id),
  ]);

  return {
    profile: profile.status === 'fulfilled' ? profile.value : null,
    stats: stats.status === 'fulfilled' ? stats.value : null,
    notifications: notifications.status === 'fulfilled' ? notifications.value : [],
  };
  // Graceful degradation: partial response even if one service fails
}
```

## Quality Gates

- [ ] Rate limiting configured on all public endpoints
- [ ] Authentication at gateway level (not duplicated in services)
- [ ] API versioning strategy defined and documented
- [ ] Circuit breakers on all external service calls
- [ ] Request/response logging with correlation IDs
- [ ] Health check endpoint for each downstream service
- [ ] Timeout configured for all downstream calls
