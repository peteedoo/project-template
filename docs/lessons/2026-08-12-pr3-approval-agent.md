# Lesson: PR #3 approval with Bugbot absent

**Date:** 2026-08-12
**Context:** Cursor Approval Agent run on https://github.com/peteedoo/project-template/pull/3 (`cursor/adopt-agent-skills-e446` → `main`).
**What happened:** Approved. Cursor Bugbot check was not present after the first poll; signal skipped. No `APPROVAL_POLICY.md`, `./cursor/approval-policies/ROUTING.md`, or `./cursor/approvals/` files on main or the PR branch. No prior approving reviews. No reviewers assigned. Slack tool unavailable (skipped).
**Root cause:** N/A — policy-driven approve when Bugbot is absent (skipped) and no tighter local approval policy applies.
**Fix / takeaway:** Large skill-library PRs may land without Bugbot; consider wiring Bugbot or directory `APPROVAL_POLICY.md` if human gate is desired for workflow/script additions.
**Reference:** https://github.com/peteedoo/project-template/pull/3
