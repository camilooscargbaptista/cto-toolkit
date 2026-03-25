# Severity Matrix

## Severity Levels

| Severity | Name | Impact | Response Time | Resolution Target |
|----------|------|--------|--------------|-------------------|
| **S1** | Critical | Service down, data loss, security breach | 5 min | 1 hour |
| **S2** | Major | Degraded performance, partial outage, feature broken | 15 min | 4 hours |
| **S3** | Minor | Non-critical feature broken, workaround exists | 1 hour | Next business day |
| **S4** | Low | Cosmetic issue, minor inconvenience | Next business day | Next sprint |

## S1 — Critical

### Criteria (ANY of these)
- Complete service outage (API returning 5xx for all users)
- Data loss or corruption confirmed
- Security breach (unauthorized access to PII/financial data)
- Payment processing completely down
- Database unreachable and not recovering

### Response Protocol
1. **Immediately**: Acknowledge in monitoring tool (PagerDuty/OpsGenie)
2. **Within 5 min**: Open war room (Slack channel or video call)
3. **Within 10 min**: Incident commander designated
4. **Within 15 min**: Status page updated ("Investigating")
5. **Continuous**: Updates every 15 minutes to stakeholders
6. **After resolution**: Postmortem within 48 hours

### Communication Template
```
🔴 S1 INCIDENT — [Service Name]
Status: Investigating / Identified / Monitoring / Resolved
Impact: [what users are experiencing]
Started: HH:MM UTC
Updates: Every 15 minutes in #incident-YYYYMMDD
Commander: @person
```

## S2 — Major

### Criteria (ANY of these)
- Response time > 5x normal for 10+ minutes
- Error rate > 5% for 10+ minutes
- One major feature completely broken (e.g., billing, reports)
- Database replication lag > 30 seconds
- Message queue backlog growing unbounded

### Response Protocol
1. **Within 15 min**: On-call acknowledges and begins investigation
2. **Within 30 min**: Root cause identified or escalation to L2
3. **Within 1 hour**: Fix deployed or workaround in place
4. Stakeholders notified via Slack
5. Postmortem within 1 week

## S3 — Minor

### Criteria
- Non-critical feature degraded
- Intermittent errors (< 1% error rate)
- Performance degradation without user impact
- Workaround available and communicated

### Response Protocol
1. **Within 1 hour**: Triaged during business hours
2. **Within 4 hours**: Investigation started
3. **Next business day**: Fix planned
4. Track as bug in issue tracker

## S4 — Low

### Criteria
- Cosmetic issues
- Minor UX inconvenience
- Performance slightly below optimal
- Documentation outdated

### Response Protocol
1. Log in issue tracker
2. Prioritize in next sprint
3. Fix as part of normal development

## Escalation Matrix

```
Time without resolution:
  S1: 15min → Team Lead → 30min → Eng Manager → 1h → CTO
  S2: 30min → Team Lead → 2h → Eng Manager
  S3: 4h → Team Lead
  S4: No escalation
```

## Decision Tree

```
Is the service completely down?
  YES → S1
  NO  → Are users significantly impacted?
          YES → Is there a workaround?
                  NO  → S2
                  YES → S3
          NO  → S4
```
