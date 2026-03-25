# JWT & Authentication Patterns

Guia completo de implementação de autenticação com JWT, refresh tokens, e session management.

## Arquitetura de Tokens

```
┌──────────────────────────────────────────────────────────────┐
│                    TOKEN LIFECYCLE                             │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  Login → Access Token (15min) + Refresh Token (7-30 dias)     │
│                                                                │
│  Request → Authorization: Bearer <access_token>                │
│                                                                │
│  Token Expired → POST /auth/refresh { refresh_token }         │
│              → New Access Token + New Refresh Token (rotate)  │
│                                                                │
│  Logout → Revoke Refresh Token (delete from DB)               │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

## Access Token — Best Practices

```typescript
// Payload mínimo (não colocar dados sensíveis)
interface JwtPayload {
  sub: string;        // user ID (UUID)
  email: string;      // email
  roles: string[];    // ['ADMIN', 'OPERATOR']
  iat: number;        // issued at
  exp: number;        // expiration (15-30 min)
  jti: string;        // unique token ID (for revocation)
}

// Geração
const token = this.jwtService.sign(payload, {
  secret: process.env.JWT_SECRET,
  expiresIn: '15m',
  algorithm: 'HS256', // ou RS256 para microserviços
});
```

### Regras
- Expiração curta: 15-30 minutos
- Payload mínimo: ID, email, roles — SEM senhas, tokens, PII
- Armazenamento: `httpOnly` cookie (web) ou secure storage (mobile)
- Algoritmo: HS256 para monolito, RS256 para microserviços (validação sem secret)
- NUNCA armazenar em localStorage (vulnerável a XSS)

## Refresh Token — Best Practices

```typescript
// Entity de Refresh Token
@Entity('refresh_tokens')
class RefreshToken {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  user_id: string;

  @Column()
  token_hash: string; // bcrypt hash do token

  @Column()
  device_info: string; // fingerprint do dispositivo

  @Column({ type: 'timestamp' })
  expires_at: Date;

  @Column({ default: false })
  revoked: boolean;

  @Column({ type: 'timestamp', nullable: true })
  revoked_at: Date;
}
```

### Regras
- Armazenado hasheado no banco (bcrypt)
- Rotação obrigatória: cada uso gera novo par (access + refresh)
- Device binding: vincular ao dispositivo/user-agent
- Família de tokens: se token antigo usado → revogar toda a família (detecção de roubo)
- Expiração: 7 dias (mobile), 30 dias (web com "remember me")

## Token Refresh Flow com Detecção de Roubo

```typescript
async refreshToken(oldRefreshToken: string): Promise<TokenPair> {
  // 1. Buscar token no banco
  const stored = await this.refreshTokenRepo.findOne({
    where: { token_hash: await bcrypt.hash(oldRefreshToken) },
  });

  // 2. Token não existe → possível roubo
  if (!stored) {
    // Revogar TODA a família de tokens do usuário
    await this.refreshTokenRepo.update(
      { user_id: stored.user_id },
      { revoked: true, revoked_at: new Date() },
    );
    throw new UnauthorizedException('Token reuse detected');
  }

  // 3. Token já revogado → roubo confirmado
  if (stored.revoked) {
    await this.revokeAllUserTokens(stored.user_id);
    throw new UnauthorizedException('Token reuse detected');
  }

  // 4. Token expirado
  if (stored.expires_at < new Date()) {
    throw new UnauthorizedException('Refresh token expired');
  }

  // 5. Revogar token atual
  stored.revoked = true;
  stored.revoked_at = new Date();
  await this.refreshTokenRepo.save(stored);

  // 6. Gerar novo par
  const newAccessToken = this.generateAccessToken(stored.user_id);
  const newRefreshToken = await this.generateRefreshToken(stored.user_id);

  return { accessToken: newAccessToken, refreshToken: newRefreshToken };
}
```

## RBAC (Role-Based Access Control)

### Implementação NestJS

```typescript
// Decorator
export const Roles = (...roles: string[]) => SetMetadata('roles', roles);

// Guard
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<string[]>('roles', [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles) return true;

    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}

// Uso
@Get('admin/users')
@UseGuards(AuthGuard, RolesGuard)
@Roles('ADMIN', 'GERENTE')
async listUsers() { ... }
```

### Hierarquia de roles recomendada
```
SUPER_ADMIN → ADMIN → GERENTE → OPERADOR → VIEWER
     ↓          ↓         ↓          ↓          ↓
   Tudo    Config+    Equipe+    CRUD+      Leitura
           Billing    Reports    Operações
```

## Password Security

```typescript
// Hashing com bcrypt
import * as bcrypt from 'bcrypt';

const SALT_ROUNDS = 12; // Aumentar conforme hardware melhora

// Hash
const hashedPassword = await bcrypt.hash(plainPassword, SALT_ROUNDS);

// Verify
const isValid = await bcrypt.compare(plainPassword, hashedPassword);

// Política de senha
const PASSWORD_POLICY = {
  minLength: 8,
  requireUppercase: true,
  requireLowercase: true,
  requireNumber: true,
  requireSpecial: false, // Controverso — NIST 800-63B não recomenda
  maxLength: 128,        // Prevenir DoS via bcrypt
};
```

## Rate Limiting para Auth

```typescript
// NestJS com @nestjs/throttler
@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60,    // janela de 60 segundos
      limit: 5,   // máximo 5 requests
    }),
  ],
})

// Endpoint com rate limit customizado
@Throttle({ default: { limit: 3, ttl: 300 } }) // 3 tentativas em 5 min
@Post('login')
async login() { ... }

// Após 5 falhas consecutivas → bloquear conta por 15min
// Após 10 falhas → bloquear conta + notificar por email
```

## Session Management Checklist

- [ ] Session ID regenerado após login
- [ ] HttpOnly + Secure + SameSite=Strict/Lax nos cookies
- [ ] Idle timeout: 15-30 min
- [ ] Absolute timeout: 8-24 horas
- [ ] Concurrent session control (máximo N sessões)
- [ ] Logout invalida sessão no servidor (não só apaga cookie)
- [ ] CSRF token para operações mutáveis (se usando cookies)
