# CTO Toolkit

The ultimate Claude Code plugin for engineering leadership — **54 skills, 6 autonomous agents, 9 automation scripts, 9 intelligent hooks, and workflow orchestrators** covering the full software engineering lifecycle. Now with **declarative skill activation**, **model routing**, and **continuous learning**.

Built for CTOs, VPs of Engineering, Staff Engineers, and Tech Leads who ship production software.

## What's New in v3.1

- **Declarative Skill Activation** — All 54 skills now declare triggers in YAML frontmatter (frameworks, anti-patterns, score thresholds, file patterns, domains, dimension thresholds). Skills self-activate based on project context
- **Model Routing** — Skills and agents declare preferred model tier (haiku/sonnet/opus) with dynamic escalation. Security-critical tasks auto-upgrade to opus; quick scans use haiku for 10x cost savings
- **Continuous Learning** — New `session-learning.sh` Stop hook tracks session patterns (languages, tests, security activity) and generates improvement insights every 10 sessions
- **Auto-Activation** — New `SessionStart` hook scans the project, detects frameworks/file patterns, and suggests relevant skills automatically at the start of each session
- **Model Routing Advisory** — New `PostToolUse` hook detects when security-critical or financial files are edited and suggests deeper analysis with opus-tier models
- **Deploy Safety Guard** — New `PreToolUse` hook intercepts production deployment commands and verifies safety (explicit env, no --force, dry-run first)
- **Agent Model Upgrades** — adversarial-reviewer, architecture-reviewer, security-auditor, and release-readiness agents upgraded to opus by default with escalation rules
- **Dependency Graph** — Skills declare `depends-on` for optimal execution ordering via topological sort

## What's New in v3.0

- **12 New Skills** — vendor-evaluation, engineering-budget, on-call-design, tech-debt-prioritization, api-gateway-patterns, multi-tenancy, feature-flags, domain-modeling, architecture-review-board, C#/.NET review, Swift/iOS review, Elixir/Phoenix review
- **22 New Reference Files** — deep-dive docs for security (OWASP, JWT, RBAC), observability (OTEL, SLOs), database (PostgreSQL, N+1), incident response, pentest, Flutter, Kubernetes, and LGPD compliance
- **8 Automation Scripts** — architecture lint, dependency audit, migration check, DORA metrics, compliance scan, dead code finder, test coverage gate, API breaking changes detector
- **4 New Hooks** — Dockerfile security, SQL migration validation, test quality check, destructive command blocker
- **Project Infrastructure** — CONTRIBUTING.md, CHANGELOG.md, sync-skills.sh for multi-project synchronization
- **Total: 42 reference files** across 13 skills with actionable patterns and templates

## Agents

Autonomous subagents that scan your codebase and produce comprehensive reports without manual guidance. Agents now declare `model-routing` with escalation rules — they start at a cost-efficient tier and upgrade to opus when critical findings are detected.

| Agent | Model | What it does |
|-------|-------|-------------|
| `architecture-reviewer` | sonnet → opus | Scans the entire codebase and produces an Architecture Health Report with scores by dimension |
| `security-auditor` | opus | Full security audit — secrets, OWASP Top 10, auth, injection, dependencies |
| `adversarial-reviewer` | opus | Challenges architectural decisions — stress-tests ADRs, finds hidden risks, devil's advocate |
| `tech-debt-analyzer` | sonnet → opus | Inventories all tech debt, prioritizes by ROI, produces a sprint reduction plan |
| `onboarding-guide` | sonnet → opus | Explores the project and generates a complete Developer Onboarding Guide |
| `release-readiness` | sonnet → opus | Evaluates production readiness — Go/No-Go report across 7 dimensions |

## Workflow Orchestrators

| Skill | What it does |
|-------|-------------|
| `full-review` | Orchestrates code review + security + performance + database + architecture + testing into one consolidated report |
| `health-check` | Runs architecture, tech debt, and security analysis to produce a Project Health Dashboard with scores and roadmap |

## Skills (54 total)

