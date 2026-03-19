# LINKEDIN POST — ENGLISH

---

OpenAI published an experiment where 1 million lines of code were written 100% by AI in 5 months.

The most important insight wasn't the speed.

It was that a giant AGENTS.md doesn't work. Agents ignore it. It's expensive in context. Impossible to maintain.

The turning point came when they treated the entire repository as a system of record for agents: distributed docs, versioned specs, codified architecture, quality rules as linters.

The "source of truth" shifted from the code itself to the ecosystem around it.

I reached the same conclusion from a different path.

I spent months building skills for Claude Code — not prompts, skills. Specialized files the model loads automatically based on context.

I started with one big SKILL.md. Same problem OpenAI had: expensive, ignored, too generic.

So I refactored with progressive disclosure: main skill at ~100 lines + 21 reference files that load on demand. The model reads the minimum needed and goes deep only when required.

Result: 24 skills covering code review, clean architecture, SOLID, TDD, pentest, Terraform, observability, sprint planning, postmortems.

10,000 lines of technical knowledge that Claude applies on its own. Without me writing a single prompt.

Packaged it as an open source plugin and submitted to Anthropic's official marketplace.

The lesson is the same one OpenAI learned: the future isn't writing better prompts. It's building the ecosystem that makes the agent think better.

If you're still writing manual prompts for every task, you're solving the wrong problem.

Link in comments.

#ClaudeCode #Anthropic #AI #OpenSource #AgenticAI

---

# FIRST COMMENT

CTO Toolkit — 24 skills for Claude Code

github.com/camilooscargbaptista/cto-toolkit

To install:
git clone https://github.com/camilooscargbaptista/cto-toolkit.git
claude --plugin-dir ./cto-toolkit

All skills detailed: girardellitecnologia.com/plugins/cto-toolkit.html

The OpenAI experiment (Harness Engineering): openai.com/index/harness-engineering
