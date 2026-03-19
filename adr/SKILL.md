---
name: adr
description: "**Architecture Decision Record (ADR)**: Creates well-structured ADRs to document technical decisions, their context, and consequences. Use this skill whenever the user wants to document a technical decision, create an ADR, record why a technology or approach was chosen, compare architectural alternatives, or mentions 'ADR', 'architecture decision', 'decision record', 'technical decision', 'why did we choose', or 'document this decision'. Also trigger when the user is evaluating trade-offs between technical approaches and wants to formalize the reasoning."
---

# Architecture Decision Record (ADR)

ADRs capture the context, reasoning, and consequences of significant technical decisions. They serve as institutional memory — when someone asks "why did we do it this way?" six months from now, the ADR has the answer.

## When to Write an ADR

An ADR is warranted when:
- Choosing between frameworks, libraries, or services
- Defining API contracts or data models
- Deciding on infrastructure or deployment strategy
- Changing architectural patterns (monolith → microservices, REST → GraphQL, etc.)
- Making decisions that are costly to reverse
- Any decision where the team debated multiple options

## ADR Template

Use this structure (based on Michael Nygard's format, the industry standard):

```markdown
# ADR-[NUMBER]: [TITLE — short, noun-phrase describing the decision]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Date
[YYYY-MM-DD]

## Context
[Describe the situation that motivates this decision. What problem are we facing?
What constraints exist? What forces are at play (technical, business, team)?
Be specific — include numbers, metrics, team size, timeline pressures.
This section should be understandable by someone who wasn't in the room.]

## Decision
[State the decision clearly and concisely. Use active voice:
"We will use PostgreSQL as our primary database."
Not: "It was decided that PostgreSQL would be used."]

## Alternatives Considered

### [Alternative A]
- **Pros**: ...
- **Cons**: ...
- **Why not**: [specific reason this was rejected]

### [Alternative B]
- **Pros**: ...
- **Cons**: ...
- **Why not**: [specific reason this was rejected]

## Consequences

### Positive
- [What becomes easier or better]

### Negative
- [What becomes harder or worse — be honest about trade-offs]

### Risks
- [What could go wrong and how we'll mitigate it]

## References
- [Links to relevant docs, benchmarks, discussions, RFCs]
```

## Writing Guidelines

- **Be honest about trade-offs.** Every decision has downsides. If the ADR doesn't mention any, it's incomplete. A decision with no downsides is a sign that alternatives weren't seriously evaluated.

- **Include the "why not" for rejected alternatives.** This is the most valuable part of the ADR — it prevents future teams from re-evaluating options that were already considered.

- **Quantify when possible.** "Better performance" is vague. "Reduced p99 latency from 450ms to 120ms in our benchmark" is useful. Include benchmark data, cost projections, or capacity estimates when available.

- **Write for the future reader.** Assume they have general technical knowledge but no context about your current project state. Spell out acronyms on first use, link to relevant docs.

- **Keep the scope tight.** One ADR per decision. If you're documenting multiple related decisions, write multiple ADRs and cross-reference them.

## Naming Convention

Save ADRs as: `docs/adr/NNNN-short-title.md`

Number sequentially (0001, 0002, ...). The title should be a concise noun phrase: "postgresql-as-primary-database", "event-driven-architecture-for-notifications".
