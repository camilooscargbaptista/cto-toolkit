# Helm Best Practices

## Chart Structure
```
my-chart/
├── Chart.yaml          # Metadata (name, version, dependencies)
├── values.yaml         # Default values
├── values-dev.yaml     # Dev overrides
├── values-staging.yaml # Staging overrides
├── values-prod.yaml    # Production overrides
├── templates/
│   ├── _helpers.tpl    # Template helpers
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   └── tests/
│       └── test-connection.yaml
└── README.md
```

## Values — Best Practices

```yaml
# values.yaml — sempre documentar cada valor
# -- Number of pod replicas
replicaCount: 1

image:
  # -- Container image repository
  repository: my-app
  # -- Container image tag
  tag: "1.0.0"
  # -- Image pull policy
  pullPolicy: IfNotPresent

# -- Resource requests and limits
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "500m"

# -- Horizontal Pod Autoscaler config
autoscaling:
  enabled: false
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70

# -- Ingress configuration
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: api.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: api-tls
      hosts:
        - api.example.com

# -- Environment variables
env:
  NODE_ENV: production
  LOG_LEVEL: info

# -- Sensitive env vars (from secrets)
secretEnv:
  DB_PASSWORD: ""
  JWT_SECRET: ""
```

## Templates — Best Practices

### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "my-chart.fullname" . }}
  labels:
    {{- include "my-chart.labels" . | nindent 4 }}
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0        # Zero-downtime deploy
  selector:
    matchLabels:
      {{- include "my-chart.selectorLabels" . | nindent 6 }}
  template:
    metadata:
      annotations:
        # Force rollout on configmap change
        checksum/config: {{ include (print $.Template.BasePath "/configmap.yaml") . | sha256sum }}
      labels:
        {{- include "my-chart.selectorLabels" . | nindent 8 }}
    spec:
      serviceAccountName: {{ include "my-chart.serviceAccountName" . }}
      terminationGracePeriodSeconds: 30
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ include "my-chart.fullname" . }}
            - secretRef:
                name: {{ include "my-chart.fullname" . }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          livenessProbe:
            httpGet:
              path: /health
              port: {{ .Values.service.port }}
            initialDelaySeconds: 15
            periodSeconds: 20
          readinessProbe:
            httpGet:
              path: /ready
              port: {{ .Values.service.port }}
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Helpers
```yaml
# templates/_helpers.tpl

{{- define "my-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "my-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "my-chart.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "my-chart.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 }}
app.kubernetes.io/name: {{ include "my-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}
```

## Testing

```bash
# Lint chart
helm lint ./my-chart

# Template render (dry-run)
helm template my-release ./my-chart -f values-prod.yaml

# Install with dry-run
helm install my-release ./my-chart --dry-run --debug

# Run tests
helm test my-release
```

## Checklist

- [ ] Chart versioning follows semver
- [ ] values.yaml has comments/documentation for every value
- [ ] Environment-specific overrides (values-dev.yaml, values-prod.yaml)
- [ ] Resource limits defined for all containers
- [ ] Health probes configured (liveness + readiness)
- [ ] Rolling update strategy with zero downtime
- [ ] ConfigMap/Secret checksum annotation for auto-rollout
- [ ] Labels follow Kubernetes recommended labels
- [ ] Helm tests verify basic connectivity
- [ ] `helm lint` passes without warnings
