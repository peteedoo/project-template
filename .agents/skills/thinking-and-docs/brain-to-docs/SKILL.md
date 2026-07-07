---
name: brain-to-docs
description: Extract project vision and decisions from a user through iterative Q&A, then convert them into clear repo documentation (README, ADRs, lessons). Use when user asks to document ideas in their head.
---

# Brain to Docs

Turn rough user intent into durable project documentation.

## Primary targets in this template

- `README.md`
- `docs/adr/`
- `docs/lessons/`

## Workflow

1. Ask focused questions one at a time (goal, users, constraints, scope).
2. Reflect back concise understanding after each answer.
3. Identify whether info belongs in README, ADR, or lesson log.
4. Propose concrete edits.
5. Apply changes incrementally and verify with the user when needed.

## Routing rules

- Use README for current state and operational conventions.
- Use ADRs for durable decisions and tradeoffs.
- Use lessons for failures/surprises and future prevention.

## Output quality bar

- Plain, specific language.
- Capture rationale, not only outcomes.
- Leave actionable next steps when information is incomplete.
