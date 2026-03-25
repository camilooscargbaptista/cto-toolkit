---
name: vendor-evaluation
description: "Build vs Buy scorecard, vendor lock-in risk, SLA negotiation and vendor management"
---

# Vendor Evaluation & Build vs Buy Analysis

## When to Use
- Evaluating whether to build in-house or buy a SaaS solution
- Comparing multiple vendor options for a specific need
- Assessing vendor lock-in risk for existing integrations
- Negotiating SLA terms with a vendor

## Build vs Buy Decision Framework

### Score each dimension (1-5):

| Dimension | Build | Buy |
|-----------|-------|-----|
| **Core competency** | Is this your core business? (5=yes) | Is this commodity functionality? (5=yes) |
| **Time to market** | How fast can you build? (1=slow, 5=fast) | How fast can you integrate? (1=slow, 5=fast) |
| **Total Cost (3yr)** | Dev salary + maintenance + infra | License + integration + migration risk |
| **Customization need** | How unique are your requirements? (5=very) | Does the vendor fit 80%+ of needs? (5=yes) |
| **Team expertise** | Do you have the skills? (5=yes) | Is integration straightforward? (5=yes) |
| **Strategic value** | Does owning this give competitive advantage? (5=yes) | Is this a differentiator? (1=yes → build) |
| **Maintenance burden** | Can you sustain ongoing maintenance? (5=yes) | Is vendor reliable long-term? (5=yes) |

**Decision**: Sum scores. Higher score wins.
**Tie-breaker**: If core competency + strategic value > 7, BUILD. Otherwise, BUY.

## Vendor Evaluation Scorecard

### Technical Fit (40%)
- [ ] Covers 80%+ of functional requirements
- [ ] API quality (REST/GraphQL, documentation, versioning)
- [ ] SDK available for your stack (Node.js, Flutter, Java)
- [ ] Webhook/event support for real-time integration
- [ ] Data export capability (avoid lock-in)
- [ ] Performance SLA matches your needs (latency, throughput)
- [ ] Multi-region/multi-tenant support

### Security & Compliance (25%)
- [ ] SOC2 Type II certified
- [ ] LGPD/GDPR compliant
- [ ] Data encryption at rest and in transit
- [ ] SSO/SAML support
- [ ] Audit logging
- [ ] Data residency options (Brazil)
- [ ] Penetration test reports available

### Business Viability (20%)
- [ ] Company age > 3 years
- [ ] Funding/revenue stability
- [ ] Customer references in similar industry
- [ ] SLA with financial penalties
- [ ] Clear pricing model (no hidden costs)
- [ ] Exit clause and data portability

### Support & Operations (15%)
- [ ] 24/7 support availability
- [ ] Average response time < 4 hours
- [ ] Status page with uptime history
- [ ] Incident communication process
- [ ] Dedicated account manager (for enterprise)
- [ ] Documentation quality

## Vendor Lock-in Risk Matrix

| Risk Level | Indicators | Mitigation |
|-----------|-----------|------------|
| 🟢 Low | Standard APIs, data export, open formats | Normal evaluation |
| 🟡 Medium | Proprietary SDK, limited export, custom format | Abstract with adapter pattern |
| 🔴 High | No data export, vendor-specific language, deep integration | Build abstraction layer, plan exit strategy |

## SLA Negotiation Checklist

- [ ] Uptime guarantee (99.9% minimum for production)
- [ ] Response time SLA by severity (P1: 15min, P2: 1h, P3: 4h)
- [ ] Credit/refund for SLA breach
- [ ] Planned maintenance windows (and exclusion from SLA)
- [ ] Data backup and recovery guarantees
- [ ] Notification lead time for breaking changes
- [ ] Contract termination terms (data return timeline)

## Output Format

```markdown
# Vendor Evaluation: [Vendor Name] for [Use Case]

## Summary
**Recommendation**: BUY / BUILD / DEFER
**Confidence**: High / Medium / Low
**Total Score**: XX/100

## Scores
| Category | Score | Weight | Weighted |
|----------|-------|--------|----------|
| Technical Fit | X/10 | 40% | X |
| Security | X/10 | 25% | X |
| Business Viability | X/10 | 20% | X |
| Support | X/10 | 15% | X |

## Key Risks
1. [Risk with mitigation]

## Lock-in Assessment
[Low/Medium/High with justification]

## Cost Comparison (3 years)
| | Build | Buy |
|--|-------|-----|
| Year 1 | $X | $X |
| Year 2 | $X | $X |
| Year 3 | $X | $X |
| Total | $X | $X |
```
