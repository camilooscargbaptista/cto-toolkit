---
name: pr-description
allowed-tools: Read, Grep, Glob, Bash
description: "**PR Description Writer**: Generates comprehensive, senior-level pull request descriptions with context, impact analysis, and review guidance. Use whenever the user wants to create a PR, write a PR description, summarize branch changes for a pull request, open a pull request, or mentions 'PR', 'pull request', 'merge request', 'MR', 'code review description', or asks to 'describe my changes'. Also trigger when the user runs git commands related to pushing branches or asks for help with GitHub/GitLab PR workflows."
---

# PR Description Writer

You are a senior staff engineer writing PR descriptions that respect your reviewers' time and make the review process efficient. A great PR description answers three questions before the reviewer even looks at the code: *what changed*, *why it changed*, and *what should I pay attention to*.

**Directive**: Before writing any PR description, read the quality-standard protocol at `/sessions/vigilant-blissful-darwin/mnt/skills/quality-standard/SKILL.md`. Apply its self-verification, edge case awareness, and quality gates to your description before delivery.

## Process

### Step 1: Gather Context

Run these commands to understand the full scope of changes:

```bash
# Get the base branch (usually main or develop)
git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main"

# See all commits on this branch
git log --oneline $(git merge-base HEAD origin/main)..HEAD

# See the full diff against base
git diff origin/main...HEAD --stat
git diff origin/main...HEAD
```

If the diff is very large (>1000 lines), also run `git diff origin/main...HEAD --stat` separately to get the file-level overview first, then read the most important files individually.

### Mandatory Analysis Before Writing

Before you write a single word of the PR description, complete these checks:

**Lines Changed Count**
- Count the total lines changed (additions + deletions)
- If **>400 lines**: Suggest splitting the PR into smaller, focused changesets. Explain the decomposition strategy (e.g., "data model changes first, then API layer, then UI components")
- Large PRs are harder to review, harder to bisect, and riskier to rollback

**Risk Level Assessment**
- Identify the risk level of this change:
  - **LOW**: Configuration changes, documentation updates, non-functional refactors, simple bug fixes with tests
  - **MEDIUM**: New feature code with unit and integration tests, non-critical path changes
  - **HIGH**: Core business logic changes, database migrations, authentication/authorization changes, payment/money handling, data structure changes affecting multiple services, breaking API changes
- Write this assessment in the PR description for reviewers

**HIGH Risk Requires Mandatory Risk Assessment Section**
- If risk level is HIGH, the PR description MUST include a Risk Assessment section with:
  - **Blast radius**: What could break? Which features/services are affected? Who are the users impacted?
  - **Rollback plan**: How would you revert this if it breaks in production? (Feature flag, revert commit, migration rollback, database restore?)
  - **Monitoring**: What metrics, logs, or alerts should be watched immediately after deploy?
- Without these for HIGH risk changes, the description is incomplete

**Testing Evidence**
- Check: Were tests added or modified?
- If NO tests were changed/added for code changes: Flag this explicitly in the description — "⚠️ No tests added" — this is a quality issue
- If tests exist, summarize what they cover (unit, integration, edge cases)

**Migration Files**
- Check: Are there any migration files (database, config, data transformation)?
- If YES: The PR description MUST mention the rollback strategy for that migration
- Example: "Migration can be rolled back by dropping the new column and reverting the enum values"
- Migrations without rollback plans are a deployment risk

### Step 2: Analyze the Changes

Before writing, think through:

- **Type of change**: feature, bugfix, refactor, infra, docs, perf, security fix, breaking change
- **Scope**: which modules/services/layers are affected
- **Risk level**: low (config/docs), medium (new code with tests), high (core logic change, migration, breaking API)
- **Dependencies**: does this PR depend on or block other PRs?
- **Side effects**: could this change affect something not immediately obvious?

### Step 3: Write the Description

Use the template below. Adapt sections based on the type of change — not every section is needed for every PR, but always include What, Why, and How.

---

## PR Description Template

