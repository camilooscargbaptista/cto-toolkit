---
name: git-flow
description: "**Git Workflow & Branching Strategy**: Helps define and follow Git branching strategies (Git Flow, GitHub Flow, Trunk-Based), write good commit messages, manage releases, and resolve merge conflicts. Use whenever the user asks about Git workflow, branching strategy, commit conventions, release management, merge conflicts, or mentions 'git flow', 'branching', 'commit message', 'conventional commits', 'release branch', 'hotfix', 'merge conflict', 'rebase', 'cherry-pick', or asks how to organize their Git workflow."
---

# Git Workflow & Branching Strategy

Help teams choose and follow the right Git workflow. The best workflow is the one your team actually follows consistently.

## Branching Strategies

### Git Flow (for versioned releases)

Best for: Products with scheduled releases, mobile apps, products with multiple supported versions.

```
main ─────────●─────────────────●─────────── (production)
              │                 │
release/1.0 ──┼──●──●──────────┘
              │  │
develop ──────┼──┼──●──●──●──●──●──●──────── (integration)
              │     │     │        │
feature/auth ─┘     │     │        │
feature/cart ───────┘     │        │
hotfix/crash ─────────────┘        │
feature/search ────────────────────┘
```

**Branches:**
- `main` — Production code. Every commit is a release tag.
- `develop` — Integration branch. Features merge here.
- `feature/*` — New features. Branch from develop, merge to develop.
- `release/*` — Release prep. Branch from develop, merge to main + develop.
- `hotfix/*` — Production fixes. Branch from main, merge to main + develop.

### GitHub Flow (for continuous deployment)

Best for: SaaS, web apps, teams deploying multiple times per day.

```
main ──●──●──●──●──●──●──●── (always deployable)
       │     │        │
       │     │        └── feat/notifications (short-lived)
       │     └── fix/login-bug
       └── feat/dashboard
```

**Rules:**
- `main` is always deployable
- Branch from main for any change
- Open a PR, get review, merge to main
- Deploy after merge (automated)
- No long-lived branches

### Trunk-Based Development (for high-performing teams)

Best for: Experienced teams with strong CI, feature flags, and automated testing.

```
main ──●──●──●──●──●──●──●── (deploy continuously)
       │  │
       └──┘ (very short-lived branches, <1 day)
```

**Rules:**
- Everyone commits to main (or very short branches, <1 day)
- Feature flags for incomplete features
- Requires excellent CI/CD and test coverage
- No long-lived branches ever

## Choosing a Strategy

| Factor | Git Flow | GitHub Flow | Trunk-Based |
|--------|----------|-------------|-------------|
| Release cadence | Scheduled | Continuous | Continuous |
| Team experience | Any | Any | High |
| CI/CD maturity | Low-Medium | Medium | High |
| Feature flags | Optional | Optional | Required |
| Code review | On merge to develop | On PR | On PR or pair |

## Commit Message Convention

Use **Conventional Commits** for consistency and automated changelog:

```
<type>(<scope>): <short description>

[optional body — explain WHY, not WHAT]

[optional footer — BREAKING CHANGE, issue refs]
```

### Types

| Type | When |
|------|------|
| `feat` | New feature for the user |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `style` | Formatting, no code change |
| `refactor` | Code change that neither fixes nor adds |
| `perf` | Performance improvement |
| `test` | Adding or fixing tests |
| `chore` | Build process, dependencies, CI |
| `ci` | CI/CD configuration changes |

### Examples

```
feat(auth): add OAuth2 login with Google

Implements Google OAuth2 using authorization code flow with PKCE.
Refresh tokens are stored in httpOnly cookies.

Closes #142

---

fix(payment): prevent double-charge on retry

The payment service was not checking idempotency keys on retries,
causing duplicate charges when the client retried after a timeout.

Fixes #256

---

refactor(orders): extract pricing logic into domain service

Moved discount calculation from OrderController to PricingService
to align with Clean Architecture (business logic in domain layer).

BREAKING CHANGE: OrderDTO no longer includes calculatedDiscount field.
Clients should call GET /orders/:id/pricing instead.
```

### Bad Commit Messages

```
❌ "fix bug"
❌ "update code"
❌ "WIP"
❌ "changes"
❌ "asdfgh"
❌ "fix: fix the thing that was broken"
```

## Pull Request Guidelines

### PR Title
Follow the same Conventional Commits format: `feat(scope): description`

### PR Description Template
```markdown
## What
[Brief description of the change]

## Why
[Motivation — link to issue/ticket]

## How
[Key implementation decisions, if not obvious from the code]

## Testing
[How was this tested? What scenarios were covered?]

## Screenshots
[If UI change — before/after]

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented in BREAKING CHANGE)
- [ ] PR is <400 lines (split if larger)
```

### PR Size Guidelines
- **Ideal:** <200 lines changed
- **Acceptable:** 200-400 lines
- **Too large:** >400 lines (split into smaller PRs)
- Large PRs get worse reviews. Small PRs merge faster.

## Release Management

### Semantic Versioning (SemVer)
```
MAJOR.MINOR.PATCH
  │     │     └── Bug fixes (backward compatible)
  │     └──────── New features (backward compatible)
  └────────────── Breaking changes
```

### Release Checklist
1. Create release branch from develop: `release/v1.2.0`
2. Bump version numbers
3. Update CHANGELOG.md
4. Final QA on release branch
5. Merge to main + tag: `git tag -a v1.2.0 -m "Release v1.2.0"`
6. Merge back to develop
7. Deploy from main

### Hotfix Process
1. Branch from main: `hotfix/v1.2.1`
2. Fix the issue
3. Bump patch version
4. Merge to main + tag
5. Merge to develop (don't forget!)
6. Deploy immediately

## Common Git Operations

### Resolving Merge Conflicts
1. `git fetch origin`
2. `git merge origin/main` (or rebase)
3. Resolve conflicts in each file
4. `git add <resolved files>`
5. `git commit` (or `git rebase --continue`)

**Rule:** When in doubt, talk to the other developer whose code conflicts with yours.

### Interactive Rebase (cleaning up before PR)
```bash
git rebase -i HEAD~3  # Squash/reorder last 3 commits
```
Use before opening a PR to create a clean, logical commit history. Don't rebase commits that are already pushed and shared.

### Cherry-Pick (applying specific commits)
```bash
git cherry-pick <commit-hash>  # Apply a specific fix to another branch
```
Common for applying hotfixes to release branches.
