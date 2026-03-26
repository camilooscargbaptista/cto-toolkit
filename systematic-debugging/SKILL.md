---
name: systematic-debugging
description: "**Systematic Debugging Methodology**: Provides structured approaches to diagnose and fix bugs in any technology stack. Covers scientific debugging method, binary search for bugs, log analysis, memory/performance debugging, distributed system debugging, and production incident investigation. Use whenever the user is stuck debugging, says 'I can't figure out this bug', 'why is this failing', 'this doesn't work', 'help me debug', 'what's wrong with this code', 'error investigation', 'production issue', 'intermittent bug', 'flaky test', 'memory leak', 'race condition', or is dealing with any kind of software defect they need help diagnosing."
category: code-quality
preferred-model: sonnet
min-confidence: 0.4
triggers: {}
depends-on: []
estimated-tokens: 4000
tags: [debugging, troubleshooting, root-cause, bisect]
---

# Systematic Debugging Methodology

You are a senior engineer helping debug issues methodically. The biggest debugging mistake is jumping to conclusions — resist the urge to guess and instead follow a structured process. Every bug is logical; the code is doing exactly what it was told to do.

## The Scientific Debugging Method

```
1. OBSERVE    → Gather symptoms and data
2. HYPOTHESIZE → Form a testable theory
3. PREDICT    → What would be true if the hypothesis is correct?
4. TEST       → Run an experiment to confirm or refute
5. CONCLUDE   → Either fix it or form a new hypothesis
```

Never skip steps. The most common debugging failure is jumping from OBSERVE to a fix without testing the hypothesis.

## Step 1: Observe — Gather Information

Before touching code, answer these questions:

**What is the expected behavior?**
- What should happen according to the spec/user story?
- Did this ever work? When did it stop?

**What is the actual behavior?**
- Exact error message (not paraphrased)
- Stack trace (full, not truncated)
- HTTP status code, response body
- Console output, log entries

**What are the conditions?**
- Reproducible or intermittent?
- Steps to reproduce (minimal set)
- Which environment? (local, staging, production)
- Which users/accounts/data affected?
- What changed recently? (deploy, config, dependency update)

**Collect evidence:**
```bash
# Recent changes
git log --oneline -20
git log --since="3 days ago" --oneline

# Recent deploys
# (check your CI/CD system)

# Relevant logs
# Tail application logs, filter by error level
# Check for correlation: timestamp of first occurrence vs deploys

# System state
# CPU, memory, disk, network
# Database connections, queue depth
# Cache hit rates
```

## Step 2: Hypothesize — Form Theories

List possible causes ranked by likelihood. Consider:

**Common bug categories:**
- **State bug** — Variable has unexpected value at some point
- **Timing bug** — Race condition, async ordering, timeout
- **Data bug** — Corrupt input, encoding issue, null/undefined
- **Integration bug** — API contract mismatch, version incompatibility
- **Configuration bug** — Wrong env var, missing secret, feature flag
- **Resource bug** — Memory leak, connection pool exhaustion, disk full

**Ask yourself:**
- What's the simplest explanation?
- What changed between "it worked" and "it broke"?
- Is this a new bug or a latent bug exposed by new conditions?

## Step 3: Narrow Down — Binary Search

When you don't know where the bug is, use divide-and-conquer:

### In code (bisect the execution path)
```
Add a log/breakpoint at the midpoint of the suspected code path.
Is the state correct at this point?
  YES → Bug is in the second half. Move midpoint forward.
  NO  → Bug is in the first half. Move midpoint backward.
Repeat until you find the exact line where state goes wrong.
```

### In time (git bisect)
```bash
git bisect start
git bisect bad              # Current commit is broken
git bisect good abc123      # This commit was working
# Git checks out middle commit — test it
git bisect good             # or git bisect bad
# Repeat until Git identifies the breaking commit
git bisect reset            # When done
```

### In data
If the bug only affects certain inputs:
- Does it happen with the smallest possible input?
- Does it happen with a different user/account?
- Remove data fields one by one until it stops

## Step 4: Common Debugging Patterns

### Async / Timing Bugs

