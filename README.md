# CTO Toolkit

A comprehensive Claude Code plugin with **24 skills** covering the full software engineering lifecycle — from sprint planning to production incident response.

Built for CTOs, Staff Engineers, and Tech Leads who ship production software.

## Skills

### Code Review (6 skills)

| Skill | What it does |
|-------|-------------|
| `code-review` | Router that detects technology context and delegates to the right specialist |
| `backend-review` | Node.js, Java, Clean Architecture, SOLID, microservices, messaging, payments |
| `frontend-review` | Angular, React, TypeScript, accessibility, performance, CSS |
| `flutter-review` | Dart, BLoC/Cubit, widget architecture, platform channels, performance |
| `security-review` | OAuth2, JWT, RBAC, API security, LGPD/GDPR, payment security |
| `ux-review` | Nielsen heuristics, mobile UX, accessibility, design systems |

### Architecture & Patterns (3 skills)

| Skill | What it does |
|-------|-------------|
| `design-patterns` | SOLID, Clean Architecture, DDD, GoF patterns, refactoring guidance |
| `adr` | Architecture Decision Records (Michael Nygard format) |
| `tech-spec` | Technical specifications / RFCs with 12-section template |

### DevOps & Infrastructure (4 skills)

| Skill | What it does |
|-------|-------------|
| `devops-infra` | Docker, AWS (ECS, Lambda, S3, RDS), CI/CD, Kafka, SQS/SNS, monitoring |
| `terraform-iac` | Terraform modules, state management, security, CI/CD pipelines |
| `observability` | SLOs/SLIs, alerting strategy, dashboards, OpenTelemetry, on-call |
| `cost-optimization` | FinOps, right-sizing, pricing models, cloud waste elimination |

### Quality & Security (3 skills)

| Skill | What it does |
|-------|-------------|
| `testing-strategy` | TDD, BDD, unit/integration/E2E testing, coverage guidelines, QA |
| `pentest` | OWASP Top 10, PTES methodology, vulnerability reporting, STRIDE |
| `systematic-debugging` | Scientific debugging method, binary search, production debugging |

### Database & Performance (3 skills)

| Skill | What it does |
|-------|-------------|
| `database-review` | Schema design, migrations, EXPLAIN plans, indexing, connection pools |
| `performance-profiling` | Node.js/Java/Flutter profiling, load testing, caching strategies |
| `api-documentation` | OpenAPI/Swagger specs, REST design, documentation quality |

### Process & Management (5 skills)

| Skill | What it does |
|-------|-------------|
| `sprint-planning` | User stories (INVEST), estimation, RICE prioritization, roadmaps |
| `git-flow` | Branching strategies, Conventional Commits, PR guidelines, SemVer |
| `pr-description` | Generates senior-level PR descriptions with risk assessment |
| `one-on-one` | 1:1 prep, SBI feedback framework, career development, skip-levels |
| `incident-postmortem` | Blameless postmortems, runbooks, severity classification, escalation |

## Features

- **Progressive disclosure**: Lean SKILL.md files (~100 lines) with deep-dive `references/` loaded on demand
- **Read-only review skills**: `allowed-tools` restricts review skills to read operations only
- **Utility scripts**: Pre-review checks, secret scanning, diff generation
- **21 reference files**: 6,000+ lines of detailed examples, patterns, and templates
- **3 automation scripts**: Shell scripts for common review and security tasks

## Install

```bash
# From GitHub
claude plugin install cto-toolkit@camilooscargbaptista/cto-toolkit

# Or add marketplace
/plugin marketplace add camilooscargbaptista/cto-toolkit
```

## Usage

Skills activate automatically based on context. Examples:

```
"Review this backend code"          → triggers backend-review
"Help me plan the next sprint"      → triggers sprint-planning
"Write a PR description"            → triggers pr-description
"Is this Terraform config secure?"  → triggers terraform-iac
"My API is slow"                    → triggers performance-profiling
"Create an ADR for this decision"   → triggers adr
```

## Tech Stack Coverage

- **Backend**: Node.js, Java, NestJS, Spring Boot, Express
- **Frontend**: Angular, React, TypeScript
- **Mobile**: Flutter, Dart
- **Infrastructure**: Docker, AWS, Terraform, GitHub Actions
- **Databases**: PostgreSQL, MySQL, MongoDB, DynamoDB, Redis
- **Messaging**: Kafka, SQS, SNS
- **Observability**: OpenTelemetry, Prometheus, Grafana, CloudWatch, Datadog

## License

MIT License — see [LICENSE](LICENSE)

## Author

**Girardelli Tecnologia**
Camilo Girardelli — [camilo.baptista@girardellitecnologia.com](mailto:camilo.baptista@girardellitecnologia.com)
