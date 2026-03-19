---
name: incident-postmortem
description: "**Incident Response & Postmortem**: Creates blameless postmortem documents and incident response runbooks. Use this skill whenever the user wants to write a postmortem, incident report, root cause analysis (RCA), create an incident runbook, document an outage, or analyze what went wrong in production. Trigger when the user mentions 'postmortem', 'incident', 'outage', 'RCA', 'root cause', 'production issue', 'downtime', 'war room', 'on-call', or wants to improve their incident response process. Also trigger when the user asks to create escalation procedures or SLA documentation."
---

# Incident Response & Postmortem

This skill helps create two key artifacts: **postmortem documents** (after an incident) and **incident runbooks** (before incidents happen). Both are critical for building a mature engineering org that learns from failures.

## Postmortem Document

The goal of a postmortem is to learn, not to blame. Every production incident is an opportunity to make the system more resilient.

### Template

```markdown
# Incident Postmortem: [Short Title]

**Date of Incident**: [YYYY-MM-DD]
**Duration**: [Start time → End time, with timezone]
**Severity**: [P0/P1/P2/P3]
**Author**: [Name]
**Status**: Draft | Reviewed | Action Items Complete

## Executive Summary
[3-4 sentences max. What happened, who was affected, how long it lasted,
and how it was resolved. A VP should be able to read only this and understand
the incident.]

## Impact
- **Users affected**: [Number or percentage]
- **Revenue impact**: [If measurable]
- **SLA impact**: [Did we breach any SLAs?]
- **Data impact**: [Any data loss or corruption?]

## Timeline
[Chronological sequence of events. Use UTC timestamps.]

| Time (UTC) | Event |
|------------|-------|
| 14:00 | Deploy of v2.3.1 begins |
| 14:05 | Error rate spikes to 15% in monitoring |
| 14:12 | On-call engineer paged |
| 14:15 | War room opened |
| ... | ... |
| 15:30 | Rollback deployed, error rate returns to normal |

## Root Cause
[Technical explanation of what went wrong at the deepest level.
Not "the deploy broke things" but "the migration script assumed
all users had a `preferences` column, but 12% of legacy accounts
created before 2023 didn't have this column, causing NULL reference
exceptions in the UserService.getPreferences() path."]

## Contributing Factors
[What made the incident worse or longer than it needed to be?
Examples: missing monitoring, slow detection, unclear runbooks,
missing feature flags, no canary deployment.]

## Resolution
[What was done to fix the immediate issue. Be specific about
the exact change, not just "we rolled back."]

## Detection
- **How was it detected?** [Alert? Customer report? Someone noticed?]
- **Time to detect**: [Minutes from incident start to first alert/awareness]
- **Could we have detected it sooner?** [What monitoring would have caught it faster?]

## Action Items

| Priority | Action | Owner | Due Date | Status |
|----------|--------|-------|----------|--------|
| P0 | Add NULL check in UserService.getPreferences() | @alice | 2024-01-20 | Done |
| P1 | Add monitoring for migration script failures | @bob | 2024-01-25 | In Progress |
| P2 | Create runbook for database migration rollback | @carol | 2024-02-01 | Not Started |

## Lessons Learned
- **What went well**: [Things that helped during the incident]
- **What went poorly**: [Things that made the incident worse]
- **Where we got lucky**: [Things that could have made it much worse]

## Appendix
[Relevant logs, graphs, metrics screenshots, Slack threads]
```

### Postmortem Writing Guidelines

- **Blameless, always.** Focus on systems and processes, not individuals. Replace "Alice forgot to check" with "The deployment process didn't include a validation step for."
- **Be specific about the root cause.** Keep asking "why?" until you reach a systemic issue, not a human error. Human error is a symptom, not a root cause.
- **Action items must be SMART.** Specific, measurable, with an owner and due date. "Improve monitoring" is not an action item. "Add alerting for error rate >5% on /api/users endpoint with 5-minute window" is.
- **Include "where we got lucky."** This surfaces near-misses that could become future incidents.

---

## Incident Runbook

Runbooks are step-by-step guides for handling known failure modes. They're written for the on-call engineer at 3am who's half-awake and stressed.

### Runbook Template

```markdown
# Runbook: [Service/System] — [Failure Scenario]

**Last Updated**: [Date]
**Owner**: [Team]
**Related Alerts**: [Alert names that trigger this runbook]

## Symptoms
[What does this failure look like? What alerts fire?
What do users experience?]

## Severity Assessment
[How to determine if this is P0/P1/P2/P3.
Include metrics thresholds.]

## Immediate Actions (First 5 minutes)
1. [Step-by-step — assume the reader is stressed and unfamiliar]
2. [Include exact commands to run, with copy-pasteable snippets]
3. [State expected output for each step]

## Diagnosis
[How to determine the root cause. Decision tree format works well.]

- If [condition A] → Go to section X
- If [condition B] → Go to section Y
- If unclear → Escalate to [team/person]

## Resolution Steps
[For each known cause, step-by-step fix]

## Rollback Procedure
[How to undo changes if the fix makes things worse]

## Escalation
| Level | Contact | When to escalate |
|-------|---------|-----------------|
| L1 | On-call engineer | Auto-paged |
| L2 | Team lead | If not resolved in 30 min |
| L3 | VP Engineering | If P0 lasting >1 hour |

## Post-Incident
[Checklist after the incident is resolved:
customer communication, postmortem scheduling, etc.]
```

### Runbook Guidelines

- **Write for the worst case.** The reader is tired, stressed, and may not know this system well. Be explicit. Don't assume knowledge.
- **Include exact commands.** Not "restart the service" but `kubectl rollout restart deployment/user-service -n production`.
- **State expected outputs.** After each command, describe what success looks like so the reader can verify each step worked.
- **Keep it updated.** A wrong runbook is worse than no runbook. Add a review cadence (quarterly is a good default).
