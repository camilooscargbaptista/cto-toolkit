# SOC2 Evidence Templates

## Control Categories & Required Evidence

### CC6 — Logical Access Controls

#### CC6.1 — Access Control Policies
```markdown
## Evidence: Access Control Policy
- [ ] Document: Access Control Policy (version, approval date)
- [ ] Role definitions matrix (role → permissions)
- [ ] Access request/approval workflow documented
- [ ] Quarterly access review logs (date, reviewer, findings)
- [ ] Terminated employee access removal logs (< 24h SLA)
```

#### CC6.2 — Authentication Mechanisms
```markdown
## Evidence: Authentication Controls
- [ ] MFA enforcement configuration screenshot
- [ ] Password policy configuration (min length, complexity, rotation)
- [ ] Account lockout policy (attempts, duration)
- [ ] SSO/SAML configuration (if applicable)
- [ ] Service account inventory with rotation schedule
```

#### CC6.3 — Production Access
```markdown
## Evidence: Production Access
- [ ] List of users with production access (quarterly snapshot)
- [ ] Justification for each production access grant
- [ ] Segregation of duties: dev team ≠ prod access (or compensating control)
- [ ] Break-glass procedure for emergency access
- [ ] VPN/bastion host configuration
```

### A1 — Availability

#### A1.1 — System Availability
```markdown
## Evidence: Availability Controls
- [ ] SLA document with uptime target (e.g., 99.9%)
- [ ] Uptime monitoring dashboard (last 12 months)
- [ ] Incident log with response times
- [ ] Redundancy architecture diagram (multi-AZ, failover)
- [ ] Load balancer configuration
```

#### A1.2 — Disaster Recovery
```markdown
## Evidence: DR Controls
- [ ] DR plan document (version, last test date)
- [ ] RTO (Recovery Time Objective): [X hours]
- [ ] RPO (Recovery Point Objective): [X hours]
- [ ] Last DR test results and date
- [ ] Backup schedule and retention policy
- [ ] Backup restoration test results (quarterly)
```

### CC7 — System Operations

#### CC7.1 — Monitoring
```markdown
## Evidence: Monitoring
- [ ] Monitoring tool configuration (CloudWatch, DataDog, etc.)
- [ ] Alert rules and thresholds
- [ ] On-call rotation schedule
- [ ] Escalation procedures
- [ ] Incident response plan
```

#### CC7.2 — Change Management
```markdown
## Evidence: Change Management
- [ ] Change management policy document
- [ ] Code review requirement (PR approval rules)
- [ ] CI/CD pipeline configuration (automated testing)
- [ ] Deployment approval workflow
- [ ] Rollback procedures
- [ ] Change log (last 3 months)
```

### CC8 — Risk Management

```markdown
## Evidence: Risk Assessment
- [ ] Annual risk assessment document
- [ ] Risk register with severity, likelihood, mitigation
- [ ] Vulnerability scanning reports (monthly)
- [ ] Penetration test report (annual)
- [ ] Third-party vendor risk assessments
```

## Audit Preparation Timeline

| Weeks Before | Action |
|-------------|--------|
| 12 | Identify control gaps, assign owners |
| 8 | Begin collecting evidence artifacts |
| 6 | Internal pre-audit review |
| 4 | Remediate gaps found in pre-audit |
| 2 | Final evidence organization |
| 0 | Auditor on-site / remote audit |

## Common Audit Findings to Preempt

1. **Missing access reviews** — Do quarterly, document every review
2. **Terminated employees still have access** — Automate deprovisioning
3. **No change approval for production** — Require PR approvals in Git
4. **Backups never tested** — Restore test quarterly
5. **No vendor risk assessment** — Assess all critical vendors annually
6. **Incomplete incident log** — Log even minor incidents
