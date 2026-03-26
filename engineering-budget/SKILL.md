---
name: engineering-budget
description: "Engineering budget planning, headcount forecasting, infrastructure cost modeling and ROI analysis"
category: management
preferred-model: sonnet
min-confidence: 0.8
depends-on: [engineering-metrics]
estimated-tokens: 4000
triggers: {}
tags: [budget, headcount, roi, planning]
---

# Engineering Budget & Resource Planning

## When to Use
- Annual/quarterly budget planning for engineering
- Headcount forecasting and hiring plans
- Infrastructure cost modeling and optimization
- Calculating ROI for technical projects/initiatives
- Justifying technical investments to stakeholders

## Budget Categories

### 1. People Costs (typically 60-75% of eng budget)
```
Headcount Plan:
┌──────────────────────────────────────────────────────┐
│ Role          │ Current │ Q+1 │ Q+2 │ Q+3 │ Q+4    │
│ Sr Engineer   │    5    │  6  │  7  │  7  │   8    │
│ Mid Engineer  │    3    │  4  │  4  │  5  │   5    │
│ Jr Engineer   │    2    │  2  │  3  │  3  │   3    │
│ Tech Lead     │    1    │  1  │  2  │  2  │   2    │
│ DevOps/SRE    │    1    │  1  │  1  │  2  │   2    │
│ QA            │    1    │  1  │  2  │  2  │   2    │
├──────────────────────────────────────────────────────┤
│ Total         │   13    │ 15  │ 19  │ 21  │  22    │
│ Cost/month    │  XXk    │ XXk │ XXk │ XXk │  XXk   │
└──────────────────────────────────────────────────────┘
```

### 2. Infrastructure (typically 15-25%)
- Cloud hosting (AWS/GCP/Azure)
- Database services (RDS, Atlas)
- CDN, storage, bandwidth
- Monitoring & observability (Datadog, New Relic)
- CI/CD (GitHub Actions, CircleCI)
- Security tools (Snyk, SonarQube)

### 3. Tools & Services (typically 5-15%)
- IDE licenses (JetBrains, GitHub Copilot)
- SaaS integrations (Stripe, SendGrid, Twilio)
- Design tools (Figma)
- Project management (Jira, Linear)
- Communication (Slack)

## ROI Calculation Framework

```
ROI = (Net Benefit / Cost) × 100

Where:
  Net Benefit = Revenue Gain + Cost Savings - Implementation Cost
  
Example — Implementing caching layer:
  Revenue Gain:     R$0 (não gera receita direta)
  Cost Savings:     R$15k/mês (redução de 40% na conta AWS)
  Implementation:   R$30k (2 engineers × 2 weeks)
  
  Payback Period:   30k / 15k = 2 meses
  Annual ROI:       ((15k × 12) - 30k) / 30k × 100 = 500%
```

### ROI Template for Technical Projects

```markdown
# Investment Case: [Project Name]

## Problem
[What business problem this solves]

## Proposed Solution
[Technical approach in 2-3 sentences]

## Costs
| Item | One-time | Monthly | Annual |
|------|----------|---------|--------|
| Engineering time | R$XX | - | - |
| Infrastructure | - | R$XX | R$XX |
| Licenses | - | R$XX | R$XX |
| **Total** | **R$XX** | **R$XX** | **R$XX** |

## Benefits
| Benefit | Monthly Value | Annual Value |
|---------|--------------|-------------|
| [Quantified benefit 1] | R$XX | R$XX |
| [Quantified benefit 2] | R$XX | R$XX |
| **Total** | **R$XX** | **R$XX** |

## Key Metrics
- Payback period: X months
- 3-year ROI: XX%
- Risk level: Low/Medium/High

## Non-Quantifiable Benefits
- [Developer productivity improvement]
- [Reduced incident frequency]
- [Better user experience]
```

## Cost Per Transaction Model

```
For SaaS/platform businesses:

Unit Economics:
  Infrastructure cost = R$X/month
  Transactions/month = N
  Cost per transaction = R$X / N

  Target: Cost per transaction should DECREASE as volume grows
  
  Warning signs:
  - Cost per transaction increasing → scaling problem
  - Cost per transaction > 10% of revenue per transaction → margin problem
```

## Budget Review Cadence

| Frequency | What to Review |
|-----------|---------------|
| Weekly | Cloud cost anomalies (spikes > 20%) |
| Monthly | Actual vs budget variance by category |
| Quarterly | Headcount plan, tool renewals, capacity planning |
| Annually | Full budget rebuild, vendor renegotiation, strategy alignment |

## Output Format

```markdown
# Engineering Budget: [Period]

## Summary
| Category | Budget | Actual | Variance |
|----------|--------|--------|---------|
| People | R$XX | R$XX | +/-X% |
| Infrastructure | R$XX | R$XX | +/-X% |
| Tools & Services | R$XX | R$XX | +/-X% |
| **Total** | **R$XX** | **R$XX** | **+/-X%** |

## Key Variances
1. [Explanation of significant variances]

## Recommendations
1. [Budget adjustments needed]
2. [Cost optimization opportunities]
```
