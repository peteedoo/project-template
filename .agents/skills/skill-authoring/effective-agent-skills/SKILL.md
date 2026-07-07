---
name: effective-agent-skills
description: How to write effective agent skills and debug skill routing/execution. Use when creating, editing, reviewing, or troubleshooting SKILL.md files.
---

# Effective Agent Skills

Use this guide when authoring or improving skills in this repository.

## What a skill is

A skill is a folder containing a `SKILL.md` with frontmatter and instructions.
Optional helpers can live next to it (`references/`, `scripts/`, `assets/`).

## Authoring checklist

1. Define one clear purpose for the skill.
2. Write `name` and `description` first.
3. Ensure `name` matches the containing folder name exactly.
4. Keep the main workflow in `SKILL.md`; move heavy detail to `references/`.
5. Add at least one verification loop before completion.

## Frontmatter rules

- `name`: lowercase, hyphenated, matches folder name.
- `description`: say what it does and when to use it.
- Keep frontmatter valid YAML; malformed YAML can prevent loading.

## Description guidance (routing contract)

The description is what routes the skill. Include:

- **What** the skill does.
- **When** to use it (trigger phrases/situations).
- **Differentiator** from related skills.

Avoid embedding a full workflow in the description. Keep "how" in the body.

## Writing guidance

- Prefer deterministic steps when consistency matters.
- Use concrete commands/examples rather than abstract prose.
- If behavior must be exact, encode strict step sequences.
- If behavior needs judgment, provide constraints and checkpoints.
- Make failure handling explicit ("if X fails, do Y").

## Validation loop pattern

For every significant workflow:

1. Execute.
2. Validate output/state.
3. Fix gaps.
4. Re-validate before declaring complete.

## Common anti-patterns

- Vague descriptions ("helpful for docs").
- Skills that bundle too many unrelated concerns.
- Re-teaching generic concepts the model already knows.
- Omitting failure branches and fallback behavior.
- Storing time-sensitive claims in static skill docs.

## Debugging skill behavior

- If it does not trigger: improve `description`.
- If it triggers but performs poorly: improve steps/examples in body.
- Re-test with realistic prompts that should and should not trigger.

## Security baseline

Before adopting third-party skills:

1. Read all files in the skill folder.
2. Audit scripts for unexpected network calls or destructive actions.
3. Verify provenance and license.
4. Prefer pinning to a known commit/version when importing externally.
