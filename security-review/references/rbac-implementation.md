# RBAC Implementation Guide

Guia de implementação de Role-Based Access Control para aplicações multi-tenant.

## Modelos de Permissão

### 1. Role-Based (RBAC) — Simples
```
User → Role → Permissions (implícitas)

ADMIN   → pode tudo
GERENTE → pode CRUD + reports
OPERADOR → pode CRUD operacional
VIEWER  → somente leitura
```

### 2. Permission-Based (mais granular)
```
User → Role → Permission[]

Role: GERENTE
Permissions: [
  'users:read',
  'users:create',
  'refueling:read',
  'refueling:create',
  'refueling:validate',
  'reports:read',
  'reports:export',
]
```

### 3. Attribute-Based (ABAC) — Enterprise
```
User → Policy → Condition → Action

Policy: "Manager can approve refuelings under R$5000 for their own station"
Condition: user.role === 'MANAGER' 
        && resource.station_id === user.station_id
        && resource.amount < 5000
Action: ALLOW
```

## Schema de Banco

```sql
-- Roles
CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) UNIQUE NOT NULL,
  description TEXT,
  is_system BOOLEAN DEFAULT false, -- roles do sistema não podem ser deletadas
  created_at TIMESTAMP DEFAULT NOW()
);

-- Permissions
CREATE TABLE permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  resource VARCHAR(50) NOT NULL,   -- 'users', 'refueling', 'reports'
  action VARCHAR(20) NOT NULL,     -- 'create', 'read', 'update', 'delete'
  description TEXT,
  UNIQUE(resource, action)
);

-- Role ↔ Permission
CREATE TABLE role_permissions (
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  permission_id UUID REFERENCES permissions(id) ON DELETE CASCADE,
  PRIMARY KEY (role_id, permission_id)
);

-- User ↔ Role (com scope)
CREATE TABLE user_roles (
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
  scope_type VARCHAR(20),    -- 'global', 'company', 'station'
  scope_id UUID,             -- ID da company/station (null = global)
  granted_by UUID REFERENCES users(id),
  granted_at TIMESTAMP DEFAULT NOW(),
  PRIMARY KEY (user_id, role_id, COALESCE(scope_id, '00000000-0000-0000-0000-000000000000'))
);
```

## Implementação NestJS

### Decorator de Permissões
```typescript
// permission.decorator.ts
export const RequirePermissions = (...permissions: string[]) =>
  SetMetadata('permissions', permissions);

// Uso
@RequirePermissions('refueling:validate', 'refueling:read')
@Get('refuelings')
async list() { ... }
```

### Guard de Permissões
```typescript
@Injectable()
export class PermissionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private permissionService: PermissionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const required = this.reflector.getAllAndOverride<string[]>('permissions', [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!required || required.length === 0) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    // Carregar permissões do cache (Redis) ou banco
    const userPermissions = await this.permissionService.getUserPermissions(
      user.userId,
      user.scopeId, // company_id ou station_id
    );

    return required.every(perm => userPermissions.includes(perm));
  }
}
```

### Cache de Permissões
```typescript
@Injectable()
export class PermissionService {
  constructor(
    @InjectRepository(UserRole) private userRoleRepo: Repository<UserRole>,
    private cacheManager: Cache,
  ) {}

  async getUserPermissions(userId: string, scopeId?: string): Promise<string[]> {
    const cacheKey = `permissions:${userId}:${scopeId || 'global'}`;

    // Tentar cache (TTL: 5 minutos)
    const cached = await this.cacheManager.get<string[]>(cacheKey);
    if (cached) return cached;

    // Buscar do banco
    const permissions = await this.userRoleRepo
      .createQueryBuilder('ur')
      .innerJoin('role_permissions', 'rp', 'rp.role_id = ur.role_id')
      .innerJoin('permissions', 'p', 'p.id = rp.permission_id')
      .select("CONCAT(p.resource, ':', p.action)", 'permission')
      .where('ur.user_id = :userId', { userId })
      .andWhere('(ur.scope_id = :scopeId OR ur.scope_id IS NULL)', { scopeId })
      .getRawMany();

    const permList = permissions.map(p => p.permission);
    await this.cacheManager.set(cacheKey, permList, 300); // 5 min TTL

    return permList;
  }

  // Invalidar cache quando role mudar
  async invalidateUserCache(userId: string): Promise<void> {
    const keys = await this.cacheManager.store.keys(`permissions:${userId}:*`);
    await Promise.all(keys.map(key => this.cacheManager.del(key)));
  }
}
```

## Multi-Tenant Scoping

```typescript
// Middleware que injeta scope do tenant
@Injectable()
export class TenantScopeMiddleware implements NestMiddleware {
  use(req: AuthRequest, res: Response, next: NextFunction) {
    if (req.user) {
      // Scope baseado no header ou no token
      req.tenantScope = {
        companyId: req.user.companyId,
        stationId: req.headers['x-station-id'] as string,
      };
    }
    next();
  }
}

// Guard que valida acesso ao recurso no scope correto
@Injectable()
export class ResourceOwnershipGuard implements CanActivate {
  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const resourceId = request.params.id;
    const resource = await this.findResource(resourceId);

    // Admin global → acesso total
    if (request.user.roles.includes('SUPER_ADMIN')) return true;

    // Verificar se recurso pertence ao tenant do usuário
    return resource.company_id === request.user.companyId;
  }
}
```

## Audit Trail

```typescript
// Decorator para logging de ações sensíveis
export function AuditLog(action: string) {
  return function (target: any, key: string, descriptor: PropertyDescriptor) {
    const original = descriptor.value;
    descriptor.value = async function (...args: any[]) {
      const result = await original.apply(this, args);
      await this.auditService.log({
        action,
        userId: args[0]?.user?.userId,
        resourceId: args[0]?.params?.id,
        timestamp: new Date(),
        details: { method: key },
      });
      return result;
    };
  };
}
```

## Checklist de Implementação

- [ ] Roles definidas no banco (não hardcoded)
- [ ] Permissões granulares por resource:action
- [ ] Cache de permissões (Redis, 5 min TTL)
- [ ] Invalidação de cache ao alterar roles
- [ ] Scope multi-tenant (company/station)
- [ ] Ownership check em recursos individuais
- [ ] Audit trail para ações sensíveis
- [ ] Super admin bypass documentado
- [ ] Testes para cada combinação role × permissão
