---
name: adr
description: "**Architecture Decision Record (ADR) — Philosophy-First**: Creates well-structured ADRs using a 3-phase process: (1) Define the architectural philosophy and identity of the system, (2) Explore options through the lens of that philosophy, (3) Adversarial review by a devil's advocate agent. Use this skill whenever the user wants to document a technical decision, create an ADR, record why a technology or approach was chosen, compare architectural alternatives, or mentions 'ADR', 'architecture decision', 'decision record', 'technical decision', 'why did we choose', or 'document this decision'. Also trigger when the user is evaluating trade-offs between technical approaches and wants to formalize the reasoning."
triggers:
  anti-patterns: [undocumented_decisions]
  score-below: 70
preferred-model: opus
min-confidence: 0.4
depends-on: [design-patterns]
category: architecture
estimated-tokens: 8000
tags: [adr, decisions, architecture]
---

# Architecture Decision Record (ADR) — Philosophy-First

ADRs capture the context, reasoning, and consequences of significant technical decisions. They serve as institutional memory — when someone asks "why did we do it this way?" six months from now, the ADR has the answer.

**This skill uses a 3-phase process** inspired by the canvas-design principle: define the vision before the implementation. Every architectural decision should align with a declared architectural identity, not just solve an immediate problem.

## When to Write an ADR

An ADR is warranted when:
- Choosing between frameworks, libraries, or services
- Defining API contracts or data models
- Deciding on infrastructure or deployment strategy
- Changing architectural patterns (monolith → microservices, REST → GraphQL, etc.)
- Making decisions that are costly to reverse
- Any decision where the team debated multiple options

---

## Phase 1: Architectural Identity (Philosophy-First)

**Before any technical decision, define what the system MUST BE.**

This is the most important phase. Most teams skip it and jump to "should we use X or Y?" without first answering "what kind of system are we building?" The Architectural Identity is the compass that guides all decisions.

### Architectural Identity Template

```markdown
# Architectural Identity: [System Name]

## Quality Attributes (ranked by priority)
1. [Most important] — e.g., "Reliability: 99.99% uptime, zero data loss"
2. [Second] — e.g., "Security: SOC2 compliant, zero trust"
3. [Third] — e.g., "Developer Velocity: <15min deploy, <5min local setup"
4. [Fourth] — e.g., "Scalability: handle 10x current load without re-architecture"
5. [Fifth] — e.g., "Cost Efficiency: <$X/month cloud spend"

## Trade-off Declaration
"When [quality A] conflicts with [quality B], we choose [A]."
- "When reliability conflicts with velocity, we choose reliability."
- "When cost conflicts with developer experience, we choose developer experience."

## Non-Negotiables (hard constraints)
- [Constraint 1] — e.g., "All data at rest must be encrypted (AES-256)"
- [Constraint 2] — e.g., "No vendor lock-in on core business logic"
- [Constraint 3] — e.g., "All changes must be deployable independently"

## Architectural Style
[Describe in one paragraph the architectural vision]
Example: "A modular monolith with clear domain boundaries, designed to be split into services only when team scaling demands it. Event-driven communication between modules via internal event bus, with synchronous APIs only at the edge."
```

**Why Phase 1 matters:** Without a declared identity, teams make contradictory decisions. One team member optimizes for performance, another for developer experience, a third for cost. The identity aligns everyone before the debate starts.

---

## Phase 2: Decision Exploration

With the Architectural Identity as the lens, explore options systematically.

### ADR Template (Philosophy-Aligned)