### Code Review (12 skills)

| Skill | What it does |
|-------|-------------|
| `code-review` | Router that detects technology context and delegates to the right specialist |
| `backend-review` | Node.js, Java, Clean Architecture, SOLID, microservices, messaging, payments |
| `frontend-review` | Angular, React, TypeScript, accessibility, performance, CSS |
| `flutter-review` | Dart, BLoC/Cubit, widget architecture, platform channels, performance |
| `python-review` | Django, FastAPI, Flask, async/await, type hints, Pythonic patterns |
| `go-review` | Goroutines, channels, error handling, interfaces, concurrency safety |
| `rust-review` | Ownership, lifetimes, unsafe, error handling with Result/Option, async Rust |
| `csharp-dotnet-review` | ASP.NET Core, EF Core, Minimal APIs, CQRS, MediatR, Azure patterns |
| `swift-review` | SwiftUI, Combine, UIKit, MVVM/TCA, App Store guidelines, iOS performance |
| `elixir-review` | OTP, GenServer, Phoenix LiveView, fault tolerance, supervision trees |
| `security-review` | OAuth2, JWT, RBAC, API security, LGPD/GDPR, payment security |
| `ux-review` | Nielsen heuristics, mobile UX, accessibility, design systems |

### Architecture & Patterns (8 skills)

| Skill | What it does |
|-------|-------------|
| `design-patterns` | SOLID, Clean Architecture, DDD, GoF patterns, refactoring guidance |
| `adr` | Architecture Decision Records (Michael Nygard format) |
| `tech-spec` | Technical specifications / RFCs with 12-section template |
| `event-driven-architecture` | Event Sourcing, CQRS, Saga patterns, Domain Events, Kafka architecture |
| `api-gateway-patterns` | Rate limiting, BFF pattern, circuit breaking, API versioning, request aggregation |
| `multi-tenancy` | Row-level, schema-level, database-level isolation, tenant routing |
| `feature-flags` | Toggle strategies, rollout patterns (canary, %), kill switches, flag lifecycle |
| `domain-modeling` | Event Storming, Bounded Contexts, Aggregates, Value Objects, Domain Events |

### DevOps & Infrastructure (5 skills)

| Skill | What it does |
|-------|-------------|
| `devops-infra` | Docker, AWS (ECS, Lambda, S3, RDS), CI/CD, Kafka, SQS/SNS, monitoring |
| `terraform-iac` | Terraform modules, state management, security, CI/CD pipelines |
| `kubernetes-review` | K8s manifests, Helm charts, pod security, RBAC, network policies, GitOps |
| `observability` | SLOs/SLIs, alerting strategy, dashboards, OpenTelemetry, on-call |
| `cost-optimization` | FinOps, right-sizing, pricing models, cloud waste elimination |

### Data & AI (2 skills)

| Skill | What it does |
|-------|-------------|
| `data-engineering` | Pipelines, ETL/ELT, data quality, data contracts, dbt, Airflow, governance |
| `ai-ml-engineering` | MLOps, model serving, LLM integration, RAG, evaluation, responsible AI |

### Quality & Security (4 skills)

| Skill | What it does |
|-------|-------------|
| `testing-strategy` | TDD, BDD, unit/integration/E2E testing, coverage guidelines, QA |
| `pentest` | OWASP Top 10, PTES methodology, vulnerability reporting, STRIDE |
| `systematic-debugging` | Scientific debugging method, binary search, production debugging |
| `compliance-review` | SOC2, HIPAA, PCI-DSS, ISO 27001, LGPD/GDPR checklists and controls |

### Database, Performance & API (4 skills)

| Skill | What it does |
|-------|-------------|
| `database-review` | Schema design, migrations, EXPLAIN plans, indexing, connection pools |
| `performance-profiling` | Node.js/Java/Flutter profiling, load testing, caching strategies |
| `api-documentation` | OpenAPI/Swagger specs, REST design, documentation quality |
| `graphql-review` | Schema design, N+1 prevention, query complexity, federation, security |

