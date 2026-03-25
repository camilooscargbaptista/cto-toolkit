# Database Migration Patterns

## Naming Convention
```
{NNN}_{action}_{target}.sql

Exemplos:
001_create_users.sql
002_create_companies.sql
003_add_cnpj_to_companies.sql
004_create_index_users_email.sql
099_seed_initial_roles.sql
```

## Safe Migration Patterns

### 1. Add Column (SAFE)
```sql
-- ✅ Adicionar coluna nullable é non-blocking
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- ✅ Adicionar com default (PG 11+ é instantâneo)
ALTER TABLE users ADD COLUMN is_active BOOLEAN DEFAULT true;

-- ❌ NUNCA: adicionar NOT NULL sem default em tabela com dados
ALTER TABLE users ADD COLUMN phone VARCHAR(20) NOT NULL; -- LOCK!
```

### 2. Rename Column (2-STEP)
```sql
-- STEP 1: Adicionar nova coluna + copiar dados
ALTER TABLE users ADD COLUMN full_name VARCHAR(200);
UPDATE users SET full_name = name;

-- Deploy app que lê de ambas colunas (fallback)

-- STEP 2: Remover coluna antiga (próxima migration)
ALTER TABLE users DROP COLUMN name;
```

### 3. Change Column Type (3-STEP)
```sql
-- STEP 1: Criar nova coluna com tipo correto
ALTER TABLE transactions ADD COLUMN amount_new DECIMAL(19,4);

-- STEP 2: Backfill (em batches para não bloquear)
UPDATE transactions SET amount_new = amount::DECIMAL(19,4)
WHERE id IN (SELECT id FROM transactions WHERE amount_new IS NULL LIMIT 10000);

-- STEP 3: Swap e drop (próxima migration)
ALTER TABLE transactions DROP COLUMN amount;
ALTER TABLE transactions RENAME COLUMN amount_new TO amount;
```

### 4. Create Index (CONCURRENTLY)
```sql
-- ✅ Non-blocking index creation
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- ❌ NUNCA: index sem CONCURRENTLY em tabela grande (bloqueia writes)
CREATE INDEX idx_users_email ON users(email); -- LOCK!
```

### 5. Drop Column (SAFE with grace period)
```sql
-- STEP 1: Parar de escrever na coluna no app
-- STEP 2: Esperar 1 release cycle
-- STEP 3: Drop
ALTER TABLE users DROP COLUMN legacy_field;
```

## Dangerous Patterns (EVITAR)

| Pattern | Risco | Alternativa |
|---------|-------|-------------|
| `ALTER TABLE ... ADD COLUMN ... NOT NULL` | Lock exclusivo | Adicionar nullable + backfill + add constraint |
| `CREATE INDEX` (sem CONCURRENTLY) | Lock exclusivo | `CREATE INDEX CONCURRENTLY` |
| `ALTER TABLE ... ALTER COLUMN TYPE` | Rewrite table | Nova coluna + backfill + swap |
| `LOCK TABLE` | Bloqueia tudo | Usar advisory locks |
| `UPDATE ... SET` (tabela inteira) | Longo, sem progresso | Batch updates com LIMIT |

## Batch Updates (tabelas grandes)

```sql
-- ✅ Update em batches de 10k
DO $$
DECLARE
  batch_size INT := 10000;
  affected INT;
BEGIN
  LOOP
    UPDATE users 
    SET status = 'ACTIVE' 
    WHERE id IN (
      SELECT id FROM users 
      WHERE status IS NULL 
      LIMIT batch_size
      FOR UPDATE SKIP LOCKED
    );
    
    GET DIAGNOSTICS affected = ROW_COUNT;
    EXIT WHEN affected = 0;
    
    RAISE NOTICE 'Updated % rows', affected;
    PERFORM pg_sleep(0.1); -- Dar espaço para outras queries
  END LOOP;
END $$;
```

## Rollback Strategy

```sql
-- Toda migration deve ter um DOWN
-- UP
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- DOWN
ALTER TABLE users DROP COLUMN IF EXISTS phone;
```

## Checklist de Migration Review

- [ ] Testada em banco com volume similar a produção
- [ ] Não usa operações bloqueantes em tabelas grandes
- [ ] Índices criados com CONCURRENTLY
- [ ] Colunas NOT NULL adicionadas em 2 steps (nullable + backfill + constraint)
- [ ] Backfills feitos em batches
- [ ] Rollback script incluído
- [ ] Naming convention respeitada
- [ ] Sem hardcoded IDs ou dados que variam por ambiente
