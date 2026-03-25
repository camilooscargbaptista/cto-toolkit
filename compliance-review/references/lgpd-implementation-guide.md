# LGPD Implementation Guide

Guia técnico para implementação da Lei Geral de Proteção de Dados (Lei 13.709/2018).

## Bases Legais (Art. 7)

| Base Legal | Quando usar | Exemplo |
|-----------|------------|---------|
| **Consentimento** | Coleta opcional, marketing | Newsletter, cookies de tracking |
| **Execução de contrato** | Dados necessários para o serviço | CPF para emissão de NF-e |
| **Obrigação legal** | Exigido por lei | Dados fiscais, trabalhistas |
| **Legítimo interesse** | Benefício mútuo, impacto mínimo | Prevenção a fraude |
| **Proteção ao crédito** | Score/análise de crédito | Consulta SPC/Serasa |

## Mapeamento de Dados (ROPA)

```markdown
## Registro de Atividades de Tratamento

| Campo | Valor |
|-------|-------|
| Atividade | [ex: Cadastro de usuários] |
| Dados coletados | [nome, CPF, email, telefone] |
| Base legal | [Execução de contrato] |
| Finalidade | [Criação de conta para uso do serviço] |
| Compartilhamento | [Gateway de pagamento, emissor de NF-e] |
| Retenção | [Enquanto conta ativa + 5 anos após inativação] |
| Categoria do titular | [Cliente, motorista, empresa] |
| Local de armazenamento | [AWS us-east-1, PostgreSQL] |
```

## Direitos do Titular — Implementação Técnica

### 1. Direito de Acesso (Art. 18, II)
```typescript
// Endpoint: GET /api/v1/me/data-export
async exportUserData(userId: string): Promise<UserDataExport> {
  const user = await this.userRepo.findOne(userId);
  const refuelings = await this.refuelingRepo.find({ userId });
  const payments = await this.paymentRepo.find({ userId });
  
  return {
    personal: {
      name: user.name,
      cpf: user.cpf,
      email: user.email,
      phone: user.phone,
      created_at: user.createdAt,
    },
    refuelings: refuelings.map(r => ({
      date: r.datetime,
      station: r.stationName,
      amount: r.totalAmount,
      liters: r.quantityLiters,
    })),
    payments: payments.map(p => ({
      date: p.date,
      amount: p.amount,
      method: p.method,
    })),
    exportDate: new Date(),
    format: 'JSON', // Formato legível por máquina
  };
}
```

### 2. Direito de Eliminação (Art. 18, VI)
```typescript
// Endpoint: DELETE /api/v1/me/data
async deleteUserData(userId: string): Promise<void> {
  // 1. Anonimizar dados pessoais (manter transações por obrigação fiscal)
  await this.userRepo.update(userId, {
    name: 'USUARIO_ANONIMIZADO',
    cpf: null,
    email: `deleted_${userId}@anonimizado.local`,
    phone: null,
    deleted_at: new Date(),
  });

  // 2. Manter dados transacionais (obrigação legal — 5 anos)
  // NÃO deletar: refuelings, payments, invoices
  
  // 3. Remover de serviços externos
  await this.emailService.removeContact(userId);
  await this.analyticsService.deleteUser(userId);
  
  // 4. Log de auditoria
  await this.auditLog.create({
    action: 'DATA_DELETION',
    userId,
    timestamp: new Date(),
    retainedData: ['refuelings', 'payments'], // Por obrigação legal
  });
}
```

### 3. Direito de Portabilidade (Art. 18, V)
```typescript
// Formato: CSV ou JSON
// Incluir: todos os dados que o titular forneceu diretamente
async exportPortableData(userId: string): Promise<Buffer> {
  const data = await this.exportUserData(userId);
  
  // CSV para máxima portabilidade
  const csv = convertToCsv(data);
  return Buffer.from(csv, 'utf-8');
}
```

## Consentimento — Implementação

```typescript
// Schema de consentimento
@Entity('user_consents')
class UserConsent {
  @PrimaryColumn('uuid')
  id: string;

  @Column('uuid')
  user_id: string;

  @Column()
  purpose: string;       // 'marketing_email', 'analytics', 'third_party_share'

  @Column()
  granted: boolean;

  @Column({ type: 'timestamp' })
  granted_at: Date;

  @Column({ type: 'timestamp', nullable: true })
  revoked_at: Date;

  @Column()
  version: string;       // Versão da política de privacidade

  @Column()
  ip_address: string;    // Prova do consentimento

  @Column()
  user_agent: string;    // Prova do consentimento
}
```

### Regras de Consentimento
- [ ] Opt-in explícito (checkbox desmarcada por padrão)
- [ ] Granular (um consentimento por finalidade, não "aceito tudo")
- [ ] Revogável a qualquer momento
- [ ] Registro de prova (IP, timestamp, versão da política)
- [ ] Recoleta quando política de privacidade muda

## Notificação de Incidente (Art. 48)

```markdown
## Template: Notificação à ANPD

**Para**: ANPD (Autoridade Nacional de Proteção de Dados)
**De**: [Nome do controlador]
**Data**: [data do comunicado]

### 1. Natureza dos dados afetados
[Tipos de dados: nome, CPF, email, dados financeiros]

### 2. Titulares afetados
[Número de titulares, categorias: clientes, funcionários]

### 3. Medidas técnicas de segurança
[Encriptação, controle de acesso, monitoramento que existiam]

### 4. Riscos relacionados
[Acesso não autorizado a dados pessoais, possível uso para fraude]

### 5. Medidas adotadas para reverter/mitigar
[Revogação de credenciais, notificação aos titulares, etc.]

### 6. Prazo para comunicação aos titulares
[Imediato / em até X dias]
```

### Prazo
- LGPD: "prazo razoável" (ANPD recomenda 2 dias úteis)
- GDPR: 72 horas (referência)

## Checklist Técnico LGPD

### Banco de Dados
- [ ] PII encriptado em repouso (AES-256)
- [ ] CPF/CNPJ mascarado em logs (`***.***. 123-45`)
- [ ] Soft delete com anonimização (não hard delete com dados fiscais)
- [ ] Campos de auditoria (created_at, updated_at, deleted_at)
- [ ] Retenção definida por categoria de dado

### API
- [ ] Endpoint de exportação de dados (JSON/CSV)
- [ ] Endpoint de exclusão/anonimização
- [ ] Endpoint de gerenciamento de consentimento
- [ ] Privacy policy version tracking
- [ ] Consent collection com prova (IP, timestamp)

### Frontend
- [ ] Cookie consent banner (opt-in, não opt-out)
- [ ] Link para política de privacidade em todas as telas
- [ ] Opção de gerenciar consentimentos no perfil
- [ ] Confirmação antes de exclusão de conta

### Operacional
- [ ] DPO (Encarregado) designado e publicado
- [ ] ROPA (Registro de Atividades) atualizado
- [ ] Plano de resposta a incidentes com template ANPD
- [ ] Treinamento de equipe em proteção de dados
- [ ] Avaliação de impacto (DPIA) para tratamentos de alto risco
