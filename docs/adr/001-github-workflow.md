# ADR-001: GitHub as Project Hub

**Status:** Accepted
**Date:** 2026-05-18

## Context

Projects were scattered across machines, lost during OS reinstalls, and undocumented. No consistent structure. No searchable history. Future You couldn't reconstruct what happened or why.

## Decision

Use GitHub as the single source of truth for all projects. Every project gets a repo. Every repo starts from a template with consistent structure, conventions, and documentation folders.

## Consequences

**Easier:**
- Clone anywhere, work anywhere
- Full history survives OS reinstalls
- Lessons and decisions are searchable across projects
- Issues track work instead of scattered notes

**Harder:**
- Requires internet to push/pull
- Must remember to commit and push
- Private projects need paid GitHub plan (or use private repos within free tier limits)

## Alternatives Considered

- **Local folders + Syncthing:** Survives reinstalls if synced, but no history, no issues, no search
- **Apple Notes:** Good for capture, terrible for code and structured documentation
- **Obsidian + Git:** Powerful, but higher friction than GitHub's built-in tools
