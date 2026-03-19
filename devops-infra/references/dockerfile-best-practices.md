# Dockerfile Best Practices

## Multi-Stage Build Example (Node.js)

```dockerfile
# Stage 1: Builder
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

# Stage 2: Runtime
FROM node:20-alpine AS runtime

# Create non-root user
RUN addgroup -g 1001 appgroup && \
    adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /app

# Copy only necessary artifacts from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

# Security: run as non-root user
USER appuser

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget -qO- http://localhost:3000/health || exit 1

# Signal handling: use exec form (not shell form)
CMD ["node", "dist/main.js"]
```

## Dockerfile Checklist

- [ ] **Multi-stage build** — Separate build stage from runtime stage to reduce final image size
- [ ] **Base image tags** — Use specific versions (e.g., `node:20-alpine`), never `latest`
- [ ] **Alpine or distroless** — Minimize base image size and attack surface
- [ ] **Non-root user** — Create a dedicated user with limited privileges
- [ ] **.dockerignore** — Exclude node_modules, .git, .env, .DS_Store, etc.
- [ ] **Layer ordering** — Dependencies before source code (cache optimization)
- [ ] **HEALTHCHECK** — Define health probe with appropriate interval and timeout
- [ ] **Signal handling** — Use exec form for CMD (`["node", "app.js"]` not `CMD node app.js`)
- [ ] **No secrets** — Never pass secrets as build args or environment variables in Dockerfile
- [ ] **Image scanning** — Scan for vulnerabilities before pushing to registry

---

## Production-Ready Docker Compose

```yaml
version: '3.9'

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: api-app
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - LOG_LEVEL=info
    env_file:
      - .env.production
    ports:
      - "3000:3000"
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.5'
          memory: 256M
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
        labels: "app=api"
    healthcheck:
      test: ["CMD", "wget", "-qO-", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 10s
    networks:
      - app-network

  db:
    image: postgres:16-alpine
    container_name: postgres-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASS}
      POSTGRES_INITDB_ARGS: "-c log_statement=all"
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./init-db.sql:/docker-entrypoint-initdb.d/01-init.sql
    ports:
      - "5432:5432"
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "5"
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redisdata:/data
    ports:
      - "6379:6379"
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 3
    networks:
      - app-network

volumes:
  pgdata:
    driver: local
  redisdata:
    driver: local

networks:
  app-network:
    driver: bridge
```

### Key Features

- **Service dependencies** — API waits for DB to be healthy before starting
- **Resource limits** — Both hard limits (limits) and soft reservations (reservations)
- **Logging** — JSON file driver with rotation (10MB max, 3 files)
- **Health checks** — All services have health probes with appropriate intervals
- **Networking** — Custom network for service-to-service communication
- **Volumes** — Named volumes for persistent data with proper ownership
- **Restart policy** — `unless-stopped` keeps services running across reboots
- **Environment** — Loaded from .env.production, not hardcoded

### Usage

```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f api

# Health check
docker-compose ps

# Stop and clean up
docker-compose down -v  # -v removes volumes
```
