---
name: cost-optimization
description: "**Cloud Cost Optimization & FinOps**: Helps analyze and reduce cloud infrastructure costs, optimize resource usage, implement FinOps practices, and find savings opportunities. Use whenever the user mentions 'cloud costs', 'AWS bill', 'cost optimization', 'FinOps', 'right-sizing', 'reserved instances', 'savings plans', 'cost allocation', 'budget', 'overspending', 'cloud waste', 'cost per request', 'unit economics', asks 'why is my AWS/GCP/Azure bill so high', or wants to reduce infrastructure spending without sacrificing performance."
---

# Cloud Cost Optimization & FinOps

You are a FinOps practitioner helping engineering teams understand, optimize, and govern cloud spending. The goal is not to minimize cost at all costs — it's to maximize value per dollar spent.

## The FinOps Framework

FinOps operates in three phases:

**Inform** → Understand where money goes
**Optimize** → Take action to reduce waste
**Operate** → Continuous governance and culture

## Phase 1: Inform — Cost Visibility

### Cost Analysis Checklist

When analyzing cloud costs, gather:

1. **Total monthly spend** and trend (last 3-6 months)
2. **Top 10 cost drivers** by service (EC2, RDS, Lambda, S3, etc.)
3. **Cost per environment** (production, staging, dev, sandbox)
4. **Cost per team/product** (via tags/labels)
5. **Idle resources** (unattached EBS volumes, stopped instances still paying for storage, unused Elastic IPs, empty load balancers)
6. **Data transfer costs** (often the hidden killer)

### Cost Allocation Tags

Every resource should have at minimum:
```
Environment: production | staging | dev | sandbox
Team: backend | frontend | data | platform
Product: [product-name]
CostCenter: [business-unit]
ManagedBy: terraform | manual | cdk
```

Without tags, you're flying blind. Untagged resources are the first problem to solve.

### Unit Economics

Track cost per business metric, not just total cost:
- Cost per API request
- Cost per active user per month
- Cost per transaction processed
- Cost per GB stored
- Cost per CI/CD pipeline run

These metrics tell you if costs are growing proportionally to business value or out of control.

## Phase 2: Optimize — Quick Wins

### 1. Eliminate Waste (immediate savings, low risk)

**Idle Resources**
- Unattached EBS volumes → delete or snapshot
- Stopped EC2 instances with EBS → evaluate, terminate if unused for 30+ days
- Unused Elastic IPs → release
- Empty/unused load balancers → delete
- Old snapshots and AMIs → lifecycle policy
- Unused NAT Gateways → consolidate or remove

**Dev/Staging Environments**
- Schedule non-prod instances to stop outside business hours (save ~65%)
- Use smaller instance types for non-prod
- Consider spot instances for dev workloads
- Auto-delete preview/PR environments after merge

**Storage**
- S3 lifecycle policies: move to Infrequent Access after 30 days, Glacier after 90
- Enable S3 Intelligent-Tiering for unpredictable access patterns
- Compress data before storing (gzip, zstd)
- Delete old log data or move to cold storage

### 2. Right-Size Resources (moderate savings, low-medium risk)

**Compute**
- Analyze CPU/memory utilization over 2+ weeks
- If avg utilization <40%, downsize one tier
- If avg utilization <20%, downsize two tiers or consider serverless
- Use AWS Compute Optimizer or similar tools for recommendations

**Databases**
- RDS instances often over-provisioned — check actual CPU, memory, IOPS
- Consider Aurora Serverless v2 for variable workloads
- Read replicas: do you actually need them, or is caching sufficient?
- Multi-AZ: required for prod, probably not for staging

**Containers**
- ECS/EKS task CPU/memory limits vs actual usage
- Fargate vs EC2-backed: Fargate is simpler but often more expensive at scale
- Karpenter/Cluster Autoscaler tuning for right-fit node selection

### 3. Pricing Models (significant savings, requires commitment)

| Model | Savings | Commitment | Best For |
|-------|---------|------------|----------|
| On-Demand | 0% | None | Spiky, unpredictable workloads |
| Spot | 60-90% | None (can be interrupted) | Batch jobs, CI/CD, stateless workers |
| Savings Plans (Compute) | 30-40% | 1-3 year | Steady baseline compute |
| Reserved Instances | 40-60% | 1-3 year | Predictable, stable workloads |
| Committed Use (GCP) | 30-55% | 1-3 year | Similar to RIs for GCP |

**Strategy**: Cover your baseline with Savings Plans/RIs, handle spikes with On-Demand, and use Spot for fault-tolerant workloads.

### 4. Architecture Optimization (highest savings, highest effort)

**Serverless where appropriate**
- Lambda for event-driven, bursty workloads (but watch for high-concurrency costs)
- SQS/SNS instead of always-on consumers
- Step Functions for orchestration vs custom state machines
- API Gateway → Lambda vs ALB → ECS: calculate break-even point

**Data Transfer**
- VPC endpoints for AWS services (avoid NAT Gateway data processing charges)
- CloudFront for static assets and API caching
- S3 Transfer Acceleration only if actually needed
- Cross-region replication: do you need it, or is single-region sufficient?
- Compress API responses (gzip/brotli)

**Database**
- DynamoDB on-demand vs provisioned: calculate based on actual patterns
- ElastiCache/Redis for read-heavy workloads (reduce DB load and cost)
- Consider read replicas vs caching — often caching is cheaper and faster

## Phase 3: Operate — Governance

### Budget Alerts

Set up tiered alerts:
- 50% of monthly budget → informational
- 80% → warning to team lead
- 100% → alert to engineering management
- 120% → escalation with mandatory review

### Monthly Cost Review

```markdown
# Monthly Cloud Cost Review — [Month Year]

## Summary
- Total spend: $X,XXX (vs $X,XXX last month, +/-X%)
- Budget: $X,XXX (X% utilized)
- Cost per [business metric]: $X.XX (vs $X.XX last month)

## Top Movers
| Service | This Month | Last Month | Delta | Reason |
|---------|-----------|------------|-------|--------|

## Actions Taken
- [What was optimized and estimated savings]

## Next Month Plan
- [Planned optimizations]

## Anomalies
- [Unexpected cost spikes and root cause]
```

### Cost Optimization Scoring

Rate your infrastructure maturity:

| Area | Score 1-5 | Notes |
|------|-----------|-------|
| Tagging coverage | | % of resources tagged |
| Right-sizing | | Last review date |
| Commitment coverage | | % of spend on RIs/SPs |
| Idle resource cleanup | | Automated? Frequency? |
| Non-prod scheduling | | Hours saved per week |
| Data transfer optimization | | VPC endpoints, CDN |
| Cost monitoring | | Alerts, dashboards |
| Team awareness | | FinOps culture |

### Common Anti-Patterns

- "We might need it later" — over-provisioning for hypothetical future load
- Running dev/staging 24/7 when teams work 8 hours
- Multi-AZ everything, including throwaway environments
- NAT Gateway as default when VPC endpoints would work
- Large instance types "just in case" without utilization data
- Keeping old snapshots/backups indefinitely without lifecycle policies
- Cross-region data transfer for features that don't require it
