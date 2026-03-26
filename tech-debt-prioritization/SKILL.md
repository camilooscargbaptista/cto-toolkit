---
name: tech-debt-prioritization
description: "Framework for identifying, quantifying and prioritizing technical debt with RICE scoring"
category: architecture
preferred-model: opus
min-confidence: 0.4
triggers:
  anti-patterns: [god_class, spaghetti_code, circular_dependency]
  score-below: 65
  dimensions:
    modularity: 55
    coupling: 55
depends-on: [design-patterns, database-review]
estimated-tokens: 7000
tags: [tech-debt, refactoring, prioritization, roi]
---

# Tech Debt Prioritization

## When to Use
- Sprint planning: deciding which tech debt to tackle
- Quarterly planning: allocating tech debt budget
- Stakeholder communication: justifying tech debt investment
- Codebase health assessment

## Tech Debt Quadrant (Martin Fowler)

```
                    Deliberate              Inadvertent
              ┌─────────────────────┬─────────────────────┐
  Reckless    │ "We don't have time │ "What's a           │
              │  for tests"         │  repository pattern?"│
              │  → High priority    │  → Training need     │
              ├─────────────────────┼─────────────────────┤
  Prudent     │ "Ship now, refactor │ "Now we know how    │
              │  next sprint"       │  it should be done"  │
              │  → Track + schedule │  → Natural evolution  │
              └─────────────────────┴─────────────────────┘
```

## Identification Checklist

### Code-Level Debt
- [ ] Functions > 50 lines (complexity)
- [ ] Files > 500 lines (god class)
- [ ] Duplicated code (> 3 occurrences)
- [ ] `// TODO`, `// FIXME`, `// HACK` comments
- [ ] `@ts-ignore`, `any` types without justification
- [ ] Tests with `.skip()` or no assertions
- [ ] Dead code (unused functions, unreachable branches)

### Architecture-Level Debt
- [ ] Circular dependencies between modules
- [ ] Business logic in controllers/resolvers
- [ ] Database queries in non-repository layers
- [ ] Direct dependency on external services (no abstraction)
- [ ] Shared mutable state (global variables)
- [ ] Missing error boundaries

### Infrastructure Debt
- [ ] Manual deployment steps
- [ ] Missing monitoring for critical paths
- [ ] No automated backups or disaster recovery
- [ ] Outdated dependencies (> 2 major versions behind)
- [ ] Missing rate limiting on public APIs
- [ ] No CI/CD pipeline

## RICE Scoring for Prioritization

```
RICE Score = (Reach × Impact × Confidence) / Effort

Reach:      How many users/developers are affected? (1-10)
Impact:     How much does it improve things? (0.25=minimal, 0.5=low, 1=medium, 2=high, 3=massive)
Confidence: How sure are we of the estimates? (0.5=low, 0.8=medium, 1.0=high)
Effort:     Person-weeks to complete (1=1 week, 2=2 weeks, etc.)
```

### Example Prioritization

| Tech Debt Item | Reach | Impact | Confidence | Effort | RICE |
|---------------|-------|--------|------------|--------|------|
| Add TypeORM query logging | 8 | 2 | 0.8 | 1 | **12.8** |
| Refactor billing service | 5 | 3 | 0.8 | 4 | **3.0** |
| Upgrade NestJS v8→v10 | 10 | 1 | 0.5 | 3 | **1.7** |
| Remove dead code | 2 | 0.5 | 1.0 | 1 | **1.0** |
| Rewrite auth module | 6 | 2 | 0.5 | 8 | **0.75** |

**Rule**: Tackle highest RICE first.

## Cost of Delay

```
For items that block or slow down other work:

Cost of Delay = Impact per week × Duration until addressed

Example:
  "Slow CI/CD pipeline" (adds 20 min per deploy)
  Impact: 3 deploys/day × 20 min × 5 engineers = 5h/day wasted
  Weekly cost: ~R$5,000 in lost productivity
  Fix effort: 2 weeks (R$20,000)
  Payback: 4 weeks
  
  → HIGH PRIORITY: fix immediately
```

## Sprint Allocation Strategy

### The 20% Rule
```
Sprint capacity:    100 story points
Feature work:        80 points (80%)
Tech debt:           15 points (15%)
Innovation/learning:  5 points (5%)

Adjust based on debt severity:
  Low debt:     10% tech debt allocation
  Medium debt:  20% tech debt allocation
  High debt:    30% tech debt allocation (debt sprint)
  Critical:     50%+ (stop features, fix foundations)
```

## Communication Template

```markdown
# Tech Debt Investment Request: [Item]

## The Problem
[What is broken/suboptimal, in business terms]

## Business Impact
- Current cost: [R$/month in developer time, cloud costs, or incidents]
- Risk: [What could go wrong if not addressed]
- Opportunity cost: [What we can't build because of this debt]

## Proposed Solution
[Technical approach in 2-3 sentences]

## Investment Required
- Engineering time: [X person-weeks]
- Risk level: [Low/Medium/High]

## Expected Outcome
- [Measurable improvement 1]
- [Measurable improvement 2]
- Payback period: [X weeks/months]
```

## Quality Gates

- [ ] Tech debt inventory maintained (quarterly review)
- [ ] RICE scores assigned to all items > 1 story point
- [ ] Sprint allocation includes explicit tech debt budget
- [ ] Stakeholders informed about debt levels and risks
- [ ] "Debt sprints" scheduled when RICE scores indicate urgency
- [ ] No new deliberate debt without tracking issue