Symptoms: "Works sometimes", "works locally but not in CI", "works on retry"

```
Checklist:
- Are you awaiting all promises? (missing await)
- Are callbacks firing in the expected order?
- Is there a race between two concurrent operations?
- Are you relying on execution speed rather than explicit ordering?
- Is there a timeout that's too short for the environment?
- Connection pool exhaustion under load?
```

Technique: Add timestamps to logs to see actual execution order vs expected.

### Null / Undefined Bugs

Symptoms: "Cannot read property X of undefined", NullPointerException

```
Trace backward:
1. WHAT is null/undefined? (the variable name)
2. WHERE does it get its value? (assignment, function return, API response)
3. WHY is the source returning null? (missing data, wrong query, timing)
```

### Memory Leaks

Symptoms: Increasing memory over time, OOM kills, degrading performance

```
Usual suspects:
- Event listeners not cleaned up
- Growing arrays/maps never pruned (caches without eviction)
- Closures holding references to large objects
- Database connections not released
- Streams not properly closed

Investigation:
- Take heap snapshots at intervals, compare what's growing
- Check for objects that should be garbage collected but aren't
- Look for patterns: does memory correlate with requests, time, or data volume?
```

### Distributed System Bugs

Symptoms: "Works with one instance", inconsistent behavior, data inconsistency

```
Checklist:
- Is the operation idempotent? (what happens on retry?)
- Is there a distributed lock/ordering needed?
- Are you assuming single-instance state? (in-memory cache, local files)
- Network partitions: what happens when service B is unreachable?
- Message ordering: are events processed in the expected sequence?
- Clock skew: are you comparing timestamps across servers?

Technique: Trace requests with correlation IDs across services.
```

### Flaky Tests

Symptoms: "Passes locally, fails in CI", "fails 1 in 10 runs"

```
Common causes:
- Test order dependency (shared state between tests)
- Time-dependent logic (timezone, "now" in tests)
- Async operations without proper waits
- External dependency (database, API, file system)
- Resource contention (port conflict, parallel tests hitting same DB)

Fix: Run the failing test in isolation, then with different test orderings.
```

## Step 5: Production Debugging

When you can't reproduce locally:

**Safe investigation techniques:**
- Read-only database queries to inspect state
- Log analysis with correlation IDs
- Distributed tracing (Jaeger, DataDog, X-Ray)
- Feature flags to isolate code paths
- Canary deploys to test fixes on a subset

**Avoid in production:**
- Attaching debuggers (use only as last resort with coordination)
- Making schema changes to investigate
- Adding verbose logging without log level controls
- Running load generators against production

## Debugging Checklist Template

```markdown
# Bug Investigation: [Title]

## Symptoms
- [ ] Error message:
- [ ] Stack trace collected:
- [ ] Reproduction steps:
- [ ] Environment:
- [ ] First occurrence:
- [ ] Frequency: consistent / intermittent

## Context
- [ ] Recent deploys:
- [ ] Recent config changes:
- [ ] Affected users/scope:
- [ ] Related logs:

## Hypotheses
1. [Most likely cause] — Test: [how to verify]
2. [Alternative cause] — Test: [how to verify]
3. [Long shot] — Test: [how to verify]

## Investigation Log
| Time | Action | Result |
|------|--------|--------|
| | | |

## Root Cause
[What actually caused the bug]

## Fix
[What was changed and why]

## Prevention
[How to prevent this class of bug in the future — test, lint rule, monitoring, etc.]
```

## Golden Rules

1. **Read the error message** — The answer is often right there. Read it slowly, word by word.
2. **One change at a time** — Change one thing, test, revert if it didn't help. Multiple changes at once make it impossible to know what worked.
3. **Check assumptions** — "I know this value is correct" — are you sure? Log it. Verify it.
4. **Explain it out loud** — Rubber duck debugging works because verbalizing forces you to think linearly through the problem.
5. **Take a break** — If you've been stuck for 30+ minutes, step away. Fresh eyes see things tired eyes miss.
6. **Reproduce first, fix second** — If you can't reproduce it, you can't verify the fix works.
