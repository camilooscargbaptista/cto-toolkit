---
name: tech-spec
description: "**Technical Specification Document**: Creates detailed technical specs (RFCs, design docs) for features, systems, and integrations. Use this skill whenever the user wants to write a tech spec, design doc, RFC, technical proposal, system design, or API specification. Also trigger when the user says 'spec out', 'design document', 'technical plan', 'how should we build', 'system design for', or wants to plan the implementation of a feature before coding. Trigger even for informal requests like 'I need to think through how to build X' or 'help me plan the architecture for Y'."
---

# Technical Specification Document

A tech spec is the bridge between "what we want to build" and "how we'll build it." It forces clarity before code is written, surfaces risks early, and creates alignment across the team.

## Spec Structure

```markdown
# [Feature/System Name] — Technical Specification

**Author**: [Name]
**Reviewers**: [Names]
**Status**: Draft | In Review | Approved | Implemented
**Created**: [Date]
**Last Updated**: [Date]

## 1. Overview
[2-3 sentences explaining what this is and why we're building it.
Should be understandable by any engineer on the team.]

## 2. Goals & Non-Goals

### Goals
- [What this project WILL accomplish — be specific and measurable]

### Non-Goals
- [What this project explicitly WILL NOT do — prevents scope creep]

## 3. Background
[Context needed to understand the design. Current system state,
user pain points, business requirements, relevant metrics.]

## 4. Detailed Design

### 4.1 Architecture Overview
[High-level diagram or description of how components interact.
Include a Mermaid diagram when helpful.]

### 4.2 Data Model
[Database schema changes, new tables/collections, key relationships.
Show the actual schema, not just prose descriptions.]

### 4.3 API Design
[New or modified endpoints. Include request/response examples.
For internal APIs, define the interface contract.]

### 4.4 Key Algorithms / Business Logic
[Any non-trivial logic that needs careful thought.
Pseudocode or flowcharts for complex flows.]

### 4.5 Error Handling
[How failures are detected, reported, and recovered from.
What happens when external dependencies are down?]

## 5. Security Considerations
[Authentication, authorization, data encryption, input validation,
PII handling, audit logging requirements.]

## 6. Performance & Scalability
[Expected load, latency requirements, caching strategy,
database query patterns, bottleneck analysis.]

## 7. Observability
[Key metrics to track, alerting thresholds, logging strategy,
dashboards needed, SLIs/SLOs if applicable.]

## 8. Migration / Rollout Plan
[How to deploy safely. Feature flags? Gradual rollout?
Database migration strategy? Backward compatibility?
Rollback plan if things go wrong?]

## 9. Testing Strategy
[Unit test approach, integration test plan, E2E scenarios,
load testing requirements, manual QA checklist.]

## 10. Dependencies & Risks
[External service dependencies, team dependencies, timeline risks,
technical unknowns. For each risk: impact, probability, mitigation.]

## 11. Timeline & Milestones
[Rough breakdown of work phases. Not a project plan —
just enough to show the scope is reasonable.]

## 12. Open Questions
[Things that still need answers. Tag the person who can answer.]

## Appendix
[Reference materials, benchmarks, research, related specs.]
```

## Writing Principles

- **Start with the "why."** The Overview and Background should convince the reader this work matters before diving into how.

- **Be precise about interfaces.** Anywhere two systems or teams interact, define the contract explicitly. Ambiguity in interfaces becomes bugs in production.

- **Show, don't tell.** Use code snippets, schema definitions, sequence diagrams (Mermaid), and concrete examples instead of vague descriptions.

- **Address the scary parts head-on.** The sections on security, performance, and migration are where most specs are weakest — and where most production incidents originate. Give them serious thought.

- **Non-goals are as important as goals.** They prevent scope creep and set clear expectations. If something is commonly assumed to be in scope but isn't, call it out as a non-goal.

- **Open questions are a feature, not a bug.** A spec that claims to have all the answers is suspicious. List unknowns explicitly and assign owners to resolve them.

## Adapting the Template

Not every spec needs every section. For a small feature, you might skip Migration Plan and Observability. For an API-only change, you might expand API Design and shrink Architecture Overview. Use judgment — the goal is to cover what matters for this specific project, not to fill in every heading.

For quick features (1-2 day implementations), use a lightweight version with just: Overview, Goals/Non-Goals, Design, and Testing Strategy.
