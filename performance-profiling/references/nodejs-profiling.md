# Node.js Profiling Deep Dive

## CPU Profiling

### V8 Built-in Profiler
```bash
node --prof app.js
node --prof-process isolate-*.log > profile.txt
```
Produces readable flame-graph-like output. Low overhead but requires post-processing.

### Chrome DevTools (Live Profiling)
```bash
node --inspect app.js
```
Open `chrome://inspect` → Profiler tab → Start recording. Real-time sampling, excellent UI.

### Clinic.js Suite
```bash
# Complete diagnostic
npx clinic doctor -- node app.js

# Flame graph
npx clinic flame -- node app.js

# Async bottleneck visualization
npx clinic bubbleprof -- node app.js
```
Production-grade diagnostics. Identifies event loop, I/O, and garbage collection issues.

---

## Event Loop Monitoring

The event loop is Node.js's lifeblood. If blocked, everything stalls.

### Measuring Event Loop Lag
```typescript
import { monitorEventLoopDelay } from 'perf_hooks';

const histogram = monitorEventLoopDelay({ resolution: 20 });
histogram.enable();

setInterval(() => {
  console.log({
    min: histogram.min / 1e6,      // ms
    max: histogram.max / 1e6,
    mean: histogram.mean / 1e6,
    p99: histogram.percentile(99) / 1e6,
  });
  histogram.reset();
}, 5000);
```

### Health Thresholds
- **Healthy**: mean <5ms, p99 <20ms
- **Degraded**: mean 5-50ms (users notice delays)
- **Critical**: mean >50ms (event loop is blocked)

### Common Event Loop Blockers
1. **Synchronous file I/O** in request path: `fs.readFileSync`, `fs.readdirSync`
2. **JSON operations** on large payloads: `JSON.parse()`, `JSON.stringify()` on 10MB+ objects
3. **Regex backtracking** on user input (ReDoS attacks): `/^(a+)+b/.test(input)`
4. **Crypto operations** without async: use `crypto.subtle` or `promisify(crypto.pbkdf2)`
5. **Large array operations**: sorting/filtering millions of items synchronously
6. **String concatenation** in tight loops
7. **Synchronous DNS lookups**: avoid `dns.lookup()`, use `dns.resolve4()` instead

---

## Memory Profiling

### Heap Snapshot Workflow
1. Start app with `--inspect`
2. Chrome DevTools → Memory tab
3. Take heap snapshot at baseline
4. Run suspect operation (generate users, process file, etc.)
5. Take second snapshot
6. Compare: Objects created between snapshots identify the leak
7. Drill into retained objects to trace root cause

### Configuration
```bash
# Increase heap limit for large apps
node --max-old-space-size=4096 app.js

# Allow manual GC for testing (forces collection between operations)
node --expose-gc app.js
# In code: global.gc()
```

### Allocation Tracking
Chrome DevTools → Memory → Allocation Timeline. Shows which operations allocate memory and when allocations are freed.

---

## Common Node.js Memory Leaks

| Leak Pattern | Cause | Fix |
|---|---|---|
| Event listeners | Missing `removeListener` in cleanup | Always pair `on()` with `off()` or use `once()` |
| Closures | Request/response objects held in closures | Null out references after use, use weak references if possible |
| Global caches | Maps/Sets growing unbounded | Implement TTL, LRU eviction, or bounded size |
| Unclosed streams | Error handlers don't destroy stream | Always call `stream.destroy()` on error |
| DB cursors | Connections not released | Use connection pooling, ensure cursors closed |
| Timers | `setInterval` never cleared | Store ID, `clearInterval(id)` in cleanup |
| Middleware state | Request-bound data persists | Garbage collect with request-scoped storage |

---

## Async Bottleneck Detection

### Using AsyncLocalStorage
```typescript
import { AsyncLocalStorage } from 'async_hooks';
import { performance } from 'perf_hooks';

const requestContext = new AsyncLocalStorage();

async function traceAsyncOperation(name, fn) {
  const start = performance.now();
  const result = await fn();
  const duration = performance.now() - start;
  console.log(`${name}: ${duration.toFixed(2)}ms`);
  return result;
}
```

### Using OpenTelemetry Spans
```typescript
import { trace } from '@opentelemetry/api';

const tracer = trace.getTracer('app');

async function queryDatabase() {
  const span = tracer.startSpan('database.query');
  try {
    const result = await db.query(sql);
    return result;
  } finally {
    span.end();
  }
}
```

Export spans to trace visualizer (Jaeger, Datadog, etc.). Aggregated traces show:
- Which async operation is slowest across requests
- Call chain bottlenecks
- I/O vs compute time breakdown
- Spans that exceed SLA