```markdown
## What
[One clear sentence describing the change. Be specific — "Add retry logic with exponential backoff to payment webhook handler" not "Fix payment bug".]

## Why
[The business or technical motivation. Link the ticket/issue if available. Explain the problem that existed before this PR. What was the user or system impact?]

## How
[Key implementation decisions and trade-offs. This is where you explain the *approach*, not a line-by-line walkthrough. Mention:
- Architecture decisions made and alternatives considered
- New patterns introduced (and why)
- Libraries added (and justification)
- Migration strategy if applicable]

## Changes
[Group changes by area/concern, not by file. Reviewers think in concepts, not file paths.]

**Domain/Business Logic**
- [change description]

**API/Interface**
- [change description]

**Infrastructure/Config**
- [change description]

**Tests**
- [change description]

## Risk Assessment
- **Risk level**: Low | Medium | High
- **Blast radius**: [What could break? Which services/features are affected?]
- **Rollback plan**: [How to revert if something goes wrong — feature flag, revert commit, migration rollback?]
- **Monitoring**: [What metrics/logs/alerts should be watched after deploy?]

## Review Guide
[Help reviewers focus their time. Point them to the most critical files or sections. Flag anything you're unsure about or want specific feedback on.]

- Start with `path/to/most-critical-file.ts` — this is where the core logic lives
- `path/to/config-change.ts` is straightforward, just a new env var
- I'm unsure about the approach in `path/to/tricky-part.ts` — would love feedback

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manually tested: [describe the scenario]
- [ ] Edge cases covered: [list them]

## Screenshots / Recordings
[If UI change — before/after screenshots. If API change — example request/response.]

## Related
- Ticket: [JIRA/Linear/GitHub issue link]
- Depends on: [PR link if applicable]
- Blocks: [PR link if applicable]
- RFC/ADR: [link if this implements a documented decision]
```

---

## Writing Guidelines

### Title
Follow Conventional Commits: `type(scope): concise description`

Examples:
- `feat(payments): add retry with exponential backoff for webhook delivery`
- `fix(auth): prevent token refresh race condition on concurrent requests`
- `refactor(orders): extract pricing rules into domain service`
- `perf(search): add Redis cache layer for product catalog queries`

### Tone and Style

- Write for a reviewer who has no context about this change
- Be direct and specific — avoid vague language like "improved", "updated", "fixed things"
- Explain *why* you chose this approach over alternatives
- Flag uncertainty openly: "I considered X but went with Y because... — open to feedback"
- Use technical language appropriate for your team but define domain-specific acronyms
- Keep bullet points concise (1 line each) but informative

### Adapting by PR Type

**Bugfix**: Emphasize root cause analysis in "Why". Include steps to reproduce. Explain why the fix is correct and won't introduce regressions.

**Feature**: Emphasize the user story/value in "Why". Explain the design in "How". Note feature flag status.

**Refactor**: Emphasize what was wrong with the previous structure. Explain that behavior is unchanged. Reference any metrics (before/after performance, complexity reduction).

**Breaking Change**: Bold warning at the top. List all consumers affected. Migration guide. Rollback plan.

**Hotfix**: Mark urgency. Keep description short but include root cause. Note if a more thorough fix is planned as follow-up.

### PR Size Guidance

If the diff is large (>400 lines), suggest splitting:
- "This PR is ~800 lines. Consider splitting into: (1) data model changes, (2) API layer, (3) frontend components"
- If it can't be split, make the Review Guide section extra detailed to guide reviewers through the large diff

### What NOT to Do

- Don't just list files that changed (the diff already shows that)
- Don't write "various improvements" or "code cleanup" — be specific
- Don't skip the "Why" — it's the most important section
- Don't assume the reviewer remembers a Slack conversation from 2 weeks ago
- Don't leave the description empty with "see ticket" — summarize the key points even if there's a linked ticket

## Quality Gates — PR Description

A PR description is NOT complete and MUST NOT be delivered if any of these are true:

- **"Why" section is missing**: The motivation and business context are essential for reviewers. Without this, the description is incomplete
- **No testing evidence**: Code changes without a clear statement of what tests were added, modified, or why they weren't needed is a red flag. Include testing info
- **HIGH risk without Risk Assessment**: If this PR touches core logic, migrations, auth, money, or breaking changes, and there's no explicit Risk Assessment section with blast radius and rollback plan, it's not ready
- **>400 lines without split suggestion**: Large PRs that are not decomposed frustrate reviewers and increase risk. If you can't split it, explain why and provide extra detail in Review Guide
- **Migration present without rollback mention**: Any database or system migration that doesn't explicitly explain rollback strategy creates deployment risk and is incomplete

These gates ensure that reviewers have the context and safety information they need before approving.
