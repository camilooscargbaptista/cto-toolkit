---
name: multi-tenancy
description: "Multi-tenant architecture patterns: row-level, schema-level, database-level isolation and tenant routing"
category: architecture
preferred-model: opus
min-confidence: 0.8
depends-on: [database-review, security-review]
estimated-tokens: 6000
triggers:
  domains: [saas]
  frameworks: [postgres, prisma, typeorm]
tags: [multi-tenant, saas, isolation, sharding]
---

# Multi-Tenancy Patterns

## When to Use
- Building SaaS that serves multiple organizations/clients
- Designing data isolation between tenants (companies, stations, fleets)
- Choosing the right isolation level for your compliance needs

## Isolation Models

### 1. Row-Level (Shared Everything)
```
┌──────────────────────────────┐
│         Single Database       │
│  ┌────────────────────────┐  │
│  │     users table         │  │
│  │  tenant_id │ name       │  │
│  │  ──────────┼──────────  │  │
│  │  company_a │ Alice      │  │
│  │  company_b │ Bob        │  │
│  └────────────────────────┘  │
└──────────────────────────────┘

Pros: Simple, cheap, easy to maintain
Cons: Risk of data leakage, shared resources
Best for: Small/medium SaaS, cost-sensitive
```

**Implementation — TypeORM Global Scope**:
```typescript
// Middleware injects tenant
@Injectable()
export class TenantMiddleware implements NestMiddleware {
  use(req: AuthRequest, res: Response, next: NextFunction) {
    req.tenantId = req.user?.companyId;
    next();
  }
}

// Repository automatically filters by tenant
@Injectable()
export class TenantAwareRepository<T> {
  constructor(private repo: Repository<T>) {}

  findAll(tenantId: string): Promise<T[]> {
    return this.repo.find({ where: { tenant_id: tenantId } as any });
  }

  // CRITICAL: NEVER allow findAll without tenantId
}

// Global subscriber (safety net)
@EventSubscriber()
export class TenantSubscriber implements EntitySubscriberInterface {
  afterLoad(entity: any) {
    // Verify tenant match on every load (paranoia mode)
  }
  
  beforeInsert(event: InsertEvent<any>) {
    // Auto-inject tenant_id
    if (event.entity && !event.entity.tenant_id) {
      event.entity.tenant_id = getCurrentTenantId();
    }
  }
}
```

### 2. Schema-Level (Shared Database, Separate Schemas)
```
┌──────────────────────────────┐
│         Single Database       │
│  ┌──────────┐ ┌──────────┐  │
│  │ schema_a  │ │ schema_b  │  │
│  │  users    │ │  users    │  │
│  │  orders   │ │  orders   │  │
│  └──────────┘ └──────────┘  │
└──────────────────────────────┘

Pros: Good isolation, shared infra cost
Cons: Schema migration complexity, connection pooling
Best for: Medium SaaS, regulated industries
```

### 3. Database-Level (Full Isolation)
```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  DB_A     │  │  DB_B     │  │  DB_C     │
│  users    │  │  users    │  │  users    │
│  orders   │  │  orders   │  │  orders   │
└──────────┘  └──────────┘  └──────────┘

Pros: Maximum isolation, per-tenant backup/restore
Cons: Expensive, complex management
Best for: Enterprise, healthcare, financial
```

## Tenant Routing

```typescript
// Router that selects connection based on tenant
@Injectable()
export class TenantConnectionManager {
  private connections = new Map<string, Connection>();

  async getConnection(tenantId: string): Promise<Connection> {
    if (this.connections.has(tenantId)) {
      return this.connections.get(tenantId);
    }

    const config = await this.configService.getTenantDbConfig(tenantId);
    const connection = await createConnection({
      name: tenantId,
      ...config,
    });

    this.connections.set(tenantId, connection);
    return connection;
  }
}
```

## Data Isolation Checklist

- [ ] Every query filters by tenant_id (row-level)
- [ ] No global admin endpoints return cross-tenant data without authorization
- [ ] Indexes include tenant_id as first column
- [ ] Foreign keys respect tenant boundaries
- [ ] Bulk operations scoped to single tenant
- [ ] Logging includes tenant context
- [ ] Testing includes cross-tenant access attempts
- [ ] Backup/restore can be done per-tenant
