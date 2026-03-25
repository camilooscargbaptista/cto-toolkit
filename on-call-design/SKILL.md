---
name: on-call-design
description: "On-call rotation design, escalation tiers, runbook standards and burnout prevention"
---

# On-Call Design & Incident Response

## When to Use
- Setting up on-call rotation for the first time
- Improving existing on-call process (too many pages, burnout)
- Designing escalation tiers
- Standardizing runbooks across teams

## Rotation Design

### Tier Model
```
Tier 1 (First Responder):
  Who: Engineer on rotation (weekly cycle)
  SLA: Acknowledge in 5 min, respond in 15 min
  Scope: All production alerts for their service(s)
  
Tier 2 (Specialist):
  Who: Senior engineer / tech lead
  SLA: Respond in 30 min
  Scope: Escalated issues, cross-service problems

Tier 3 (Leadership):
  Who: Engineering manager / CTO
  SLA: Respond in 1 hour
  Scope: Major incidents, customer-facing outages, data breaches
```

### Schedule Patterns

| Pattern | Team Size | Pros | Cons |
|---------|-----------|------|------|
| **Weekly rotation** | 4+ engineers | Simple, predictable | Long shifts |
| **Follow-the-sun** | 8+ (multi-TZ) | No night pages | Coordination overhead |
| **Primary/Secondary** | 6+ | Backup coverage | Requires 2 people always |
| **Business hours only** | 3+ | No night pages | Gaps in coverage |
| **Hybrid** | 5+ | Balanced | Complex scheduling |

### Recommended: Weekly Primary/Secondary
```
Week 1: Alice (primary), Bob (secondary)
Week 2: Bob (primary), Carol (secondary)
Week 3: Carol (primary), Dave (secondary)
Week 4: Dave (primary), Alice (secondary)

Rules:
- Primary: first responder, expected to resolve or escalate
- Secondary: backup if primary doesn't acknowledge in 10 min
- Handoff: Monday 10am (overlap with both people)
- Minimum 4 weeks between primary shifts
- Never on-call during PTO
```

## Escalation Policy

```yaml
# PagerDuty/OpsGenie-style escalation
escalation_policy:
  name: "Backend API"
  repeat_count: 2  # Retry full chain 2x before giving up
  
  steps:
    - timeout_minutes: 5
      targets:
        - type: on_call_primary
          
    - timeout_minutes: 10
      targets:
        - type: on_call_secondary
        
    - timeout_minutes: 15
      targets:
        - type: team_lead
        - notification: slack_channel_critical
        
    - timeout_minutes: 30
      targets:
        - type: engineering_manager
        - notification: phone_call
```

## Compensation & Fairness

### On-Call Compensation Options
1. **Additional pay**: X% bonus per week on-call
2. **Comp time**: 1 day off per week of on-call
3. **Reduced next sprint load**: fewer story points during on-call week
4. **Rotation bonus**: annual bonus based on number of rotations

### Fairness Metrics to Track
- Pages per person per month (should be roughly equal)
- Night pages per person (should be minimized)
- Mean time to acknowledge (by person — coaching, not blame)
- On-call satisfaction survey (quarterly)

## Burnout Prevention

### Warning Signs
- Engineer consistently paged > 5x per week
- Same alert firing repeatedly without fix
- Engineer avoiding on-call or swapping shifts frequently
- Decreased code quality during on-call weeks

### Mitigation Strategies
- **Noise reduction**: Review and tune alerts monthly (delete noisy, unused alerts)
- **Automation**: Every page that happens 3+ times → automate the response
- **Protected time**: No feature work expected during on-call shift
- **Blameless postmortems**: Focus on systems, not people
- **Manager one-on-ones**: Explicitly ask about on-call burden

## Runbook Standards

Every service MUST have:
1. **Service overview**: What it does, who depends on it
2. **Architecture diagram**: Dependencies, data flow
3. **Health check commands**: How to verify service is working
4. **Common failure modes**: Top 5 alerts with resolution steps
5. **Contact list**: Team lead, DB admin, infra lead
6. **Escalation criteria**: When to wake someone up vs wait

## Quality Gates

- [ ] Every production service has an on-call rotation
- [ ] Escalation policy covers all hours (24/7 or business-hours-with-documentation)
- [ ] Runbooks exist for top 10 alerts by frequency
- [ ] On-call handoff includes incident review from previous week
- [ ] Alert noise < 5 actionable pages per week (average)
- [ ] Compensation model documented and agreed
- [ ] Quarterly on-call satisfaction survey conducted
