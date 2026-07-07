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
├── docs/          # Documentation, ADRs, runbooks
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

## Decisions

See [docs/adr/](docs/adr/) for architecture decisions.

## Lessons

See [docs/lessons/](docs/lessons/) for things learned the hard way.

## Status

- Created: {date}
- Last meaningful update: {date}
- Active / Archived / Abandoned
