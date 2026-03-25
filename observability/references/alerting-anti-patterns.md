# Alerting Anti-Patterns & Best Practices

Guia para configurar alertas que realmente funcionam em produção — sem alert fatigue.

## Os 7 Anti-Patterns Fatais

### 1. Alertar em Sintomas, Não em Causas
```
❌ Alert: "CPU > 80% por 5 min"
   → E daí? CPU alta pode ser normal sob carga. O que importa é: impacta o usuário?

✅ Alert: "Error rate > 1% por 5 min" + "p99 latency > 2s por 5 min"
   → Mede impacto real no usuário
```

### 2. Thresholds Estáticos em Métricas Variáveis
```
❌ Alert: "Request count < 100/min"
   → Às 3h da manhã isso é normal. Ao meio-dia é catástrofe.

✅ Alert: "Request count < 50% da média da mesma hora nos últimos 7 dias"
   → Anomaly detection baseado em padrões históricos
```

### 3. Sem Runbook no Alerta
```
❌ Alert: "Database connection pool exhausted"
   → E agora? Quem recebe não sabe o que fazer.

✅ Alert: "Database connection pool exhausted"
   → Runbook: https://wiki/runbooks/db-pool-exhausted
   → Steps: 1) Verificar queries lentas 2) Restart pool 3) Escalar
```

### 4. Janelas Muito Curtas
```
❌ Alert: "Error rate > 0.5% por 1 minuto"
   → Falsos positivos constantes por picos transitórios

✅ Alert: "Error rate > 1% por 5 minutos"
   → Elimina ruído, pega problemas reais
```

### 5. Alertar em Cada Instância
```
❌ Alert: "Pod X memory > 80%"
   → Com 50 pods, você recebe 50 alertas para o mesmo problema

✅ Alert: "Service Y: > 20% dos pods com memory > 80%"
   → Alerta agrupado, um alerta = uma ação
```

### 6. Sem Severity Levels
```
❌ Tudo é "CRITICAL" → equipe ignora tudo

✅ Três níveis claros:
   P1 (CRITICAL): Impacto no usuário, requer ação em 5 min
   P2 (WARNING): Degradação, requer ação em 1 hora
   P3 (INFO): Tendência preocupante, revisar no próximo business day
```

### 7. Alertas Sem Owner
```
❌ Alerta vai para #general no Slack → ninguém age

✅ Cada alerta tem:
   → On-call team definido
   → Escalation path claro
   → SLA de resposta por severity
```

## Framework de Alerta: USE + RED + Four Golden Signals

### USE Method (Infraestrutura)
| Signal | O que mede | Alerta quando |
|--------|-----------|---------------|
| **U**tilization | % de recurso em uso | > 85% sustained (5min) |
| **S**aturation | Fila de trabalho | Queue depth > threshold |
| **E**rrors | Erros de recurso | Qualquer erro de hardware/OS |

### RED Method (Serviços)
| Signal | O que mede | Alerta quando |
|--------|-----------|---------------|
| **R**ate | Requests/sec | < 50% da baseline |
| **E**rrors | Error rate % | > 1% sustained (5min) |
| **D**uration | Latência p99 | > SLO target |

### Four Golden Signals (Google SRE)
| Signal | Alerta |
|--------|--------|
| Latency | p99 > SLO por 5min |
| Traffic | Queda > 50% da baseline |
| Errors | Rate > 1% por 5min |
| Saturation | Resource > 85% por 5min |

## Template de Alerta

```yaml
alert:
  name: "API Error Rate High"
  severity: P1  # P1=5min, P2=1h, P3=next business day
  
  condition:
    metric: http_errors_total / http_requests_total
    threshold: "> 0.01"  # 1%
    duration: "5m"
    
  labels:
    team: backend
    service: billing-api
    runbook: "https://wiki/runbooks/api-error-rate"
    
  annotations:
    summary: "API error rate is {{ $value | humanizePercentage }}"
    description: |
      Error rate for {{ $labels.service }} is above 1% for 5 minutes.
      Current value: {{ $value | humanizePercentage }}
      Dashboard: https://grafana/d/api-overview
    
  notification:
    channels:
      - pagerduty: backend-oncall
      - slack: "#alerts-backend"
    
  escalation:
    - after: 15m
      notify: backend-lead
    - after: 30m
      notify: engineering-manager
```

## Checklist de Alertas Saudáveis

- [ ] Todo alerta P1 tem runbook linkado
- [ ] Todo alerta tem um owner (team + oncall)
- [ ] Janelas de 5min+ para evitar falsos positivos
- [ ] Thresholds baseados em SLOs, não em números arbitrários
- [ ] Alertas agrupados por serviço (não por instância)
- [ ] Severity definida por impacto no usuário
- [ ] Escalation path documentado
- [ ] Review mensal de alertas (quais nunca disparam, quais disparam demais)
- [ ] Alertas que nunca acionam são deletados
- [ ] Alertas que sempre acionam são retreinados
