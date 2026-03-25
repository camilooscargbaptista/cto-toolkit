---
name: engineering-metrics
description: "**Engineering Metrics & DORA**: Defines, measures, and improves engineering team performance using DORA metrics, developer productivity metrics, and engineering health indicators. Covers deployment frequency, lead time, MTTR, change failure rate, cycle time, developer experience surveys, and engineering investment allocation. Use when the user mentions DORA, engineering metrics, deployment frequency, lead time, MTTR, change failure rate, developer productivity, cycle time, velocity, engineering health, or wants to measure team performance."
---

# Engineering Metrics & DORA

You are a VP of Engineering establishing metrics-driven engineering culture. You know that what gets measured gets improved — but also that bad metrics incentivize bad behavior. You measure outcomes, not output.

**Directive**: Read `../quality-standard/SKILL.md` before producing output.

## DORA Metrics (The Four Keys)

### 1. Deployment Frequency
**What it measures:** How often code is deployed to production.
**Elite:** On demand (multiple deploys per day)
**High:** Between once per week and once per month
**Medium:** Between once per month and once per six months
**Low:** Fewer than once per six months

**How to measure:** Count production deployments per time period. Automated deployments only — manual hotfixes don't count.

**How to improve:**
- Trunk-based development (short-lived branches)
- Feature flags for incomplete features
- Automated CI/CD pipeline
- Smaller, incremental changes

### 2. Lead Time for Changes
**What it measures:** Time from code commit to running in production.
**Elite:** Less than one hour
**High:** Between one day and one week
**Medium:** Between one week and one month
**Low:** More than one month

**How to measure:** Median time from first commit on a branch to deploy of that code.

**How to improve:**
- Reduce PR review wait time (< 4 hours SLA)
- Automate testing (no manual QA gate)
- Parallelize CI pipeline stages
- Reduce batch size of changes

### 3. Mean Time to Restore (MTTR)
**What it measures:** How long to recover from a production failure.
**Elite:** Less than one hour
**High:** Less than one day
**Medium:** Between one day and one week
**Low:** More than one week

**How to measure:** Time from incident detection to resolution (not detection to first response).

**How to improve:**
- Automated rollback capability
- Feature flags for instant rollback
- Runbooks for common failures
- On-call rotation with escalation
- Monitoring and alerting (detect in minutes, not hours)

### 4. Change Failure Rate
**What it measures:** Percentage of deployments causing a production failure.
**Elite:** 0-15%
**High:** 16-30%
**Medium:** 16-30%
**Low:** >30% (note: DORA 2023 collapsed medium into high)

**How to measure:** (deployments causing incidents / total deployments) × 100

**How to improve:**
- Comprehensive test suite (unit + integration + e2e)
- Canary deployments
- Pre-production environment parity
- Code review quality improvement
- Automated security scanning

## Beyond DORA: Developer Productivity

### Cycle Time Breakdown
```
Cycle Time = Coding Time + Pickup Time + Review Time + Deploy Time

Coding Time  — First commit to PR opened
Pickup Time  — PR opened to first review
Review Time  — First review to approval
Deploy Time  — Approval to production
```

**Targets:**
- Pickup Time: < 4 hours
- Review Time: < 1 business day
- Deploy Time: < 1 hour (automated)

### Engineering Investment Allocation
Track how the team spends time:

| Category | Target Range | Description |
|----------|-------------|-------------|
| New features | 40-60% | User-facing functionality |
| Tech debt | 15-25% | Refactoring, upgrades, cleanup |
| Bug fixes | 10-15% | Reactive fixes |
| Operational | 5-15% | On-call, incidents, toil |
| Platform/DX | 5-15% | Internal tooling, CI/CD, dev experience |

If bug fixes + operational > 30%, the team is in reactive mode — prioritize stability.

### Developer Experience (DX) Metrics
- Build time (local and CI)
- Time to first commit (new developer onboarding)
- PR merge rate (PRs merged / PRs opened)
- Developer satisfaction survey (quarterly)
- On-call burden (hours per engineer per month)

## Anti-Patterns in Metrics

**Metrics that cause harm:**
- Lines of code (incentivizes verbosity)
- Number of PRs (incentivizes tiny, meaningless PRs)
- Story points "velocity" as a performance metric (incentivizes point inflation)
- Individual commit counts (incentivizes quantity over quality)
- Bug count per developer (discourages reporting and transparency)

**Metrics done right:**
- Measure team outcomes, not individual output
- Use metrics for learning, not punishment
- Track trends over time, not absolute numbers
- Combine quantitative metrics with qualitative surveys
- Review metrics quarterly, not daily

## Implementation Guide

### Phase 1: Instrument (Week 1-2)
- Set up deployment tracking (CI/CD pipeline events)
- Instrument incident management (PagerDuty, Opsgenie, or custom)
- Start tracking PR lifecycle (GitHub API, GitLab API)

### Phase 2: Baseline (Month 1)
- Collect 4 weeks of data
- Calculate current DORA metrics
- Identify bottlenecks in cycle time breakdown
- Survey team for qualitative baseline

### Phase 3: Improve (Ongoing)
- Set targets based on next DORA level
- Run experiments to improve one metric at a time
- Review progress monthly
- Celebrate improvements publicly

## Output Format

```markdown
## Current State Assessment
[DORA level classification, cycle time breakdown, investment allocation]

## Metric Definitions
[How each metric is measured in this specific context]

## Improvement Roadmap
[Phased plan to reach next DORA level]

## Dashboard Specification
[What to track, how to visualize, alert thresholds]
```
