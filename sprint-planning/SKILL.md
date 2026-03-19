---
name: sprint-planning
description: "**Sprint & Release Planning**: Helps with sprint planning, backlog grooming, story estimation, release planning, and roadmap creation. Use this skill whenever the user wants to plan a sprint, groom the backlog, write user stories, estimate tasks, plan a release, create a roadmap, prioritize features, or structure a planning meeting. Trigger when the user mentions 'sprint', 'backlog', 'story points', 'estimation', 'velocity', 'roadmap', 'release plan', 'prioritization', 'epic', 'user story', or asks about how to organize upcoming work."
---

# Sprint & Release Planning

This skill helps you run effective planning processes — from writing good user stories to building quarterly roadmaps. Adapt the level of formality to your team's size and culture.

## User Story Writing

A well-written story communicates intent without over-prescribing implementation.

### Format
```
As a [type of user],
I want to [action/capability],
so that [benefit/value].
```

### Acceptance Criteria
Use the Given-When-Then format for testable criteria:
```
Given [precondition],
When [action],
Then [expected result].
```

### Story Quality Checklist (INVEST)
- **I**ndependent — Can be developed without depending on another story
- **N**egotiable — Details can be discussed; it's not a rigid spec
- **V**aluable — Delivers value to the user or business
- **E**stimable — Team can roughly estimate the effort
- **S**mall — Completable within one sprint
- **T**estable — Has clear acceptance criteria

### Good vs Bad Stories

**Bad**: "Implement search functionality"
**Good**: "As a customer, I want to search products by name and category, so that I can quickly find what I'm looking for."

**Bad**: "Fix the login bug"
**Good**: "As a user who forgot their password, I want the reset email to arrive within 2 minutes, so that I'm not stuck waiting (currently takes 10+ minutes due to queue backlog)."

## Sprint Planning Meeting

### Prep (before the meeting)
1. Product owner has a prioritized backlog with refined stories
2. Top stories have acceptance criteria and basic technical context
3. Team's velocity from last 3 sprints is known
4. Carry-over items from last sprint are identified

### Meeting Structure (2 hours max for a 2-week sprint)

**Part 1: What (30 min)**
- Product owner presents sprint goal and top-priority stories
- Team asks clarifying questions
- Align on what "done" means for each story

**Part 2: How (60 min)**
- Team breaks stories into tasks
- Estimation (story points or t-shirt sizes)
- Identify dependencies and risks
- Team commits to a realistic sprint backlog

**Part 3: Commitment (15 min)**
- Review the sprint goal
- Confirm total points are within velocity range
- Flag any concerns or blockers
- Everyone agrees they can commit

### Estimation Guide

Use Fibonacci (1, 2, 3, 5, 8, 13) or T-shirt sizes (XS, S, M, L, XL).

| Points | Meaning | Example |
|--------|---------|---------|
| 1 | Trivial, well-understood | Fix a typo, update a config |
| 2 | Small, straightforward | Add a field to an existing form |
| 3 | Medium, some complexity | New API endpoint with validation |
| 5 | Significant, multiple components | Feature with frontend + backend + tests |
| 8 | Large, uncertainty involved | New integration with external service |
| 13 | Very large — consider splitting | Full authentication flow from scratch |

If a story is >8 points, push to break it down. Stories that are too large hide complexity and create surprises mid-sprint.

## Release Planning

### Release Checklist
```markdown
# Release [Version] — [Date]

## Pre-Release
- [ ] All stories in "Done" column meet acceptance criteria
- [ ] QA sign-off on regression test suite
- [ ] Performance testing completed (load test results linked)
- [ ] Security review completed (if applicable)
- [ ] Database migrations tested on staging
- [ ] Feature flags configured for gradual rollout
- [ ] Rollback plan documented and tested
- [ ] Release notes drafted

## Deploy
- [ ] Staging deployment successful
- [ ] Smoke tests passing on staging
- [ ] Production deployment initiated
- [ ] Canary metrics monitored (15 min)
- [ ] Full rollout completed
- [ ] Post-deploy smoke tests passing

## Post-Release
- [ ] Monitoring dashboards reviewed (1 hour)
- [ ] Release notes published
- [ ] Stakeholders notified
- [ ] Retrospective scheduled
```

## Roadmap Planning

### Prioritization Framework: RICE

Score each initiative:
- **R**each — How many users/customers affected per quarter?
- **I**mpact — How much does it move the metric? (3=massive, 2=high, 1=medium, 0.5=low, 0.25=minimal)
- **C**onfidence — How sure are you about reach and impact? (100%=high, 80%=medium, 50%=low)
- **E**ffort — Person-months to complete

**RICE Score = (Reach x Impact x Confidence) / Effort**

Higher score = higher priority. This doesn't replace judgment but makes trade-offs explicit and comparable.

### Quarterly Roadmap Template
```markdown
# Q[X] [Year] Engineering Roadmap

## Theme: [One-line description of the quarter's focus]

## Committed (high confidence, resourced)
1. [Initiative] — [Team] — [Goal/Metric]
2. [Initiative] — [Team] — [Goal/Metric]

## Planned (medium confidence, tentatively resourced)
3. [Initiative] — [Team] — [Goal/Metric]
4. [Initiative] — [Team] — [Goal/Metric]

## Exploratory (low confidence, needs scoping)
5. [Initiative] — [Owner for scoping]

## Tech Debt / Platform
- [Item] — [Justification]

## Not Doing This Quarter (and why)
- [Item] — [Reason]
```

The "Not Doing" section is as important as the committed items — it sets expectations and prevents scope creep.
