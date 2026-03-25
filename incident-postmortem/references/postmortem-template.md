# Postmortem Template

## Incident Report: [TITLE]

**Date**: YYYY-MM-DD
**Duration**: HH:MM - HH:MM (X hours Y minutes)
**Severity**: P1 / P2 / P3
**Author**: [name]
**Status**: Draft / In Review / Final

---

## Executive Summary
[2-3 sentences: what happened, impact, how it was resolved]

## Timeline (UTC)

| Time | Event |
|------|-------|
| HH:MM | [First signal/alert] |
| HH:MM | [Incident acknowledged by on-call] |
| HH:MM | [Diagnosis started] |
| HH:MM | [Root cause identified] |
| HH:MM | [Fix applied] |
| HH:MM | [Service restored] |
| HH:MM | [Monitoring confirmed recovery] |

## Impact

| Metric | Value |
|--------|-------|
| Users affected | [number or percentage] |
| Revenue impact | [estimated if applicable] |
| Duration | [total downtime] |
| Requests failed | [count or rate] |
| Data loss | [none / description] |
| SLO impact | [error budget consumed] |

## Root Cause

[Clear, technical explanation of why this happened. Not "who" — focus on "what" system failed and "why" the failure wasn't prevented.]

### Contributing Factors
1. [Factor 1 — e.g., "Missing circuit breaker on payment gateway call"]
2. [Factor 2 — e.g., "Alert threshold too high, delayed detection by 15 minutes"]
3. [Factor 3 — e.g., "No runbook for this failure mode"]

## Resolution

[What was done to fix the immediate problem]

```
# Commands or changes applied
[actual commands, config changes, code fixes]
```

## Detection

- **How was it detected?** [Alert / Customer report / Internal observation]
- **Time to detect**: [X minutes from first signal to acknowledgment]
- **Could we have detected sooner?** [Yes/No — how?]

## Lessons Learned

### What went well
- [Good thing 1]
- [Good thing 2]

### What went wrong
- [Bad thing 1]
- [Bad thing 2]

### Where we got lucky
- [Lucky thing 1 — these are important to document]

## Action Items

| Priority | Action | Owner | Due Date | Status |
|----------|--------|-------|----------|--------|
| P1 | [Immediate fix to prevent recurrence] | [name] | [date] | TODO |
| P2 | [Improve detection/alerting] | [name] | [date] | TODO |
| P2 | [Add missing test/validation] | [name] | [date] | TODO |
| P3 | [Long-term improvement] | [name] | [date] | TODO |

## References
- [Link to monitoring dashboard during incident]
- [Link to Slack thread]
- [Link to PR with fix]
- [Link to related incidents]

---

## Review Checklist
- [ ] Timeline is accurate and complete
- [ ] Root cause is identified (not just symptoms)
- [ ] Contributing factors include systemic issues
- [ ] Action items have owners and due dates
- [ ] "Where we got lucky" section is populated
- [ ] No blame language (focus on systems, not people)
- [ ] Reviewed by at least 2 team members
