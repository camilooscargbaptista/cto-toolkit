# PostgreSQL Optimization Guide

## Query Performance

### EXPLAIN ANALYZE — Leitura
```sql
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
SELECT * FROM refuelings WHERE station_id = 'abc' AND refueling_datetime > '2026-01-01';

-- Ler o output:
-- Seq Scan → RUIM (lendo tabela inteira, precisa de índice)
-- Index Scan → BOM (usando índice)
-- Index Only Scan → ÓTIMO (dados direto do índice)
-- Bitmap Index Scan → OK (muitos rows, índice + heap)
-- Nested Loop → OK para poucos rows, RUIM para muitos
-- Hash Join → BOM para grandes datasets
-- Rows: estimated vs actual → Se muito diferente, ANALYZE necessário
```

### Índices — Quando e Como

```sql
-- B-Tree (padrão) — igualdade e range
CREATE INDEX idx_refuelings_station ON refuelings(station_id);
CREATE INDEX idx_refuelings_datetime ON refuelings(refueling_datetime);

-- Composto — queries com múltiplas condições (ordem importa!)
CREATE INDEX idx_refuelings_station_date 
ON refuelings(station_id, refueling_datetime);
-- A ordem segue a seletividade: coluna mais filtrada primeiro

-- Partial — apenas subset de dados
CREATE INDEX idx_active_cycles 
ON zeca_billing_cycles(station_id) 
WHERE status = 'ACTIVE';

-- Covering — inclui colunas do SELECT (evita heap lookup)
CREATE INDEX idx_refuelings_cover 
ON refuelings(station_id, refueling_datetime) 
INCLUDE (quantity_liters, zeca_fee_total);

-- GIN — full text search, JSONB, arrays
CREATE INDEX idx_users_search ON users USING GIN (to_tsvector('portuguese', name));

-- BRIN — dados naturalmente ordenados (timestamps)
CREATE INDEX idx_logs_created ON audit_logs USING BRIN (created_at);
```

### Quando NÃO criar índice
- Tabela com < 1000 rows (seq scan é mais rápido)
- Coluna com baixa cardinalidade (boolean, enum com 3 valores)
- Coluna raramente usada em WHERE/JOIN
- Tabela com muitos INSERTs e poucos SELECTs (overhead de manutenção)

## Tipos de Dados — Escolhas Corretas

| Dado | Tipo correto | Tipo errado | Por que |
|------|-------------|-------------|---------|
| Dinheiro | `DECIMAL(19,4)` | `FLOAT/DOUBLE` | Float tem erros de arredondamento |
| UUID | `UUID` | `VARCHAR(36)` | 16 bytes vs 36 bytes, comparação nativa |
| Timestamp | `TIMESTAMPTZ` | `TIMESTAMP` | Sem TZ, perde info de timezone |
| Boolean | `BOOLEAN` | `INTEGER` | Semântica clara |
| Enum | `VARCHAR` com CHECK | `ENUM type` | Enums são difíceis de alterar |
| CPF | `VARCHAR(11)` | `BIGINT` | CPF com leading zeros |
| JSON config | `JSONB` | `JSON` | JSONB é indexável e mais rápido |

## Connection Pooling

```typescript
// TypeORM — configuração otimizada
{
  type: 'postgres',
  extra: {
    max: 20,                    // Máximo de conexões no pool
    min: 5,                     // Mínimo mantido aberto
    idleTimeoutMillis: 30000,   // Fechar idle após 30s
    connectionTimeoutMillis: 5000, // Timeout para obter conexão
    statement_timeout: 30000,    // Timeout de query (30s)
  },
}

// Fórmula: max_connections = ((num_cores * 2) + disk_spindles)
// Para SSD: max_connections ≈ num_cores * 4
// Para pool: pool_size = max_connections / num_app_instances
```

## Vacuum e Manutenção

```sql
-- Ver tabelas que precisam de VACUUM
SELECT schemaname, relname, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables 
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Ver índices não utilizados
SELECT indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Ver queries lentas (pg_stat_statements)
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;
```

## Checklist de Performance

- [ ] EXPLAIN ANALYZE em todas as queries que fazem JOIN ou WHERE em tabelas > 10k rows
- [ ] Índices em todas as colunas usadas em WHERE, JOIN, ORDER BY frequentes
- [ ] `TIMESTAMPTZ` (não TIMESTAMP) para todas as datas
- [ ] `DECIMAL(19,4)` para todos os valores monetários
- [ ] Connection pool configurado (não usar conexão direta)
- [ ] Query timeout configurado (30s padrão)
- [ ] pg_stat_statements habilitado para monitoring
- [ ] Índices não usados removidos (idx_scan = 0)
- [ ] VACUUM automático configurado adequadamente
