# Load Testing & Frontend Performance Deep Dive

## Load Testing Strategy

### Four Test Types

1. **Baseline Test**: Normal expected traffic for 10 minutes
   - Establishes healthy performance metrics
   - Captures normal latency, memory, CPU

2. **Stress Test**: 2x–5x normal traffic until breaking point
   - Identify system limit
   - Where do connections/pools exhaust?

3. **Soak Test**: Normal traffic for 4–8 hours
   - Uncover memory leaks, GC issues, connection leaks
   - Resource usage trend over time

4. **Spike Test**: 10x traffic for 30 seconds then drop
   - Does system recover after spike?
   - Queue buildup, connection pool drain, memory freed?

---

## Load Testing Tool Comparison

| Tool | Language | Best For | Ceiling |
|------|----------|----------|---------|
| **k6** | JavaScript | Developer-friendly, CI integration, cloud runs | 10k+ VUs |
| **Artillery** | JavaScript/YAML | Quick API tests, minimal code | 5k+ VUs |
| **Gatling** | Scala | Complex scenarios, detailed HTML reports | 50k+ VUs |
| **Locust** | Python | Distributed testing, custom logic | 100k+ VUs |
| **wrk/wrk2** | C | Raw HTTP throughput, benchmarking | Simple but fast |

---

## k6 Example: Full Load Profile

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  // Ramp up → Steady → Stress → Ramp down
  stages: [
    { duration: '2m', target: 50 },    // Ramp up to 50 VUs over 2 min
    { duration: '5m', target: 50 },    // Stay at 50 for 5 min (baseline)
    { duration: '2m', target: 200 },   // Ramp to 200 (stress)
    { duration: '5m', target: 200 },   // Sustained stress for 5 min
    { duration: '2m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],  // 95th percentile <500ms
    http_req_failed: ['rate<0.01'],                  // Error rate <1%
  },
};

export default function () {
  const res = http.get('https://api.example.com/payments');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'latency < 500ms': (r) => r.timings.duration < 500,
    'body has id': (r) => r.json('id') !== undefined,
  });
  sleep(1);  // Wait 1 second between requests per VU
}
```

Run: `k6 run script.js` or `k6 cloud script.js` (distributed).

---

## Web Frontend Performance

### Core Web Vitals

| Metric | Target | What It Measures | User Impact |
|--------|--------|-----------------|-------------|
| **LCP** (Largest Contentful Paint) | <2.5s | Loading performance | Users wait for main content |
| **INP** (Interaction to Next Paint) | <200ms | Interactivity | Feels responsive or sluggish |
| **CLS** (Cumulative Layout Shift) | <0.1 | Visual stability | Layout jumps frustrate users |
| **TTFB** (Time to First Byte) | <800ms | Server response | Backend/CDN latency |
| **FCP** (First Contentful Paint) | <1.8s | First visual feedback | Perceived load speed |

Measure with: Lighthouse, WebVitals library, Google Search Console, real user monitoring (RUM).

### Browser DevTools Profiling

#### Performance Tab
```
1. Click Record
2. Perform slow action (scroll, click, load page)
3. Stop recording
4. Analyze:
   - Main thread: Look for long tasks (yellow/red bars >50ms)
   - Bottom: Network waterfall showing fetch chain
   - Look for render blocking resources (CSS, sync scripts)
   - Rendering section: excessive layout recalculations, paint storms
```

Heavy main thread = CPU-bound JavaScript (large computations, JSON parsing).
Slow network = server/CDN/asset delivery issue.

#### Memory Tab
```
1. Take heap snapshot before slow operation
2. Perform operation
3. Take second snapshot
4. Compare: What objects are newly allocated?
5. Allocation timeline shows when allocations spike
```

Look for: Detached DOM nodes (elements removed from page but still referenced), growing arrays, memory not freed after operation completes.

### Bundle Size Analysis

```bash
# Webpack bundle analyzer
npx webpack-bundle-analyzer stats.json