```markdown
# ADR-[NUMBER]: [TITLE — short, noun-phrase describing the decision]

## Status
[Proposed | Accepted | Deprecated | Superseded by ADR-XXX]

## Date
[YYYY-MM-DD]

## Architectural Identity Alignment
[Reference the quality attributes and trade-offs from Phase 1 that are relevant to this decision. This forces the author to connect every decision to the declared philosophy.]

- **Primary quality attribute:** [Which of the top 5 is most relevant here?]
- **Trade-off activated:** [Which trade-off declaration applies?]
- **Non-negotiables:** [Which hard constraints affect this decision?]

## Context
[Describe the situation that motivates this decision. What problem are we facing?
What constraints exist? What forces are at play (technical, business, team)?
Be specific — include numbers, metrics, team size, timeline pressures.
This section should be understandable by someone who wasn't in the room.]

## Decision
[State the decision clearly and concisely. Use active voice:
"We will use PostgreSQL as our primary database."
Not: "It was decided that PostgreSQL would be used."]

## Decision Matrix

Score each alternative against the quality attributes from the Architectural Identity (1-5):

| Criteria (from Identity) | Alternative A | Alternative B | Alternative C |
|--------------------------|:---:|:---:|:---:|
| [Quality Attribute 1] | X | X | X |
| [Quality Attribute 2] | X | X | X |
| [Quality Attribute 3] | X | X | X |
| Non-negotiable compliance | ✓/✗ | ✓/✗ | ✓/✗ |
| **Weighted Total** | | | |

## Alternatives Considered

### [Alternative A — the chosen one]
- **Alignment with identity**: [How does this serve the declared quality attributes?]
- **Pros**: ...
- **Cons**: ...

### [Alternative B]
- **Alignment with identity**: [How does this serve/conflict with quality attributes?]
- **Pros**: ...
- **Cons**: ...
- **Why not**: [Specific reason tied to the Architectural Identity]

### [Alternative C]
- **Alignment with identity**: ...
- **Pros**: ...
- **Cons**: ...
- **Why not**: [Specific reason tied to the Architectural Identity]

## Consequences

### Positive
- [What becomes easier or better — tied to quality attributes]

### Negative
- [What becomes harder or worse — be honest about trade-offs]

### Risks
- [What could go wrong and how we'll mitigate it]

## Phase 3 Review
[This section is filled by the Adversarial Review Agent]

## References
- [Links to relevant docs, benchmarks, discussions, RFCs]
```

---

## Phase 3: Adversarial Review

After the ADR is drafted (Phases 1-2), invoke the **adversarial-reviewer** agent to challenge the decision.

The adversarial reviewer will:
1. **Challenge the Architectural Identity alignment** — Does the decision actually serve the declared quality attributes, or is the author rationalizing?
2. **Play devil's advocate** — What's the strongest case for the rejected alternatives?
3. **Stress-test the consequences** — Are the negative consequences understated? Are there hidden risks?
4. **Check for bias** — Is the author choosing a familiar technology over a better one? Is there anchoring bias?
5. **Validate the Decision Matrix** — Are the scores defensible? Would a different weighting change the outcome?

The output of Phase 3 goes in the "Phase 3 Review" section of the ADR.

**To invoke Phase 3:** Use the `adversarial-reviewer` agent with the drafted ADR as context.

---

## Writing Guidelines

- **Define the identity first.** If the project doesn't have an Architectural Identity document, create one before writing any ADR. It takes 30 minutes and saves hundreds of hours of debate.

- **Be honest about trade-offs.** Every decision has downsides. If the ADR doesn't mention any, it's incomplete. A decision with no downsides is a sign that alternatives weren't seriously evaluated.

- **Include the "why not" for rejected alternatives.** This is the most valuable part of the ADR — it prevents future teams from re-evaluating options that were already considered.

- **Tie every "why" to the identity.** "We chose X because it scores highest on our #1 quality attribute (reliability)" is infinitely better than "We chose X because it's better."

- **Quantify when possible.** "Better performance" is vague. "Reduced p99 latency from 450ms to 120ms in our benchmark" is useful. Include benchmark data, cost projections, or capacity estimates when available.

- **Write for the future reader.** Assume they have general technical knowledge but no context about your current project state. Spell out acronyms on first use, link to relevant docs.

- **Keep the scope tight.** One ADR per decision. If you're documenting multiple related decisions, write multiple ADRs and cross-reference them.

## Naming Convention

Save ADRs as: `docs/adr/NNNN-short-title.md`

Number sequentially (0001, 0002, ...). The title should be a concise noun phrase: "postgresql-as-primary-database", "event-driven-architecture-for-notifications".

Save the Architectural Identity as: `docs/adr/0000-architectural-identity.md`