### Process & Management (13 skills)

| Skill | What it does |
|-------|-------------|
| `sprint-planning` | User stories (INVEST), estimation, RICE prioritization, roadmaps |
| `git-flow` | Branching strategies, Conventional Commits, PR guidelines, SemVer |
| `pr-description` | Generates senior-level PR descriptions with risk assessment |
| `one-on-one` | 1:1 prep, SBI feedback framework, career development, skip-levels |
| `incident-postmortem` | Blameless postmortems, runbooks, severity classification, escalation |
| `engineering-metrics` | DORA metrics, cycle time, developer productivity, investment allocation |
| `team-scaling` | Org design, engineering ladder, team topologies, hiring framework |
| `technical-interview` | Interview plans, rubrics, system design questions, scorecards |
| `vendor-evaluation` | Build vs Buy scorecard, vendor lock-in risk, SLA negotiation |
| `engineering-budget` | Headcount forecasting, infrastructure cost modeling, ROI analysis |
| `on-call-design` | Rotation design, escalation tiers, burnout prevention, runbook standards |
| `tech-debt-prioritization` | RICE scoring, Cost of Delay, sprint allocation, stakeholder communication |
| `architecture-review-board` | RFC governance, decision log, ARB process, review criteria |

### Operational Excellence (3 skills)

| Skill | What it does |
|-------|-------------|
| `chaos-engineering` | Resilience testing, fault injection, game days, experiment design |
| `migration-strategy` | Monolith to microservices, cloud migration, strangler fig, database migration |
| `developer-experience` | DX audit, build times, CI/CD speed, onboarding friction, golden paths |

### Cross-Cutting (1 skill)

| Skill | What it does |
|-------|-------------|
| `quality-standard` | Protocol enforcing self-verification, edge case analysis, and quality gates across all skills |

## Automation Scripts

Shell scripts for CI/CD integration and manual audits.

| Script | What it does |
|--------|-------------|
| `architecture-lint.sh` | Validates Clean Architecture layer boundaries (domain → infra, HTTP leakage) |
| `dependency-audit.sh` | Checks vulnerabilities, outdated packages, unused dependencies, lock files |
| `migration-check.sh` | Validates migration naming, ordering, dangerous operations (DROP, TRUNCATE) |
| `dora-collect.sh` | Collects DORA metrics from Git history (deploy frequency, lead time, failure rate) |
| `compliance-scan.sh` | Scans for PII in logs, hardcoded secrets, AWS keys, insecure HTTP URLs |
| `dead-code-finder.sh` | Finds unused exports, orphan files, large commented-out blocks |
| `test-coverage-gate.sh` | Enforces coverage threshold (supports Jest, Vitest, Flutter, pytest) |
| `api-breaking-changes.sh` | Detects removed routes, changed DTOs, OpenAPI spec diffs |
| `sync-skills.sh` | Synchronizes skills + references from toolkit to target projects |

## Hooks

Automatic event handlers that run silently in the background across 4 lifecycle phases.

| Event | What it does |
|-------|-------------|
| `SessionStart` | **Auto-Activation** — Detects frameworks, file patterns, and project context. Suggests relevant skills |
| `PreToolUse` (Bash) | Blocks destructive commands (rm -rf /, DROP DATABASE, fork bombs) |
| `PreToolUse` (Bash) | **Deploy Safety Guard** — Verifies production deploy commands (kubectl, terraform, npm publish) |
| `PostToolUse` (Write/Edit) | Scans edited files for hardcoded secrets, dangerous functions, SQL injection |
| `PostToolUse` (Write) | Validates Dockerfile security (non-root, multi-stage, no secrets, no :latest) |
| `PostToolUse` (Write) | Validates SQL migration naming and safety (CONCURRENTLY, NOT NULL + DEFAULT) |
| `PostToolUse` (Write/Edit) | Checks test quality (descriptive names, edge cases, no console.log) |
| `PostToolUse` (Write/Edit) | **Model Routing Advisory** — Suggests opus-tier analysis for security-critical/financial files |
| `Stop` | Reviews session work for security, error handling, and naming quality |
| `Stop` | **Session Learning** — Records session patterns for continuous improvement insights |

