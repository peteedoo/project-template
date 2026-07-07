# ADR-002: Adopt Agent Skills in Project Template

**Status:** Accepted
**Date:** 2026-07-07

## Context

This repository is used as the template for new projects. Today it includes
project conventions in prose (README, ADR templates, lessons template), but
does not include reusable operational guidance for AI coding agents.

As a result, agent behavior can be inconsistent across projects created from
this template. Valuable workflows (reading prior ADRs before design changes,
recording new ADRs for durable decisions, and logging lessons learned) are not
actively reinforced.

The `davidondrej/skills` repository provides an MIT-licensed catalog of Agent
Skills (`SKILL.md` files) that can be adapted into this template.

## Decision

Adopt a curated `.agents/skills/` library in this template repository.

Specifically:

1. Add adapted, general-purpose skills from `davidondrej/skills`:
   - `effective-agent-skills`
   - `read-all-adrs`
   - `brain-to-docs`
   - `handoff`
2. Add project-specific skills:
   - `write-adr`
   - `write-lesson`
3. Record source attribution and license context in
   `.agents/skills/ATTRIBUTIONS.md`.
4. Document `.agents/` in the README structure.

We choose `.agents/skills/` (rather than `.cursor/skills/`) as the canonical
location because it is a cross-tool convention and works across multiple
agent environments while still being repository-local.

## Consequences

**Easier:**
- New projects created from the template inherit consistent agent workflows.
- Decision-quality improves because ADR context is explicitly surfaced.
- Hard-won lessons are more likely to be captured and reused.
- Skills remain version-controlled alongside project code.

**Harder:**
- Additional maintenance overhead for skill docs over time.
- Imported skills must be periodically reviewed for relevance.
- Poorly written skills could misroute behavior if descriptions degrade.

## Alternatives Considered

- **No skills; rely on ad hoc prompts:** low setup effort, but inconsistent
  behavior and no reusable process discipline.
- **Vendor entire upstream skills catalog:** faster import, but pulls in many
  tool-specific skills that do not match this template's environment.
- **Use `.cursor/skills/` only:** works in Cursor but is less tool-neutral than
  `.agents/skills/` for cross-agent reuse.
