# {project-name}

One-line description of what this does.

## Why

The problem this solves. Written for Future You, who will forget.

## Quick Start

```bash
# Clone and setup
git clone git@github.com:peteedoo/{project-name}.git
cd {project-name}
# ... install steps
```

## Structure

```
.
├── src/           # Source code
├── .agents/       # Agent skills and shared agent context
├── .claude/       # Claude commands and Claude-scoped skills
├── .github/       # Automation workflows (including star sync)
├── docs/          # Documentation, ADRs, runbooks, ROADMAP.md
├── scripts/       # One-off scripts and utilities
├── tests/         # Test files
└── README.md      # This file
```

## Workflow

### Start a new project

```bash
./scripts/new-project.sh my-project-name
```

Or manually:
```bash
gh repo create peteedoo/my-project-name --public --template=peteedoo/project-template --clone
```

### Conventions

- **Branches:** `feat/description`, `fix/description`, `docs/description`, `refactor/description`
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/) — `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`
- **Issues:** Every change starts with an issue. Close with `Closes #N` in the PR body.

### Auto-sync skills from GitHub stars

This template includes an automation workflow that:

1. Scans starred repositories.
2. Evaluates each repo for skill-library growth potential.
3. Imports all discovered skill folders (directories containing `SKILL.md`) into
   `.agents/skills/imported/`.
4. Writes reports under `.agents/reports/`.

Files:

- Workflow: `.github/workflows/sync-starred-skills.yml`
- Script: `scripts/sync_starred_skills.py`

Configuration options:

- `STARRED_GITHUB_USERNAME` (repo variable or manual workflow input): username
  whose public stars should be scanned.
- `STAR_SYNC_MAX_REPOS` (repo variable or manual workflow input): scan limit.
- `GH_STARS_TOKEN` (optional secret): user token for private stars or higher
  limits. If unset, workflow falls back to `github.token` for API auth and
  scans public stars for `STARRED_GITHUB_USERNAME`.
- `STAR_SYNC_USE_AUTHENTICATED_USER` (optional repo variable, `true`/`false`):
  when `true`, uses authenticated user's `/user/starred` endpoint.

The workflow runs on a daily schedule and can also be launched manually with
custom inputs.

### Job-application skill setup from fork

This template includes a dedicated sync for the AI Job Search workflow
(`MadsLorentzen/ai-job-search`) so `/setup`, `/apply`, and related Claude
commands can be installed in-project.

Files:

- Workflow: `.github/workflows/sync-ai-job-search-fork.yml`
- Script: `scripts/sync_ai_job_search_fork.py`

Synced targets:

- `.claude/commands/ai-job-search/**`
- `.claude/skills/ai-job-search/**`
- `.agents/skills/ai-job-search/**`

Recommended setup:

1. Fork upstream once:
   ```bash
   gh repo fork MadsLorentzen/ai-job-search --clone=false
   ```
2. Set repository variables:
   - `JOB_SEARCH_SKILL_SOURCE_REPO=peteedoo/ai-job-search`
   - `JOB_SEARCH_SKILL_SOURCE_REF=master`
3. Run the **Sync AI Job Search Fork** workflow manually (or wait for schedule).

This lets you customize the job-application framework in your own fork while
keeping this repo synced automatically.

## Roadmap

Copy [docs/ROADMAP.template.md](docs/ROADMAP.template.md) to `docs/ROADMAP.md` and fill it in — the ordered plan from today to steady state, with a gate on every phase.

## Decisions

See [docs/adr/](docs/adr/) for architecture decisions.

## Lessons

See [docs/lessons/](docs/lessons/) for things learned the hard way.

## Status

- Created: {date}
- Last meaningful update: {date}
- Active / Archived / Abandoned