## Features

- **Declarative activation**: Skills declare triggers in YAML frontmatter — frameworks, anti-patterns, scores, file patterns, domains
- **Model routing**: Each skill and agent declares preferred model tier (haiku/sonnet/opus) with dynamic escalation on critical findings
- **Continuous learning**: Session patterns recorded in `.cto-toolkit/learning/` — insights generated every 10 sessions
- **Dependency graph**: Skills declare `depends-on` for topological ordering — compliance runs after security, not before
- **Progressive disclosure**: Lean SKILL.md files (~100-150 lines) with deep-dive `references/` loaded on demand
- **42 reference files**: 8,000+ lines of detailed examples, patterns, and templates across 13 skills
- **Read-only review skills**: `allowed-tools` restricts review skills to read operations only
- **Autonomous agents**: 6 agents that analyze codebases end-to-end without user guidance
- **Workflow orchestration**: Multi-skill coordination with consolidated reports
- **Intelligent hooks**: 9 hooks across 4 lifecycle phases (SessionStart, PreToolUse, PostToolUse, Stop)
- **9 automation scripts**: CI/CD-ready shell scripts for architecture, security, and quality gates
- **Multi-project sync**: `sync-skills.sh` propagates toolkit updates to all your projects

## Install

```bash
# Test locally
claude --plugin-dir /path/to/cto-toolkit

# Or add as marketplace
/plugin marketplace add camilooscargbaptista/cto-toolkit
```

## Sync to Projects

```bash
# Sync all skills + references to another project
./scripts/sync-skills.sh ~/your-project .gemini/antigravity/skills
```

## Usage

Skills and agents activate automatically based on context:

```
"Review this C# controller"               → triggers csharp-dotnet-review
"Do a full security audit"                → triggers security-auditor agent
"How healthy is this project?"            → triggers health-check workflow
"Help me evaluate this vendor"            → triggers vendor-evaluation
"Plan the engineering budget"             → triggers engineering-budget
"Design our on-call rotation"            → triggers on-call-design
"Prioritize our tech debt"               → triggers tech-debt-prioritization
"Design the multi-tenant architecture"   → triggers multi-tenancy
"Set up feature flags"                    → triggers feature-flags
"Model this domain"                       → triggers domain-modeling
"Review this API gateway config"          → triggers api-gateway-patterns
"Run an architecture review board"       → triggers architecture-review-board
"Prepare for SOC2 audit"                 → triggers compliance-review
"Plan the migration to microservices"    → triggers migration-strategy
"Run a chaos engineering game day"       → triggers chaos-engineering
```

## Tech Stack Coverage

- **Backend**: Node.js, Java, Python, Go, Rust, C#/.NET, Elixir, NestJS, Spring Boot, Django, FastAPI, Flask, Gin, Axum, ASP.NET Core, Phoenix
- **Frontend**: Angular, React, TypeScript
- **Mobile**: Flutter, Dart, Swift/SwiftUI, UIKit
- **Infrastructure**: Docker, Kubernetes, AWS, Terraform, GitHub Actions, ArgoCD
- **Data**: PostgreSQL, MySQL, MongoDB, DynamoDB, Redis, Kafka, SQS, SNS, dbt, Airflow, Spark
- **AI/ML**: LLM integration, RAG, MLOps, model serving, evaluation frameworks
- **GraphQL**: Apollo, Relay, Federation, DataLoader
- **Observability**: OpenTelemetry, Prometheus, Grafana, CloudWatch, Datadog
- **Compliance**: SOC2, HIPAA, PCI-DSS, ISO 27001, LGPD, GDPR

## License

MIT License — see [LICENSE](LICENSE)

## Author

**Girardelli Tecnologia**
Camilo Girardelli — [camilo.baptista@girardellitecnologia.com](mailto:camilo.baptista@girardellitecnologia.com)