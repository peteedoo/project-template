---
name: write-adr
description: Write a new ADR when a non-trivial or hard-to-reverse decision is made. Use for architecture, workflow, tooling, or policy decisions that should persist in docs/adr.
---

# Write ADR

Create a new Architecture Decision Record in `docs/adr/` when a decision has meaningful long-term impact.

## Trigger conditions

Use this skill when a change:

- Alters architecture or project workflow.
- Introduces durable tooling conventions.
- Has significant tradeoffs or potential lock-in.
- Is difficult to reverse later.

## Procedure

1. Read `docs/adr/000-template.md`.
2. Find the next ADR number (e.g., `002-*`).
3. Create `docs/adr/<NNN>-<short-kebab-title>.md`.
4. Fill sections: Context, Decision, Consequences, Alternatives Considered (if relevant).
5. Keep rationale concrete and specific to this repository.

## Content requirements

- State the problem being solved.
- Explain why this option was selected.
- Record costs/downsides, not only benefits.
- Reference related files/commands if useful.

## Completion check

- ADR file exists with correct numbering.
- Template fields are fully populated.
- Language is clear enough for future maintainers.
