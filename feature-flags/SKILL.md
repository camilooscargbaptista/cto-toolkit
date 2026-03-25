---
name: feature-flags
description: "Feature flag strategies, rollout patterns, kill switches and flag lifecycle management"
---

# Feature Flags

## When to Use
- Gradual rollout of new features (canary, percentage)
- A/B testing
- Kill switch for risky features in production
- Trunk-based development (merge without releasing)
- Customer-specific feature enablement

## Flag Types

| Type | Purpose | Lifespan | Example |
|------|---------|----------|---------|
| **Release** | Control feature rollout | Short (days-weeks) | `ENABLE_NEW_BILLING_UI` |
| **Experiment** | A/B testing | Medium (weeks) | `EXPERIMENT_CHECKOUT_V2` |
| **Ops** | Kill switch | Permanent | `ENABLE_EXTERNAL_PAYMENTS` |
| **Permission** | Per-customer features | Permanent | `PREMIUM_ANALYTICS` |

## Implementation

### Simple (Config-based)
```typescript
// Feature flags from environment/config
const FLAGS = {
  ENABLE_NEW_BILLING: process.env.FF_NEW_BILLING === 'true',
  ENABLE_DARK_MODE: process.env.FF_DARK_MODE === 'true',
};

// Usage
if (FLAGS.ENABLE_NEW_BILLING) {
  return this.newBillingService.process(order);
} else {
  return this.legacyBillingService.process(order);
}
```

### Advanced (Database-backed)
```typescript
@Entity('feature_flags')
class FeatureFlag {
  @PrimaryColumn()
  key: string;                    // 'ENABLE_NEW_BILLING'

  @Column({ default: false })
  enabled: boolean;               // Global toggle

  @Column({ type: 'int', default: 0 })
  rollout_percentage: number;     // 0-100

  @Column({ type: 'simple-array', nullable: true })
  allowed_tenants: string[];      // Specific tenants

  @Column({ type: 'simple-array', nullable: true })
  allowed_users: string[];        // Specific users

  @Column({ type: 'timestamp', nullable: true })
  expires_at: Date;               // Auto-disable date
}

@Injectable()
export class FeatureFlagService {
  constructor(
    @InjectRepository(FeatureFlag) private repo: Repository<FeatureFlag>,
    private cache: CacheManager,
  ) {}

  async isEnabled(
    key: string,
    context: { userId?: string; tenantId?: string },
  ): Promise<boolean> {
    const flag = await this.getFlag(key);
    if (!flag || !flag.enabled) return false;

    // Check expiration
    if (flag.expires_at && flag.expires_at < new Date()) return false;

    // Check specific tenant
    if (flag.allowed_tenants?.includes(context.tenantId)) return true;

    // Check specific user
    if (flag.allowed_users?.includes(context.userId)) return true;

    // Check percentage rollout (deterministic by userId)
    if (flag.rollout_percentage > 0 && context.userId) {
      const hash = this.hashUserId(context.userId);
      return (hash % 100) < flag.rollout_percentage;
    }

    // No specific rules + globally enabled
    return flag.allowed_tenants?.length === 0 && flag.allowed_users?.length === 0;
  }

  private hashUserId(userId: string): number {
    let hash = 0;
    for (let i = 0; i < userId.length; i++) {
      hash = ((hash << 5) - hash) + userId.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash);
  }
}
```

## Rollout Strategy

```
10% → 25% → 50% → 100%
 │        │       │       │
 └─ Monitor metrics for 24h at each stage
    If error rate increases → rollback to previous %
    If stable → advance to next %
```

### Rollout Checklist
- [ ] Feature flag created with `enabled: false`
- [ ] Internal testing (allowed_users: [team])
- [ ] Staging validation
- [ ] 10% rollout (canary)
- [ ] Monitor for 24h (error rate, latency, user feedback)
- [ ] 50% rollout
- [ ] Monitor for 24h
- [ ] 100% rollout
- [ ] Remove flag code after 2 weeks of 100%

## Flag Lifecycle

```
Created → Testing → Canary → Rollout → Full → CLEANUP
                                              │
                                              └── Remove flag code
                                                  Remove from database
                                                  Delete from config
                                                  
CRITICAL: Flags without cleanup become tech debt!
Schedule cleanup date at creation.
```

## Anti-Patterns

- ❌ Nested flags (`if (flagA && flagB && !flagC)`)
- ❌ Flags that never get cleaned up (> 3 months old)
- ❌ Testing only with flags ON (also test OFF)
- ❌ Using flags for permanent business logic (use permissions)
- ❌ Too many flags (> 20 active = confusion)

## Quality Gates

- [ ] Every flag has an owner and expiration date
- [ ] Cleanup task created when flag reaches 100%
- [ ] Dashboard showing all active flags and their rollout %
- [ ] Alert if flag is > 90 days old without cleanup
- [ ] Both flag-on and flag-off paths tested
