# N+1 Query Problem — Solutions

## O que é o N+1

```
// Buscar 100 postos e seus abastecimentos
const stations = await stationRepo.find(); // 1 query

for (const station of stations) {
  station.refuelings = await refuelingRepo.find({ station_id: station.id }); 
  // 100 queries! (1 por posto)
}
// Total: 1 + 100 = 101 queries ← N+1!
```

## Solução 1: Eager Loading (JOIN)

```typescript
// TypeORM — relations
const stations = await stationRepo.find({
  relations: ['refuelings'],
});
// 1 query com LEFT JOIN

// QueryBuilder
const stations = await stationRepo
  .createQueryBuilder('s')
  .leftJoinAndSelect('s.refuelings', 'r')
  .where('s.active = true')
  .getMany();
// 1 query
```

**Quando usar**: Quando sempre precisa dos dados relacionados.
**Cuidado**: JOIN grande pode ser lento. Limitar com WHERE.

## Solução 2: Batch Loading (IN clause)

```typescript
// Buscar postos
const stations = await stationRepo.find();
const stationIds = stations.map(s => s.id);

// Uma query para todos os refuelings
const refuelings = await refuelingRepo
  .createQueryBuilder('r')
  .where('r.station_id IN (:...ids)', { ids: stationIds })
  .getMany();

// Agrupar em memória
const refuelingsByStation = groupBy(refuelings, 'station_id');
stations.forEach(s => {
  s.refuelings = refuelingsByStation[s.id] || [];
});
// Total: 2 queries (independente de N)
```

**Quando usar**: Quando nem sempre precisa dos dados relacionados.

## Solução 3: DataLoader (GraphQL pattern)

```typescript
import DataLoader from 'dataloader';

// Criar loader (batcha automaticamente)
const refuelingLoader = new DataLoader(async (stationIds: string[]) => {
  const refuelings = await refuelingRepo
    .createQueryBuilder('r')
    .where('r.station_id IN (:...ids)', { ids: stationIds })
    .getMany();

  const grouped = groupBy(refuelings, 'station_id');
  return stationIds.map(id => grouped[id] || []);
});

// Usar (cada chamada é batchada automaticamente)
const stationRefuelings = await refuelingLoader.load(stationId);
```

## Solução 4: Subquery (SQL puro)

```sql
-- Em vez de N queries, usar subquery correlacionada
SELECT s.*,
  (SELECT COUNT(*) FROM refuelings r WHERE r.station_id = s.id) as refueling_count,
  (SELECT SUM(r.zeca_fee_total) FROM refuelings r WHERE r.station_id = s.id) as total_fees
FROM companies s
WHERE s.type = 'STATION';
-- 1 query (o DB otimiza as subqueries)
```

## Solução 5: Materialized View (leitura pesada)

```sql
-- Para dashboards com muitos JOINs e aggregations
CREATE MATERIALIZED VIEW station_billing_summary AS
SELECT 
  s.id as station_id,
  s.name as station_name,
  COUNT(r.id) as refueling_count,
  SUM(r.quantity_liters) as total_volume,
  SUM(r.zeca_fee_total) as total_fees
FROM companies s
LEFT JOIN refuelings r ON r.station_id = s.id
GROUP BY s.id, s.name;

-- Atualizar periodicamente
REFRESH MATERIALIZED VIEW CONCURRENTLY station_billing_summary;
```

## Detecção de N+1

### Log de queries (desenvolvimento)
```typescript
// TypeORM — habilitar logging
{
  logging: ['query'],
  logger: 'advanced-console',
}

// Se ver queries repetitivas com IDs diferentes → N+1
// query: SELECT * FROM refuelings WHERE station_id = $1 -- ["abc"]
// query: SELECT * FROM refuelings WHERE station_id = $1 -- ["def"]
// query: SELECT * FROM refuelings WHERE station_id = $1 -- ["ghi"]
```

### pg_stat_statements (produção)
```sql
SELECT query, calls, mean_exec_time
FROM pg_stat_statements
WHERE query LIKE '%refuelings%'
ORDER BY calls DESC;
-- Se uma query tem milhares de calls → provavelmente N+1
```

## Checklist

- [ ] Toda listagem que mostra dados de tabelas relacionadas usa JOIN ou batch loading
- [ ] DataLoader usado em resolvers GraphQL
- [ ] Query logging habilitado em desenvolvimento
- [ ] pg_stat_statements monitorado em produção
- [ ] Nenhum `findOne` dentro de loop
- [ ] Dashboards usam queries agregadas ou materialized views
