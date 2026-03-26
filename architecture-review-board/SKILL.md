---
name: architecture-review-board
description: "ARB process design, RFC governance, decision log and technical review workflows"
triggers:
  score-below: 60
preferred-model: opus
min-confidence: 0.4
depends-on: [design-patterns, adr]
category: management
estimated-tokens: 6000
tags: [arb, governance, rfc]
---

# Architecture Review Board (ARB)

## When to Use
- Establishing a technical decision governance process
- Reviewing proposed architecture changes before implementation
- Maintaining consistency across teams and services
- Building organizational knowledge through decision logs

## ARB Process

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Proposal  │───►│  Review   │───►│ Decision  │───►│ Record   │
│ (RFC)     │    │ (Meeting) │    │ (Vote)    │    │ (ADR)    │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
   Author         ARB Board       Approve/        Decision
   writes          reviews        Reject/          logged
                                  Defer
```

### RFC Template
```markdown
# RFC: [Title]

**Author**: [name]
**Date**: YYYY-MM-DD
**Status**: Draft / In Review / Approved / Rejected

## Problem Statement
[What problem are we solving and why now?]

## Proposed Solution
[Technical approach with diagrams]

## Alternatives Considered
| Option | Pros | Cons |
|--------|------|------|
| Option A | ... | ... |
| Option B | ... | ... |

## Impact Analysis
- Services affected: [list]
- Database changes: [yes/no, describe]
- API changes: [breaking/non-breaking]
- Performance impact: [estimate]
- Security implications: [describe]

## Migration Plan
[How to get from current state to proposed state]

## Risks
1. [Risk with mitigation]

## Open Questions
1. [Question that needs ARB input]
```

### Review Criteria
- [ ] Aligns with existing architecture and tech stack
- [ ] Considers security implications
- [ ] Has a migration/rollback plan
- [ ] Performance impact assessed
- [ ] Cost implications understood
- [ ] Team has expertise to implement and maintain
- [ ] Doesn't introduce unnecessary technology

### When ARB Review is Required
| Change Type | Review Required? |
|------------|-----------------|
| New external dependency | ✅ Yes |
| New database | ✅ Yes |
| New programming language | ✅ Yes |
| New microservice | ✅ Yes |
| Architecture pattern change | ✅ Yes |
| API breaking change | ✅ Yes |
| Internal refactoring | ❌ No (team decision) |
| Library update | ❌ No (unless major version) |
| Bug fixes | ❌ No |
| New feature (existing patterns) | ❌ No |

## Decision Log

```markdown
| ID | Date | Title | Decision | Rationale |
|----|------|-------|----------|-----------|
| ARB-001 | 2026-01 | Database choice | PostgreSQL | ACID, JSON support, team expertise |
| ARB-002 | 2026-02 | API framework | NestJS | TypeScript, modular, good ORM integration |
| ARB-003 | 2026-03 | Mobile framework | Flutter | Cross-platform, Dart performance, single codebase |
```

## Meeting Format (30-45 minutes)

1. **RFC Presentation** (10 min): Author presents proposal
2. **Q&A** (10 min): Board asks questions
3. **Discussion** (10 min): Alternatives, risks, concerns
4. **Decision** (5 min): Approve / Reject / Defer / Request Changes
5. **Action Items** (5 min): Who does what by when

## Board Composition
- CTO or VP Engineering (chair)
- Senior/Staff Engineers (rotating monthly)
- Security representative (for security-impacting RFCs)
- Product representative (for customer-impacting changes)

## Quality Gates

- [ ] All architectural decisions documented as ADRs
- [ ] RFC submitted at least 3 business days before ARB meeting
- [ ] Meeting minutes recorded and shared
- [ ] Decision log accessible to all engineers
- [ ] Quarterly review of past decisions (are they holding up?)
