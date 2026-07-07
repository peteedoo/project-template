# AGENTS.md

## Cursor Cloud specific instructions

This repo is a template scaffold at the root plus one real product: **MiniFW**
(`mac-mini-firewall/`), a Python CLI (`minifw`) that generates `nftables` /
`dnsmasq` / `sysctl` config from a single YAML file. There is no web server,
database, or long-running service — the "application" is the CLI itself.

### Environment

- A Python virtualenv is created at `/workspace/.venv` by the startup update
  script (which installs the `minifw` package editable + `pytest`). Use it
  directly, e.g. `/workspace/.venv/bin/python`, `/workspace/.venv/bin/pytest`,
  or `source /workspace/.venv/bin/activate` then `minifw ...`.
- `.venv/` is gitignored.

### Test / build / run

- Tests: `cd mac-mini-firewall && /workspace/.venv/bin/python -m pytest`
  (pytest config lives in `mac-mini-firewall/pyproject.toml`).
- Lint: no linter is configured for this project; `python -m compileall src tests`
  is a reasonable syntax sanity check.
- Run the CLI (needs a config path via `--config`; the default
  `/etc/minifw/firewall.yaml` won't exist here):
  - `minifw --config <path> init` — create a starter config
  - `minifw --config <path> show` — print config
  - `minifw --config <path> render` — print the generated nftables ruleset (pure, no root)

### Non-obvious caveats

- `render`, `show`, and `init` are pure and need no root or system daemons.
- `apply`, `status`, `block`, and `allow-wan` shell out to `nft` / `sysctl` /
  `systemctl` (and `block`/`allow-wan` call `apply` internally). Those tools are
  **not installed** in this dev VM and only make sense on the real Mac Mini
  router hardware — don't expect them to work here.
- The `scripts/*.sh` files (`install.sh`, `setup.sh`, etc.) provision the physical
  firewall appliance (they `apt-get install` and need root); they are **not** for
  setting up this dev environment.
