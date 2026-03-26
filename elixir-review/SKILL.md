---
name: elixir-review
description: "Review Elixir/Phoenix code: OTP patterns, GenServer, LiveView, fault tolerance and concurrency"
triggers:
  frameworks: [phoenix, ecto, otp]
  file-patterns: ["**/*.ex", "**/*.exs"]
preferred-model: sonnet
min-confidence: 0.4
depends-on: []
category: code-quality
estimated-tokens: 5000
tags: [elixir, phoenix, otp, erlang]
---

# Elixir / Phoenix Code Review

## When to Use
- Reviewing Elixir code (Phoenix, OTP, GenServer, LiveView)
- Evaluating fault tolerance patterns (supervision trees)
- Real-time system review (WebSocket, PubSub)
- Concurrency and scalability assessment

## Review Checklist

### OTP Patterns
- [ ] Supervision trees properly structured (one_for_one, rest_for_one)
- [ ] GenServers have clear purpose (not catch-all)
- [ ] `handle_info` handles unexpected messages gracefully
- [ ] Timeouts configured for long-running GenServers
- [ ] Process registry used (not PID passing)
- [ ] ETS tables for read-heavy shared state

### Phoenix Best Practices
- [ ] Contexts separate business logic from web layer
- [ ] Schemas define changesets with validation
- [ ] Controllers are thin (delegate to context)
- [ ] Plugs for cross-cutting concerns (auth, logging)
- [ ] Ecto queries composed (not raw SQL unless necessary)
- [ ] Background jobs via Oban (not raw Task.async)

### Phoenix LiveView
- [ ] `handle_event` functions are small and focused
- [ ] `assign` used for all state (no process dictionary)
- [ ] `phx-throttle`/`phx-debounce` on frequent events
- [ ] PubSub for real-time updates across users
- [ ] Dead views implement `mount/3` with proper assigns
- [ ] `live_redirect` vs `push_patch` used correctly

### Elixir Best Practices
- [ ] Pattern matching over if/else chains
- [ ] Pipe operator (`|>`) for data transformations
- [ ] `with` for multi-step operations with error handling
- [ ] `@spec` type specs on public functions
- [ ] `@doc` documentation on public functions
- [ ] Structs for domain entities (not naked maps)
- [ ] Guards for function clause selection
- [ ] `Enum` and `Stream` used appropriately (eager vs lazy)

### Concurrency
- [ ] Tasks supervised (not fire-and-forget)
- [ ] GenServer state doesn't grow unbounded
- [ ] Message queue monitored (Process.info for mailbox)
- [ ] Backpressure implemented for high-throughput
- [ ] Database connection pool sized correctly

### Fault Tolerance
- [ ] "Let it crash" — supervisors restart failed processes
- [ ] Circuit breakers for external service calls
- [ ] Fallback strategies for degraded service
- [ ] Health checks for supervised processes

## Output Format
```markdown
## Elixir Review: [Module]
**Health Score**: X/10
### Issues | Improvements | OTP Notes
```
