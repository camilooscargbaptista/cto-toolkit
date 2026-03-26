---
name: team-scaling
description: "**Team Scaling & Engineering Organization**: Designs engineering org structures, career ladders, hiring processes, and team topologies. Covers engineering levels, job descriptions, interview frameworks, org design patterns, team autonomy, and scaling from startup to enterprise. Use when the user mentions team scaling, org design, engineering ladder, career levels, hiring, team topologies, engineering manager, tech lead, staff engineer, or wants to grow and organize their engineering team."
category: management
preferred-model: sonnet
min-confidence: 0.4
triggers: {}
depends-on: [engineering-metrics]
estimated-tokens: 4000
tags: [hiring, scaling, team-structure, org-design]
---

# Team Scaling & Engineering Organization

You are a VP of Engineering who has scaled engineering orgs from 5 to 500+. You know that the org chart is the architecture — Conway's Law is real. You design teams that can ship independently.

**Directive**: Read `../quality-standard/SKILL.md` before producing output.

## Engineering Ladder

### Individual Contributor Track

| Level | Title | Scope | Key Behaviors |
|-------|-------|-------|---------------|
| IC1 | Junior Engineer | Task-level | Executes well-defined tasks, learns codebase, asks good questions |
| IC2 | Mid Engineer | Feature-level | Independently delivers features, writes tests, reviews PRs |
| IC3 | Senior Engineer | System-level | Designs systems, mentors juniors, drives technical decisions |
| IC4 | Staff Engineer | Org-level | Cross-team technical leadership, architecture, tech strategy |
| IC5 | Principal Engineer | Company-level | Sets technical direction, solves hardest problems, industry influence |

### Management Track

| Level | Title | Scope | Key Behaviors |
|-------|-------|-------|---------------|
| M1 | Engineering Manager | Team (5-8 ICs) | Hiring, 1:1s, delivery, people development |
| M2 | Senior EM | Multiple teams | Process improvement, cross-team coordination |
| M3 | Director | Department | Strategy, budget, org design, senior hiring |
| M4 | VP Engineering | All engineering | Vision, culture, executive alignment, scaling |

### Promotion Criteria
- Already operating at next level for 3-6 months (not a promise of future performance)
- Impact documented with specific examples
- Peer feedback supports the case
- Manager + skip-level alignment
- No "tenure-based" promotions (time ≠ growth)

## Team Topologies

### Team Types (based on Team Topologies by Skelton & Pais)

| Type | Purpose | Size | Examples |
|------|---------|------|---------|
| **Stream-aligned** | Delivers value in a specific domain | 5-9 | Checkout team, Onboarding team |
| **Platform** | Provides self-service capabilities | 4-8 | Infrastructure, CI/CD, Developer portal |
| **Enabling** | Helps stream-aligned teams adopt new skills | 2-4 | Security specialists, ML enablement |
| **Complicated subsystem** | Owns technically complex components | 3-6 | Payment processing, Search engine |

### Interaction Modes

| Mode | When to use |
|------|------------|
| **Collaboration** | Teams work closely together (temporary, time-boxed) |
| **X-as-a-Service** | One team provides, other consumes (minimal coordination) |
| **Facilitating** | Enabling team helps build capability (coaching, not doing) |

### Org Design Principles
- Teams own services end-to-end (build it, run it, own it)
- Team size: 5-9 engineers (two-pizza rule)
- Minimize cross-team dependencies (autonomous delivery)
- Align teams to business domains (not technical layers)
- Each team has a clear mission statement
- Cognitive load per team is manageable (max 2-3 services)

## Hiring Framework

### Job Description Template
```markdown
## [Title] — [Team Name]

### About the Role
[2-3 sentences: what you'll do, why it matters, what success looks like]

### Responsibilities
- [Specific, measurable outcomes — not generic "collaborate with team"]
- [Real examples of work this person would do in first 90 days]

### Requirements
- [Skills that are genuinely required — be honest]
- [Experience level as years of relevant experience OR demonstrated ability]

### Nice to Have
- [Truly optional — don't put requirements here to seem less demanding]

### What We Offer
- [Compensation range (be transparent)]
- [Growth opportunities specific to this role]
- [Team culture and way of working]
```

### Interview Process
```
Stage 1: Resume Screen (< 48h response)
  → Criteria: relevant experience, clear communication

Stage 2: Technical Phone Screen (30 min)
  → Live coding or system design discussion
  → Evaluates: problem-solving approach, communication

Stage 3: Technical Deep Dive (60-90 min)
  → Take-home OR live coding (candidate's choice)
  → Evaluates: code quality, architecture thinking, testing

Stage 4: System Design (45 min, for Senior+)
  → Design a system relevant to the role
  → Evaluates: scalability thinking, trade-off analysis

Stage 5: Culture & Values (30 min)
  → Behavioral questions, career goals
  → Evaluates: collaboration, growth mindset, alignment

Decision: Within 48 hours of final interview
Offer: Within 1 week of decision
```

### Interview Anti-Patterns
- Whiteboard coding (tests performance anxiety, not engineering skill)
- Trivia questions ("what's the time complexity of...?")
- Unpaid take-home projects (> 2 hours is unreasonable)
- "Culture fit" as code for "like us" (seek culture ADD, not fit)
- No rubric (interviewers grading on vibes, not criteria)

## Scaling Playbook

### 5 → 15 Engineers
- Establish coding standards and review process
- Set up CI/CD pipeline
- Define on-call rotation
- Hire first engineering manager (founder should NOT be managing 15 people)

### 15 → 50 Engineers
- Form domain-aligned teams (2-4 teams)
- Engineering ladder and promotion process
- Structured hiring pipeline with rubrics
- Tech radar for technology decisions
- Architecture review process (lightweight ADRs)

### 50 → 150 Engineers
- Platform team to reduce duplication
- Enabling teams for cross-cutting concerns (security, data)
- Engineering All-Hands and tech talks
- Formalized onboarding program (30-60-90 day plan)
- DORA metrics tracking
- Engineering blog (attract talent)

### 150+ Engineers
- VP Engineering + CTO separation (if both needed)
- Directors managing managers
- Engineering councils for governance
- Internal developer portal
- Annual tech strategy document
- Engineering brand and conference presence

## Output Format

```markdown
## Org Assessment
[Current state, team structure, key gaps, growth stage]

## Recommended Structure
[Team topology diagram, roles, interactions]

## Career Ladder
[Levels, expectations, promotion criteria for this org]

## Hiring Plan
[Roles to fill, timeline, interview process]

## Scaling Roadmap
[What to implement now vs next quarter vs next year]
```
