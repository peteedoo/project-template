---
name: handoff
description: Compact the current session into a single detailed handoff message that can be pasted into a fresh agent run. Use when switching context, ending a session, or avoiding context-window loss.
disable-model-invocation: true
---

# Handoff

Create one copy-paste-ready handoff block that captures:

1. Objective and scope.
2. What was completed.
3. Files changed and why.
4. Open issues/blockers.
5. Exact next steps.
6. Validation status (tests/checks run or missing).

## Format

Return a single fenced code block with clear sections:

- `Goal`
- `Completed`
- `Changed Files`
- `Decisions`
- `Outstanding Work`
- `Verification`
- `Next Command(s)` (optional)

## Quality bar

- Self-contained: no hidden assumptions.
- Concrete: include filenames and command snippets where useful.
- Actionable: next agent should continue immediately.
