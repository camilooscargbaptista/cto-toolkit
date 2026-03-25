# Kubernetes Security Hardening

## Pod Security

### Pod Security Standards
```yaml
# ✅ Restricted (mais seguro)
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true           # Nunca rodar como root
    runAsUser: 1000              # UID específico
    runAsGroup: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault       # Perfil seccomp padrão
  containers:
    - name: app
      image: app:1.0.0@sha256:abc...  # Image digest (imutável)
      securityContext:
        allowPrivilegeEscalation: false  # Sem escalação
        readOnlyRootFilesystem: true     # Filesystem read-only
        capabilities:
          drop: ["ALL"]                   # Remover todas as capabilities
      resources:
        requests:
          memory: "128Mi"
          cpu: "100m"
        limits:
          memory: "256Mi"
          cpu: "500m"                     # Sempre definir limites
      livenessProbe:
        httpGet:
          path: /health
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 15
      readinessProbe:
        httpGet:
          path: /ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
```

### Network Policies
```yaml
# Bloquear todo tráfego por padrão
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

---
# Permitir apenas tráfego necessário
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
spec:
  podSelector:
    matchLabels:
      app: postgres
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: api
      ports:
        - protocol: TCP
          port: 5432
```

### RBAC
```yaml
# Service Account por deployment (não usar default)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: api-service-account
  namespace: production
  annotations:
    # Não montar token automaticamente
automountServiceAccountToken: false

---
# Role com least privilege
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-role
  namespace: production
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]              # Somente leitura
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
    resourceNames: ["api-secrets"]  # Apenas secrets específicos
```

### Secrets Management
```yaml
# ❌ NUNCA hardcoded no manifesto
env:
  - name: DB_PASSWORD
    value: "minha-senha"  # NUNCA!

# ✅ Referência a Secret
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password

# ✅ Sealed Secrets (encriptados no Git)
# brew install kubeseal
kubeseal --format yaml < secret.yaml > sealed-secret.yaml

# ✅ External Secrets Operator (AWS Secrets Manager/Vault)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: db-credentials
  data:
    - secretKey: password
      remoteRef:
        key: prod/database/password
```

## Image Security

- [ ] Use specific image tags (not `latest`)
- [ ] Use image digests for immutability (`image@sha256:...`)
- [ ] Scan images for vulnerabilities (Trivy, Snyk)
- [ ] Use distroless or Alpine base images
- [ ] Multi-stage builds to minimize attack surface
- [ ] Private registry with image signing (Cosign/Notary)

## Checklist

- [ ] Pods rodando como non-root
- [ ] readOnlyRootFilesystem habilitado
- [ ] capabilities ALL dropped
- [ ] Resource limits definidos (CPU + memory)
- [ ] Network Policies bloqueando tráfego padrão
- [ ] RBAC com least privilege
- [ ] Service Account dedicado por deployment
- [ ] Secrets encriptados (Sealed Secrets ou External Secrets)
- [ ] Image scanning no CI/CD
- [ ] Liveness + Readiness probes configurados
- [ ] PodDisruptionBudget definidos
- [ ] Namespace isolation entre ambientes
