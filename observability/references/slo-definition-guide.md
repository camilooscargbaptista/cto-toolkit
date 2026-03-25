# SLO Definition Guide

Guia prático para definir SLOs, SLIs e Error Budgets.

## Conceitos

```
SLI (Service Level Indicator)
  = métrica que mede a qualidade do serviço
  = "qual % das requests completou em < 200ms?"

SLO (Service Level Objective)
  = target para o SLI
  = "99.9% das requests devem completar em < 200ms"

SLA (Service Level Agreement)
  = contrato com consequências
  = "se não atingir 99.9%, credit de 10% na fatura"

Error Budget
  = quanto downtime/erro é permitido
  = 100% - SLO = 0.1% de budget para erros
```

## Cálculos de Error Budget

| SLO | Error Budget/mês | Downtime permitido/mês |
|-----|-----------------|----------------------|
| 99% | 1% | 7h 18min |
| 99.5% | 0.5% | 3h 39min |
| 99.9% | 0.1% | 43min 50s |
| 99.95% | 0.05% | 21min 55s |
| 99.99% | 0.01% | 4min 23s |

## SLIs Recomendados por Tipo de Serviço

### API/Backend
| SLI | Como medir | SLO sugerido |
|-----|-----------|-------------|
| Availability | `successful_requests / total_requests` | 99.9% |
| Latency | `requests_under_200ms / total_requests` | 99% |
| Error rate | `1 - (error_requests / total_requests)` | 99.9% |
| Throughput | `requests_per_second > baseline` | 95% do baseline |

### Processos Batch/Background
| SLI | Como medir | SLO sugerido |
|-----|-----------|-------------|
| Freshness | `time_since_last_successful_run` | < 1h |
| Completeness | `records_processed / records_expected` | 99.9% |
| Duration | `job_duration < threshold` | 95% under 30min |

### Banco de Dados
| SLI | Como medir | SLO sugerido |
|-----|-----------|-------------|
| Query latency | `queries_under_100ms / total_queries` | 99% |
| Availability | `successful_connections / total_attempts` | 99.99% |
| Replication lag | `lag_seconds < threshold` | 99% under 1s |

## Template de Documento SLO

```markdown
# SLO: [Nome do Serviço]

## Owners
- Team: [nome do time]
- Reviewer: [aprovador]
- Last review: [data]

## Service Description
[O que o serviço faz, quem usa, impacto se falhar]

## SLIs & SLOs

### Availability
- **SLI**: Proporção de requests HTTP com status 2xx ou 3xx
- **SLO**: 99.9% calculado em janela rolante de 30 dias
- **Medição**: `sum(rate(http_requests_total{code=~"2..|3.."}[5m])) / sum(rate(http_requests_total[5m]))`
- **Error budget**: 43 min/mês

### Latency
- **SLI**: Proporção de requests com latência < 200ms
- **SLO**: 99% (p99 < 200ms)
- **Medição**: `histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))`

## Error Budget Policy

| Budget consumed | Action |
|----------------|--------|
| 0-50% | Normal development, deploy at will |
| 50-75% | Increase testing, review changes carefully |
| 75-100% | Feature freeze, focus on reliability |
| > 100% | All hands on reliability, no new features |

## Alerting

### Budget Burn Rate
- **Fast burn**: > 2% of 30-day budget consumed in 1 hour → P1
- **Slow burn**: > 5% of 30-day budget consumed in 6 hours → P2
- **Remaining**: < 25% of monthly budget → P2 warning

## Review Schedule
- Monthly: review SLO compliance and error budget
- Quarterly: review if SLO targets are appropriate
- Annually: full SLO revision with stakeholders
```

## Implementação com Prometheus

```yaml
# Prometheus recording rules
groups:
  - name: slo-api
    interval: 30s
    rules:
      # Availability SLI
      - record: sli:api:availability
        expr: |
          sum(rate(http_requests_total{code=~"2..|3.."}[5m]))
          /
          sum(rate(http_requests_total[5m]))

      # Error budget remaining (30 days)
      - record: slo:api:error_budget_remaining
        expr: |
          1 - (
            (1 - sli:api:availability)
            /
            (1 - 0.999)  # SLO = 99.9%
          )

# Alerting rules
  - name: slo-api-alerts
    rules:
      # Fast burn: consumindo budget 14.4x mais rápido que o normal
      - alert: API_SLO_FastBurn
        expr: |
          (
            (1 - sli:api:availability:1h) / (1 - 0.999)
          ) > 14.4
        for: 2m
        labels:
          severity: P1
        annotations:
          summary: "API burning error budget 14.4x faster than sustainable"
          runbook: "https://wiki/runbooks/slo-fast-burn"
```

## Comunicação de SLOs

### Para Stakeholders Técnicos
"Nosso SLO de disponibilidade é 99.9%, o que significa que aceitamos até 43 minutos de downtime por mês. Atualmente estamos em 99.95%, com 50% do error budget restante."

### Para Stakeholders de Negócio
"Nosso serviço tem confiabilidade de 99.9%. Nos últimos 30 dias, tivemos apenas 2 minutos de indisponibilidade. Estamos dentro do alvo."

## Checklist

- [ ] SLIs definidos e mensuráveis automaticamente
- [ ] SLO targets baseados em impacto de negócio (não em feeling)
- [ ] Error budget calculado e visível em dashboard
- [ ] Error budget policy documentada (o que fazer quando consome X%)
- [ ] Burn rate alerts configurados (fast + slow)
- [ ] SLO review agendada (mensal)
- [ ] Stakeholders informados sobre SLO atual
