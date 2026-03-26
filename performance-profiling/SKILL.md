---
name: performance-profiling
description: "**Performance Profiling & Optimization**: Helps diagnose and fix performance issues including memory leaks, CPU bottlenecks, slow queries, high latency, and throughput problems. Covers profiling tools, flame graphs, load testing, caching strategies, and optimization techniques for Node.js, Java, Flutter, and web applications. Use whenever the user mentions 'performance', 'slow', 'memory leak', 'OOM', 'high CPU', 'latency', 'throughput', 'flame graph', 'profiling', 'load test', 'benchmark', 'cache', 'optimization', 'p99', 'response time', 'bottleneck', 'event loop', 'garbage collection', 'heap', or says 'my app is slow', 'why is this endpoint slow', 'we're running out of memory'."
category: performance
preferred-model: sonnet
min-confidence: 0.4
triggers:
  anti-patterns: [n_plus_one, eager_loading, missing_cache]
  frameworks: [express, nestjs, fastify, spring]
  file-patterns: ["**/benchmark/**", "**/perf/**"]
depends-on: []
estimated-tokens: 5000
tags: [performance, profiling, latency, optimization]
---

# Performance Profiling & Optimization

You are a senior performance engineer helping diagnose and fix performance issues. The golden rule: measure first, optimize second. Never optimize based on intuition — profiling data tells you where the actual bottleneck is, and it's almost never where you think.

## Performance Investigation Workflow

```
1. DEFINE    → What metric is bad? (latency, throughput, memory, CPU)
2. MEASURE   → Establish baseline with numbers
3. PROFILE   → Find the bottleneck with tools
4. HYPOTHESIZE → Form theory about root cause
5. FIX       → Make targeted change
6. VERIFY    → Measure again, confirm improvement
```

## Identifying the Bottleneck Type

| Symptom | Likely Bottleneck | Where to Look |
|---------|-------------------|---------------|
| High CPU, fast responses | CPU-bound computation | Flame graphs, hot functions |
| Low CPU, slow responses | I/O-bound (DB, network, disk) | Trace spans, await times |
| Growing memory, eventual OOM | Memory leak | Heap snapshots, allocation tracking |
| Slow under load, fast alone | Contention (locks, pool, connections) | Connection pools, thread contention |
| Spiky latency (p99 >> p50) | GC pauses or resource contention | GC logs, lock contention |
| Degrading over time | Resource leak or unbounded growth | Memory trend, connection count trend |

## Node.js Profiling

Start with `npx clinic doctor -- node app.js` for quick diagnostic. Deep dive: see `references/nodejs-profiling.md` for CPU profiling tools (V8 --prof, Chrome DevTools --inspect, Clinic.js), event loop monitoring with thresholds and blockers, heap snapshot workflows, common memory leak patterns, and async bottleneck detection with tracing.

## Java / JVM Profiling

Use JFR (Java Flight Recorder) for production diagnostics. See `references/jvm-profiling.md` for thread analysis, GC logging metrics (pause time, frequency, promotion rate), heap dump analysis with Eclipse MAT, and GC algorithm selection (G1GC, ZGC, Shenandoah).

## Web Frontend Performance

Target Core Web Vitals: LCP <2.5s, INP <200ms, CLS <0.1. Use Chrome DevTools Performance tab for main thread analysis and bundle analyzer for size optimization. See `references/load-testing.md` for metrics table, profiling workflow, and common optimizations.

## Flutter Profiling

Always profile in `--profile` mode, not debug. Monitor UI thread <16ms/frame (60fps), raster thread <16ms, widget rebuild count, and Dart heap growth. See `references/load-testing.md` for key metrics and common issues (widget rebuilds, image caching, isolate usage).

## Load Testing

**Strategy:** Baseline (10 min normal) → Stress (2x-5x) → Soak (4-8 hrs) → Spike (10x burst).

**Tools:** k6 (JavaScript, CI-friendly), Artillery (quick tests), Gatling (complex scenarios), Locust (distributed), wrk (throughput benchmarking).

See `references/load-testing.md` for tool comparison, k6 example with stages and thresholds, and strategy details.

## Caching Strategy

**Hierarchy:** Browser → CDN → Application (Redis) → Database → Disk.

**When to cache:** High read/write ratio, expensive to compute, tolerance for staleness, high traffic.

**Invalidation:** TTL (simple), write-through (consistent), write-behind (fast), cache-aside (flexible), event-driven (on domain events).

See `references/load-testing.md` for cache-aside pattern code and when-to-cache decision table.

## Performance Checklist

```markdown
## Application
- [ ] Profiled under realistic load (not just locally)
- [ ] Flame graph analyzed for CPU bottlenecks
- [ ] No N+1 database queries
- [ ] Database queries have EXPLAIN ANALYZE reviewed
- [ ] Connection pools properly sized
- [ ] Caching in place for hot data
- [ ] Async operations where possible
- [ ] No blocking operations on main thread/event loop

## Infrastructure
- [ ] Autoscaling configured and tested
- [ ] CDN for static assets
- [ ] Compression enabled (gzip/brotli)
- [ ] Database indexes for common queries
- [ ] Read replicas for read-heavy workloads

## Monitoring
- [ ] Latency percentiles tracked (p50, p90, p99)
- [ ] Memory and CPU dashboards
- [ ] Alerts on latency degradation
- [ ] Load test results baselined
```
