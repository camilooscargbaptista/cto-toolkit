# OpenTelemetry Setup Guide

Guia de implementação de observabilidade com OpenTelemetry (OTEL) para aplicações Node.js/NestJS.

## Arquitetura

```
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│  App (OTEL  │───→│  OTEL       │───→│  Backend        │
│  SDK)       │    │  Collector  │    │  (Jaeger/Tempo/ │
│             │    │             │    │   Grafana/DD)   │
│ Traces      │    │ Process     │    │                 │
│ Metrics     │    │ Filter      │    │ Visualize       │
│ Logs        │    │ Export      │    │ Alert           │
└─────────────┘    └─────────────┘    └─────────────────┘
```

## Setup Node.js/NestJS

### 1. Instalação
```bash
npm install @opentelemetry/api \
  @opentelemetry/sdk-node \
  @opentelemetry/auto-instrumentations-node \
  @opentelemetry/exporter-trace-otlp-http \
  @opentelemetry/exporter-metrics-otlp-http \
  @opentelemetry/resources \
  @opentelemetry/semantic-conventions
```

### 2. Bootstrap (tracing.ts — carregar ANTES do app)
```typescript
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { ATTR_SERVICE_NAME, ATTR_SERVICE_VERSION } from '@opentelemetry/semantic-conventions';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';

const sdk = new NodeSDK({
  resource: new Resource({
    [ATTR_SERVICE_NAME]: process.env.SERVICE_NAME || 'my-api',
    [ATTR_SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
    'deployment.environment': process.env.NODE_ENV || 'development',
  }),
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
  metricReader: new PeriodicExportingMetricReader({
    exporter: new OTLPMetricExporter({
      url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/metrics',
    }),
    exportIntervalMillis: 30000, // 30 segundos
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-pg': { enabled: true },
      '@opentelemetry/instrumentation-redis': { enabled: true },
    }),
  ],
});

sdk.start();

// Graceful shutdown
process.on('SIGTERM', () => sdk.shutdown());
```

### 3. Custom Spans (operações de negócio)
```typescript
import { trace, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('billing-service');

async function processRefueling(refuelingId: string): Promise<void> {
  return tracer.startActiveSpan('process-refueling', async (span) => {
    try {
      span.setAttribute('refueling.id', refuelingId);
      span.setAttribute('refueling.station_id', stationId);

      // Sub-span para validação
      await tracer.startActiveSpan('validate-refueling', async (validationSpan) => {
        await validateRefueling(refuelingId);
        validationSpan.end();
      });

      // Sub-span para cálculo de taxa
      await tracer.startActiveSpan('calculate-fee', async (feeSpan) => {
        const fee = await calculateZecaFee(refuelingId);
        feeSpan.setAttribute('fee.amount', fee);
        feeSpan.end();
      });

      span.setStatus({ code: SpanStatusCode.OK });
    } catch (error) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });
      span.recordException(error);
      throw error;
    } finally {
      span.end();
    }
  });
}
```

### 4. Custom Metrics
```typescript
import { metrics } from '@opentelemetry/api';

const meter = metrics.getMeter('billing-metrics');

// Counter — quantidade de eventos
const refuelingCounter = meter.createCounter('refuelings.processed', {
  description: 'Total refuelings processed',
  unit: '1',
});

// Histogram — distribuição de valores
const feeHistogram = meter.createHistogram('zeca_fee.amount', {
  description: 'Distribution of ZECA fee amounts',
  unit: 'BRL',
  advice: { explicitBucketBoundaries: [0.5, 1, 2, 5, 10, 25, 50, 100] },
});

// Uso
refuelingCounter.add(1, { station_id: stationId, category: 'AUTONOMO' });
feeHistogram.record(feeAmount, { station_id: stationId });
```

## Docker Compose — OTEL Collector + Jaeger

```yaml
services:
  otel-collector:
    image: otel/opentelemetry-collector-contrib:latest
    command: ["--config=/etc/otel-collector-config.yaml"]
    volumes:
      - ./otel-collector-config.yaml:/etc/otel-collector-config.yaml
    ports:
      - "4317:4317"   # gRPC
      - "4318:4318"   # HTTP
      - "8888:8888"   # Metrics

  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686" # UI
      - "14268:14268" # Collector

  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"

  grafana:
    image: grafana/grafana:latest
    ports:
      - "3001:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
```

## Collector Configuration
```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 5s
    send_batch_size: 1024
  
  # Filtrar spans de health check (reduzir ruído)
  filter:
    traces:
      span:
        - 'attributes["http.target"] == "/health"'
        - 'attributes["http.target"] == "/ready"'

exporters:
  jaeger:
    endpoint: jaeger:14250
    tls:
      insecure: true
  prometheus:
    endpoint: "0.0.0.0:8889"

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch, filter]
      exporters: [jaeger]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
```

## Checklist de Implementação

- [ ] OTEL SDK inicializado ANTES do app (tracing.ts como primeiro import)
- [ ] Service name e version configurados via env vars
- [ ] Auto-instrumentação para HTTP, DB, Redis
- [ ] Custom spans em operações de negócio críticas
- [ ] Custom metrics para KPIs (refuelings, fees, volumes)
- [ ] Collector configurado com batch + filter
- [ ] Health check endpoints filtrados do tracing
- [ ] Graceful shutdown do SDK
- [ ] Dashboard Grafana com métricas chave
- [ ] Alertas configurados para latência e error rate
