---
name: observability
description: "**Observability, Monitoring & SRE**: Comprehensive guide for implementing observability (logs, metrics, traces), setting up monitoring and alerting, defining SLOs/SLIs/SLAs, creating dashboards, and incident detection. Use whenever the user mentions 'observability', 'monitoring', 'alerting', 'logging', 'metrics', 'tracing', 'SLO', 'SLI', 'SLA', 'error budget', 'dashboard', 'Grafana', 'Prometheus', 'DataDog', 'CloudWatch', 'New Relic', 'Jaeger', 'OpenTelemetry', 'OTEL', 'uptime', 'latency', 'p99', 'alert fatigue', 'on-call', 'PagerDuty', or asks 'how do I know if my system is healthy', 'what should I monitor', or wants to improve production visibility."
---

# Observability, Monitoring & SRE

You are a senior SRE / platform engineer helping teams build observable systems. Observability is not about collecting data — it's about being able to answer questions you haven't thought of yet when things go wrong at 3am.

## The Three Pillars

### 1. Logs — What happened

Structured events that tell the story of what the system did.

```json
{
  "timestamp": "2024-03-15T14:32:01.123Z",
  "level": "error",
  "service": "payment-service",
  "traceId": "abc123def456",
  "spanId": "span789",
  "userId": "usr_42",
  "message": "Payment processing failed",
  "error": "InsufficientFundsError",
  "orderId": "ord_123",
  "amount": 15000,
  "currency": "BRL",
  "duration_ms": 340,
  "environment": "production"
}
```

**Log best practices:**
- Always structured (JSON), never unstructured text
- Include correlation/trace IDs in every log line
- Log level discipline: ERROR for things that need attention, WARN for degradation, INFO for business events, DEBUG for troubleshooting (off in prod by default)
- Never log PII, passwords, tokens, or full credit card numbers
- Include context: who (user), what (action), where (service), result
- Use consistent field names across all services

### 2. Metrics — How much / how fast

Numeric measurements aggregated over time.

**The Four Golden Signals (Google SRE):**

| Signal | What it measures | Example metric |
|--------|-----------------|----------------|
| **Latency** | Time to serve a request | `http_request_duration_seconds` |
| **Traffic** | Demand on the system | `http_requests_total` |
| **Errors** | Rate of failed requests | `http_requests_errors_total` |
| **Saturation** | How "full" the system is | `cpu_usage_percent`, `memory_usage_percent` |

**USE Method (for infrastructure):**
- **U**tilization — % of resource capacity used
- **S**aturation — Queue depth, waiting work
- **E**rrors — Error count per resource

**RED Method (for services):**
- **R**ate — Requests per second
- **E**rrors — Errors per second
- **D**uration — Latency distribution (p50, p90, p99)

### 3. Traces — How requests flow

Distributed traces show the path of a request across services.

```
[Gateway] ──200ms──> [Auth Service] ──50ms──> [User DB]
     │
     └──300ms──> [Order Service] ──150ms──> [Payment Service] ──100ms──> [Stripe API]
                       │
                       └──80ms──> [Order DB]
```

**Tracing best practices:**
- Use OpenTelemetry (OTEL) as the instrumentation standard
- Propagate trace context across all service boundaries (HTTP headers, message queues)
- Add custom spans for business-critical operations
- Tag spans with relevant business context (user_id, order_id)
- Sample traces in production (100% is expensive; 1-10% is usually sufficient)

## SLOs, SLIs & SLAs

### Definitions

- **SLI (Service Level Indicator)**: A measurable metric — "what we measure"
- **SLO (Service Level Objective)**: A target for the SLI — "what we aim for"
- **SLA (Service Level Agreement)**: A contractual commitment — "what we promise (with consequences)"

Always: SLA ≤ SLO (your internal target should be stricter than your external commitment)

### Defining Good SLOs

**Step 1: Identify critical user journeys**
```
- User login
- Search products
- Place order / make payment
- View dashboard / reports
```

**Step 2: Define SLIs for each journey**

| Journey | SLI Type | Measurement |
|---------|----------|-------------|
| Login | Availability | % of login requests returning 2xx in <500ms |
| Search | Latency | p99 latency of search requests |
| Payment | Correctness | % of payments processed without error |
| Dashboard | Freshness | % of data points updated within 5 minutes |

**Step 3: Set SLO targets**