# Source-map-explorer
npx source-map-explorer build/static/js/*.js
```

Common culprits:
- Entire lodash imported instead of `lodash/get`
- moment.js with all locales (2.5MB!) → use date-fns or dayjs
- Duplicate dependencies (e.g., two versions of React)
- Disabled tree-shaking (check `sideEffects` in package.json)

Target: <50KB gzipped for critical path JavaScript.

---

## Flutter Performance

### Profile Mode (Not Debug)
```bash
flutter run --profile
# NEVER profile in debug mode; it adds significant overhead
```

### DevTools
```bash
flutter pub global activate devtools
dart devtools
# Open in browser, connect your app
```

### Key Flutter Metrics

| Metric | Target | What It Means |
|--------|--------|---------------|
| **UI thread** | <16ms (60fps) or <8ms (120fps) | Frame rate; >16ms = dropped frames |
| **Raster thread** | <16ms per frame | GPU rendering; >16ms = janky scroll |
| **Widget rebuild count** | Minimal per frame | Excessive rebuilds = wasted work |
| **Dart heap** | Stable | Growing = memory leak |

Measure in DevTools → Performance tab. Look for red bars (frame overages).

### Common Flutter Performance Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| Excessive rebuilds | Parent widget rebuilds, forcing children to rebuild | Extract widgets, use `const` constructors, `ValueListenableBuilder` |
| Janky scrolling | Heavy computation during scroll | Move to `compute()` isolate, use `RepaintBoundary` |
| Large images | Uncached or unresized images | Use `Image.asset(..., cacheWidth: X)` or precache |
| Memory growth | Listeners not unregistered | `dispose()` streams, listeners, controllers |
| Slow startup | Expensive initialization | Lazy-load features, defer non-critical init |

Profile-first: Use DevTools timeline, don't optimize by intuition.

---

## Caching Strategy

### Cache Hierarchy

```
Browser cache        → Fastest (user's machine)
CDN cache            → Geographic speed (edge)
Application cache    → Flexible (Redis, Memcached)
Database query cache → Automatic but limited
Database disk        → Slowest (must optimize queries)
```

### When to Cache

**Cache when:**
- Data read 100x more than written
- Expensive to compute (>10ms latency)
- Tolerance for staleness (5-60 min acceptable)
- High traffic (cache overhead pays for itself)

**Don't cache when:**
- Data changes per request (session state)
- Already fast (<1ms fetch)
- Consistency critical (payment status)
- Low traffic (cache overhead > benefit)

### Cache Invalidation Patterns

1. **TTL (Time-to-Live)**: Expire after N seconds. Simple, eventual consistency.
   ```
   redis.set(key, value, 'EX', 300)  // 5 min TTL
   ```

2. **Write-through**: Update cache on every write. Consistent but slower writes.

3. **Write-behind**: Queue writes, update cache async. Fast writes, staleness risk.

4. **Cache-aside**: App manages cache (load → miss → fetch → store).

5. **Event-driven**: Invalidate on domain events (order.created → clear order cache).

### Cache-Aside Pattern (Recommended)

```typescript
async function getUser(userId: string): Promise<User> {
  const cacheKey = `user:${userId}`;

  // Step 1: Check cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    return JSON.parse(cached);  // Cache hit
  }

  // Step 2: Cache miss — fetch from source
  const user = await db.users.findById(userId);
  if (!user) return null;

  // Step 3: Store in cache with TTL
  await redis.set(cacheKey, JSON.stringify(user), 'EX', 300);  // 5 min

  return user;
}

// Invalidate on update
async function updateUser(userId: string, data: Partial<User>): Promise<User> {
  const user = await db.users.update(userId, data);
  await redis.del(`user:${userId}`);  // Clear cache
  return user;
}
```

**Advantages:**
- Simple to implement
- No cache stampede issues
- Updates always fresh
- Easy to add/remove caching

**Disadvantages:**
- First request slow (cache miss)
- Requires cache-aware code everywhere
