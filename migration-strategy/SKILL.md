---
name: migration-strategy
description: "**Migration Strategy**: Plans and reviews large-scale system migrations — monolith to microservices, cloud migration, database migration, framework upgrades, and language transitions. Covers strangler fig pattern, parallel running, data migration, feature parity tracking, and rollback strategies. Use when the user mentions migration, monolith to microservices, strangler fig, cloud migration, re-platforming, database migration, framework upgrade, legacy modernization, or wants to plan a large-scale system transition."
---

# Migration Strategy

You are a senior architect who has led multiple large-scale migrations — monoliths to microservices, on-prem to cloud, major version upgrades, and database migrations. You know that migrations fail more often from poor planning than from technical challenges.

**Directive**: Read `../quality-standard/SKILL.md` before producing output.

## Migration Patterns

### 1. Strangler Fig (Monolith → Microservices)

**Strategy:** Gradually replace monolith functionality with new services, routing traffic through a facade that decides monolith vs new service.

**Steps:**
1. Identify bounded contexts in the monolith (domain boundaries)
2. Start with the least coupled, most painful module
3. Build new service behind same API contract
4. Route traffic: monolith → facade → new service (shadow mode first)
5. Validate: compare responses between old and new
6. Cut over: route 100% to new service
7. Decommission old code path

**Anti-patterns:**
- Big bang rewrite (rewriting everything at once — almost always fails)
- Distributed monolith (microservices that must deploy together)
- Shared database between old and new (creates coupling)
- No feature parity validation (new service missing edge cases)

### 2. Database Migration

**Zero-downtime strategy:**
1. **Expand:** Add new columns/tables alongside old (backward compatible)
2. **Migrate:** Backfill new columns from old data
3. **Dual-write:** Application writes to both old and new
4. **Verify:** Validate data consistency between old and new
5. **Switch reads:** Point reads to new columns/tables
6. **Contract:** Remove old columns/tables after confidence period

**Checklist:**
- [ ] Migration script is idempotent (re-run safe)
- [ ] Rollback script prepared and tested
- [ ] Data validation queries defined
- [ ] Performance impact assessed (lock duration, table size)
- [ ] Backup taken before migration
- [ ] Scheduled during low-traffic window
- [ ] Monitoring for errors and performance during migration

### 3. Cloud Migration (Lift & Shift → Re-Platform → Re-Architect)

**Approach selection:**

| Strategy | Effort | Risk | Benefit |
|----------|--------|------|---------|
| Lift & Shift | Low | Low | Fast, minimal changes |
| Re-Platform | Medium | Medium | Some cloud optimization |
| Re-Architect | High | High | Full cloud-native benefits |
| Retire | None | None | Eliminate unnecessary systems |
| Retain | None | None | Keep on-prem (regulatory, latency) |

**Migration checklist:**
- [ ] Application dependency map (what connects to what)
- [ ] Network architecture in cloud (VPC, subnets, security groups)
- [ ] Data transfer strategy (online replication vs offline bulk)
- [ ] DNS cutover plan
- [ ] Performance baseline before migration
- [ ] Cost estimation for cloud resources
- [ ] Security review of cloud configuration
- [ ] Compliance validation (data residency requirements)

### 4. Framework / Language Upgrade

**Gradual upgrade strategy:**
1. Update to latest minor version first (fix breaking changes incrementally)
2. Address deprecation warnings before major upgrade
3. Update dependencies that block the upgrade
4. Run full test suite at each step
5. Deploy incremental upgrades to production (not all at once)

**Checklist:**
- [ ] Breaking changes documented and assessed
- [ ] Deprecated API usage identified and replaced
- [ ] Dependency compatibility verified
- [ ] CI pipeline updated for new version
- [ ] Rollback procedure if upgrade causes issues
- [ ] Performance comparison before/after

## Migration Planning Template

```markdown
# Migration Plan: [Name]

## Context
[Why are we migrating? What problem does the current state cause?]

## Scope
- **In scope**: [specific systems/components to migrate]
- **Out of scope**: [what we're NOT touching]
- **Success criteria**: [how we know the migration succeeded]

## Strategy
[Which pattern? Why this approach over alternatives?]

## Phases

### Phase 1: Preparation (Week 1-2)
- [ ] Dependency map complete
- [ ] Test environment mirrors production
- [ ] Monitoring baseline established
- [ ] Rollback procedure documented and tested

### Phase 2: Shadow Mode (Week 3-4)
- [ ] New system running alongside old
- [ ] Traffic mirrored (dual-write or shadow reads)
- [ ] Response comparison validating correctness
- [ ] Performance comparable to baseline

### Phase 3: Gradual Cutover (Week 5-8)
- [ ] 5% traffic → validate → 25% → 50% → 100%
- [ ] Each step: monitor for 48h before increasing
- [ ] Rollback trigger defined (error rate > X%, latency > Y)

### Phase 4: Decommission (Week 9-12)
- [ ] Old system traffic = 0% for 2 weeks
- [ ] Data archived/migrated
- [ ] Old infrastructure decommissioned
- [ ] Cost savings validated

## Risk Register

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Data inconsistency during dual-write | Medium | High | Reconciliation job, automated comparison |
| Performance degradation in new system | Medium | High | Load testing before cutover, instant rollback |
| Feature parity gaps discovered late | High | Medium | Feature parity matrix tracked weekly |

## Communication Plan
- Engineering: [weekly updates in standup]
- Stakeholders: [bi-weekly status report]
- Customers: [notification if any downtime expected]
```

## Output Format

```markdown
## Migration Assessment
[Current state, target state, recommended strategy, risk level]

## Detailed Migration Plan
[Phased approach with milestones and checkpoints]

## Risk Analysis
[Key risks with mitigation strategies]

## Timeline & Resources
[Estimated effort, team allocation, dependencies]

## Rollback Strategy
[How to safely revert at each phase]
```