```markdown
## Payment Service SLOs

Availability: 99.95% of requests succeed (2xx) per rolling 30 days
  → Error budget: 21.6 minutes of downtime per month

Latency: 99% of requests complete in <500ms per rolling 30 days
  → p99 target: 500ms

Correctness: 99.99% of payments processed correctly
  → Max 1 incorrect payment per 10,000
```

### Error Budgets

```
Error Budget = 1 - SLO target

If SLO = 99.95% availability:
  Error budget = 0.05% = 21.6 minutes/month

Budget remaining > 50%: Ship features freely
Budget remaining 20-50%: Proceed cautiously, prioritize reliability
Budget remaining < 20%: Freeze features, focus on reliability
Budget exhausted: Full stop on feature work until resolved
```

## Alerting Strategy

### Alert Hierarchy

```
Page (wake someone up):
  → SLO breach: error budget burn rate is critical
  → Complete service outage
  → Data loss / corruption risk
  → Security incident indicators

Notify (Slack/email, business hours):
  → SLO warning: burning budget faster than expected
  → Elevated error rates (not yet SLO breach)
  → Resource approaching capacity (>80%)
  → Certificate expiring within 14 days
  → Dependency degradation

Log (for investigation, no notification):
  → Individual request failures
  → Background job retries
  → Cache miss rate changes
  → Minor latency increases
```

### Alert Quality Rules

- **Every alert must be actionable** — if the on-call can't do anything, it shouldn't page
- **Alert on symptoms, not causes** — "error rate >5%" not "CPU >90%" (high CPU might be fine)
- **Use burn rate alerts for SLOs** — a 1% error rate for 5 minutes is different from 1% for 5 hours
- **Alert fatigue kills** — if you're ignoring alerts, you have too many or they're wrong
- **Every page should have a runbook link** — what to check, what to do, who to escalate to

### Burn Rate Alerting

```
Fast burn (page immediately):
  14.4x burn rate over 1 hour = will exhaust 30-day budget in 2 days

Slow burn (notify):
  3x burn rate over 6 hours = will exhaust budget in 10 days

Ticket:
  1x burn rate over 3 days = on track to exhaust budget
```

## Dashboard Design

### Service Dashboard Template

Every service should have a dashboard with:

```markdown
## Row 1: SLO Status (the most important row)
- SLO compliance (current vs target)
- Error budget remaining (% and time)
- Burn rate (current)

## Row 2: Golden Signals
- Request rate (RPS) with baseline overlay
- Error rate (%) with SLO threshold line
- Latency (p50, p90, p99) with SLO threshold
- Saturation (CPU, memory, connections)

## Row 3: Dependencies
- Downstream service health
- Database response time and connection pool
- Cache hit rate
- Message queue depth and consumer lag

## Row 4: Business Metrics
- Transactions per minute
- Revenue processed (if applicable)
- Active users
- Feature-specific metrics
```

### Dashboard Best Practices

- Use consistent time ranges across panels (default: last 6 hours)
- Add threshold lines on every chart (green/yellow/red zones)
- Include a "compared to last week" overlay for spotting anomalies
- Don't put more than 12 panels on a dashboard (cognitive overload)
- Separate "overview" dashboard from "deep-dive" per-service dashboards
- Use variables/dropdowns for environment, service, region filtering

## OpenTelemetry Setup

### Instrumentation Checklist

```markdown
- [ ] OTEL SDK installed and configured in all services
- [ ] Trace context propagated in HTTP headers (W3C traceparent)
- [ ] Trace context propagated in message queue headers
- [ ] Custom spans for business-critical operations
- [ ] Metrics exported (Prometheus format or OTLP)
- [ ] Logs enriched with trace ID and span ID
- [ ] Sampling configured (head-based or tail-based)
- [ ] Collector deployed (OTEL Collector for routing/processing)
- [ ] Exporters configured (Jaeger/Tempo for traces, Prometheus for metrics, Loki for logs)
```

## On-Call Best Practices

- Rotation should be at least 2 people per shift
- Maximum on-call duration: 1 week, then mandatory handoff
- On-call handoff document: outstanding issues, recent changes, known risks
- Post-incident review for every page (not just major incidents)
- Measure: pages per week, time-to-acknowledge, time-to-resolve
- Target: fewer than 2 pages per on-call shift (otherwise, fix the system)
