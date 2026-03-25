# OWASP Top 10 — Checklist Técnico

Referência completa para revisão de código contra as 10 vulnerabilidades mais críticas (OWASP 2021).

## A01:2021 — Broken Access Control

### O que verificar
- Deny by default: toda rota exige auth a menos que explicitamente pública
- Ownership check: `user.id === resource.ownerId` antes de retornar dados
- IDOR (Insecure Direct Object Reference): IDs sequenciais expostos na URL → usar UUIDs
- Horizontal privilege escalation: usuário A não acessa dados do usuário B
- Vertical privilege escalation: `OPERATOR` não acessa rotas de `ADMIN`
- CORS configurado com origin whitelist (não `*` em produção)
- Rate limiting em rotas sensíveis (login, reset password, API keys)

### Patterns de correção
```typescript
// ❌ Ruim — sem ownership check
@Get(':id')
async findOne(@Param('id') id: string) {
  return this.service.findById(id);
}

// ✅ Bom — verifica ownership
@Get(':id')
async findOne(@Param('id') id: string, @Req() req: AuthRequest) {
  const resource = await this.service.findById(id);
  if (resource.ownerId !== req.user.userId) {
    throw new ForbiddenException();
  }
  return resource;
}
```

### Checklist rápido
- [ ] Todas as rotas protegidas por `@UseGuards(AuthGuard)`
- [ ] Verificação de ownership em GET/PUT/DELETE de recursos individuais
- [ ] RBAC com decorators (`@Roles('ADMIN')`)
- [ ] UUIDs em vez de IDs sequenciais nas URLs
- [ ] CORS com origin whitelist
- [ ] Rate limiting em autenticação

---

## A02:2021 — Cryptographic Failures

### O que verificar
- Dados sensíveis em trânsito: TLS 1.2+ obrigatório
- Dados sensíveis em repouso: AES-256 para PII (CPF, CNPJ, cartões)
- Hashing de senhas: bcrypt/scrypt/argon2 com salt (NUNCA MD5/SHA1)
- Chaves e secrets: em variáveis de ambiente ou secrets manager (NUNCA hardcoded)
- Logs: NUNCA logar senhas, tokens, números de cartão, CPF completo

### Patterns de correção
```typescript
// ❌ Ruim — MD5/SHA1 para senha
const hash = crypto.createHash('md5').update(password).digest('hex');

// ✅ Bom — bcrypt com salt rounds
import * as bcrypt from 'bcrypt';
const hash = await bcrypt.hash(password, 12);
```

### Checklist rápido
- [ ] Senhas hasheadas com bcrypt (salt rounds >= 10)
- [ ] TLS enforced (HSTS header)
- [ ] Nenhum secret no código-fonte
- [ ] PII encriptado em repouso no banco
- [ ] Logs sanitizados (CPF mascarado: `***.***.123-45`)

---

## A03:2021 — Injection

### O que verificar
- SQL Injection: queries parametrizadas (NUNCA concatenação)
- NoSQL Injection: sanitizar inputs em queries MongoDB
- Command Injection: nunca usar `exec()` com input do usuário
- LDAP Injection: escapar caracteres especiais
- Template Injection: sanitizar antes de renderizar templates

### Patterns de correção
```typescript
// ❌ SQL Injection vulnerável
const query = `SELECT * FROM users WHERE email = '${email}'`;

// ✅ Parametrizado
const query = `SELECT * FROM users WHERE email = $1`;
await pool.query(query, [email]);

// ✅ TypeORM QueryBuilder
.where('user.email = :email', { email })
```

### Checklist rápido
- [ ] Zero concatenação de string em queries
- [ ] TypeORM/Prisma sempre com parâmetros
- [ ] Input validation com class-validator/Joi
- [ ] Nenhum `eval()`, `exec()`, `child_process` com input do usuário

---

## A04:2021 — Insecure Design

### O que verificar
- Threat modeling feito antes de implementar features críticas
- Limites de negócio implementados (não permitir saque > saldo)
- Fluxos de erro não revelam informações internas
- Inputs com limites (max length, max value, max file size)

### Checklist rápido
- [ ] Business rules validadas no backend (não confiar no frontend)
- [ ] Limites de valor/volume em operações financeiras
- [ ] Error messages genéricas para o cliente (detalhes apenas no log)

---

## A05:2021 — Security Misconfiguration

### O que verificar
- Headers de segurança: `helmet()` no Express/NestJS
- Stack traces desabilitados em produção
- Default credentials removidas
- CORS restritivo
- Debug mode desligado

### Headers obrigatórios
```typescript
import helmet from 'helmet';
app.use(helmet({
  contentSecurityPolicy: true,
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: true,
  hsts: { maxAge: 31536000, includeSubDomains: true },
  noSniff: true,
  referrerPolicy: { policy: 'strict-origin-when-cross-origin' },
}));
```

---

## A06:2021 — Vulnerable and Outdated Components

### O que verificar
- `npm audit` sem vulnerabilidades HIGH/CRITICAL
- Dependências atualizadas (< 1 major version atrás)
- Lock files commitados (package-lock.json)
- Nenhuma dependência abandonada (last publish > 2 anos)

### Automação
```bash
# Verificar vulnerabilidades
npm audit --audit-level=high

# Verificar outdated
npm outdated

# Verificar deps abandonados
npx depcheck
```

---

## A07:2021 — Identification and Authentication Failures

### O que verificar
- Brute force protection (rate limiting + account lockout)
- Senhas fracas rejeitadas (min 8 chars, complexidade)
- Session fixation prevention (regenerar session ID após login)
- MFA disponível para operações críticas
- Tokens com expiração (JWT exp claim)

### JWT Checklist
- [ ] Access token: 15-30 min de expiração
- [ ] Refresh token: 7-30 dias, rotação a cada uso
- [ ] Token em httpOnly cookie ou Authorization header
- [ ] Refresh token armazenado encriptado no banco
- [ ] Blacklist de tokens revogados

---

## A08:2021 — Software and Data Integrity Failures

### O que verificar
- CI/CD pipeline seguro (secrets não expostos em logs)
- Dependências verificadas (checksums, lock files)
- Webhook signatures verificadas (Stripe, GitHub)
- Serialização segura (não deserializar input não confiável)

---

## A09:2021 — Security Logging and Monitoring Failures

### O que verificar
- Login failures logados
- Access denied logados
- Input validation failures logados
- Alterações em dados sensíveis logadas (audit trail)
- Alertas configurados para padrões suspeitos
- Logs centralizados e imutáveis

### O que NUNCA logar
- Senhas (nem hasheadas)
- Tokens JWT completos
- Números de cartão
- CPF/CNPJ completo
- Chaves de API

---

## A10:2021 — Server-Side Request Forgery (SSRF)

### O que verificar
- URLs fornecidas pelo usuário não acessam rede interna
- Whitelist de domínios/IPs permitidos para requests externos
- Metadados de cloud não acessíveis (169.254.169.254 bloqueado)

### Pattern de proteção
```typescript
// ✅ Whitelist de domínios
const ALLOWED_DOMAINS = ['api.stripe.com', 'api.sendgrid.com'];
const url = new URL(userInput);
if (!ALLOWED_DOMAINS.includes(url.hostname)) {
  throw new BadRequestException('Domain not allowed');
}
```
