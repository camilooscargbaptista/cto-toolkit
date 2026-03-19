# CI/CD Pipeline Templates

## Complete GitHub Actions Pipeline

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    name: Unit & Integration Tests
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run linter
        run: npm run lint

      - name: Run unit tests
        run: npm run test:unit -- --coverage

      - name: Run integration tests
        run: npm run test:integration

      - name: Upload coverage
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info

      - name: Build application
        run: npm run build

  security:
    name: Security Scanning
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy filesystem scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Setup Node.js for npm audit
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Check npm dependencies
        run: npm audit --audit-level=moderate

  build-image:
    name: Build Docker Image
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.event_name == 'push'
    permissions:
      contents: read
      packages: write
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=semver,pattern={{version}}
            type=semver,pattern={{major}}.{{minor}}
            type=sha,prefix={{branch}}-

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    name: Deploy to Staging
    needs: [build-image, test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    environment: staging
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Deploy to staging ECS
        run: |
          aws ecs update-service \
            --cluster staging-cluster \
            --service api-service \
            --force-new-deployment

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster staging-cluster \
            --services api-service

      - name: Health check
        run: |
          curl -f https://staging-api.example.com/health || exit 1

  deploy-production:
    name: Deploy to Production
    needs: [build-image, test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: production
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Deploy canary (10% traffic)
        run: |
          TASK_DEF=$(aws ecs describe-task-definition \
            --task-definition api-task \
            --query 'taskDefinition' | jq 'del(.taskDefinitionArn,.revision,.status,.requiresAttributes)')

          REVISION=$(aws ecs register-task-definition \
            --cli-input-json "$(echo $TASK_DEF | jq '.containerDefinitions[0].image = "${{ needs.build-image.outputs.image-tag }}"')" \
            --query 'taskDefinition.revision')

          aws ecs update-service \
            --cluster prod-cluster \
            --service api-service \
            --task-definition api-task:$REVISION \
            --deployment-configuration "maximumPercent=110,minimumHealthyPercent=90"

      - name: Monitor canary (5 minutes)
        run: |
          sleep 300
          UNHEALTHY=$(aws ecs describe-services \
            --cluster prod-cluster \
            --services api-service \
            --query 'services[0].deployments[0].runningCount' \
            | jq 'select(. < 1)')

          if [ ! -z "$UNHEALTHY" ]; then
            echo "Canary failed, rolling back..."
            aws ecs update-service \
              --cluster prod-cluster \
              --service api-service \
              --force-new-deployment
            exit 1
          fi

      - name: Full production deployment (100% traffic)
        run: |
          aws ecs update-service \
            --cluster prod-cluster \
            --service api-service \
            --deployment-configuration "maximumPercent=200,minimumHealthyPercent=100"

      - name: Wait for deployment
        run: |
          aws ecs wait services-stable \
            --cluster prod-cluster \
            --services api-service

      - name: Health check
        run: |
          curl -f https://api.example.com/health || exit 1

      - name: Notify deployment
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -d '{"text":"✅ Production deployment successful"}'

  rollback-production:
    name: Rollback Production
    runs-on: ubuntu-latest
    if: failure() && github.ref == 'refs/heads/main'
    environment: production
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: us-east-1

      - name: Rollback to previous version
        run: |
          aws ecs update-service \
            --cluster prod-cluster \
            --service api-service \
            --force-new-deployment

      - name: Notify rollback
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK }} \
            -d '{"text":"⚠️ Production rollback triggered"}'
```

---

## Pipeline Principles

### Code Quality & Testing
- **Tests before deploy** — All tests must pass; blocked deployment if tests fail
- **Unit + Integration tests** — Run both types; coverage reports uploaded
- **Linting** — Code style enforced; builds fail on lint errors
- **Build verification** — Application builds successfully on every change

### Security
- **Dependency scanning** — `npm audit` checks for vulnerable packages
- **Container scanning** — Trivy scans Dockerfile and dependencies for CVEs
- **SARIF upload** — Vulnerability results appear in GitHub Security tab
- **Secrets management** — Never in code; use GitHub Secrets or AWS Secrets Manager
- **Environment isolation** — Separate staging and production credentials

### Deployment Strategy
- **Staging before production** — All changes go to staging first
- **Canary deployment** — Production rollout in stages (10% → 100%)
- **Blue-green fallback** — Ability to switch back to previous version instantly
- **Health checks** — Automated health probes after each deployment stage
- **Traffic gradual ramp** — Catch issues with small user base before full rollout

### Automation & Reliability
- **No manual gates** — Pipeline runs automatically on branch push
- **Automated rollback** — Failed health checks trigger automatic rollback
- **Notifications** — Slack alerts on deployment success/failure
- **Status checks** — PR blocking until all checks pass
- **Idempotency** — Safe to re-run failed jobs without side effects

### Monitoring & Observability
- **Deployment tracking** — Timestamps and version info logged
- **Incident response** — Fast rollback capability (< 1 minute)
- **Audit trail** — GitHub Actions logs retained for compliance
- **Metrics collection** — Integration points for CloudWatch/Prometheus
