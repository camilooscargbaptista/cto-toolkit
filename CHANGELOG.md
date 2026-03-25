# Changelog

All notable changes to CTO Toolkit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-03-24

### Added — New Skills (12)
- `vendor-evaluation` — Build vs Buy scorecard, vendor lock-in risk, SLA negotiation
- `engineering-budget` — Headcount forecasting, infra cost modeling, ROI analysis
- `on-call-design` — Rotation design, escalation tiers, burnout prevention
- `tech-debt-prioritization` — RICE scoring, Cost of Delay, sprint allocation
- `api-gateway-patterns` — Rate limiting, BFF pattern, circuit breaking
- `multi-tenancy` — Row-level, schema-level, database-level isolation
- `feature-flags` — Toggle strategies, rollout patterns, flag lifecycle
- `domain-modeling` — Event Storming, Bounded Contexts, Aggregates, DDD
- `architecture-review-board` — RFC governance, decision log, ARB process
- `csharp-dotnet-review` — ASP.NET Core, EF Core, Minimal APIs, Azure
- `swift-review` — SwiftUI, Combine, iOS architecture, App Store guidelines
- `elixir-review` — OTP, GenServer, LiveView, fault tolerance

### Added — Reference Documentation (22 files)
- `security-review/references/` — OWASP Top 10, JWT patterns, RBAC implementation
- `observability/references/` — OpenTelemetry setup, alerting anti-patterns, SLO guide
- `database-review/references/` — PostgreSQL optimization, migration patterns, N+1 solutions
- `incident-postmortem/references/` — Postmortem template, runbook template, severity matrix
- `pentest/references/` — API pentest checklist, OWASP testing guide
- `flutter-review/references/` — BLoC patterns, performance checklist, platform channels
- `kubernetes-review/references/` — K8s security hardening, Helm best practices
- `compliance-review/references/` — SOC2 evidence templates, LGPD implementation guide

### Added — Automation Scripts (8)
- `scripts/architecture-lint.sh` — Clean Architecture layer boundary validation
- `scripts/dependency-audit.sh` — Security, outdated and unused dependency checks
- `scripts/migration-check.sh` — Migration naming, ordering and safety validation
- `scripts/dora-collect.sh` — DORA metrics from Git history
- `scripts/compliance-scan.sh` — PII in logs, secrets, AWS keys, insecure URLs
- `scripts/dead-code-finder.sh` — Unused exports, orphan files, commented blocks
- `scripts/test-coverage-gate.sh` — Coverage threshold enforcement
- `scripts/api-breaking-changes.sh` — OpenAPI diff and route change detection

### Added — New Hooks (4)
- `PostToolUse` — Dockerfile security check (non-root, multi-stage, no secrets)
- `PostToolUse` — SQL migration naming and safety validation
- `PostToolUse` — Test quality check (descriptive names, edge cases)
- `PreToolUse` — Destructive bash command blocker

### Added — Project Infrastructure
- `CONTRIBUTING.md` — Contribution guide with SKILL.md template
- `CHANGELOG.md` — This file
- `scripts/sync-skills.sh` — Skill synchronization to target projects

## [2.0.0] - 2026-03-23

### Added
- 5 autonomous agents (architecture-reviewer, security-auditor, etc.)
- 4 workflow orchestrators
- Hooks system (post-edit security check, session review)
- README v2.0 with full documentation

## [1.0.0] - 2025-12-01

### Added
- Initial release with 24 skills
- Plugin configuration for Claude Code
