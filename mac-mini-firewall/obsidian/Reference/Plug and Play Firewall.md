---
tags: [reference, workflow, plug-and-play]
aliases: [Auto USB, Plug and Play]
---

# Plug and Play Firewall

← [[Home]] · [[MINIFWSETUP USB]] · [[Phase 2 - MINIFWSETUP USB]]

Your Mac Mini is a **firewall appliance**, not a general-purpose server. This workflow treats it like one: plug in the USB, it configures itself.

---

## The workflow

```
1. Build MINIFWSETUP stick (one paste on your Mac laptop)
2. Install Ubuntu on the firewall Mac Mini (one time)
3. Enable USB watcher (one paste — see below)
4. Plug MINIFWSETUP → firewall auto-runs setup
5. Cut over from Network Box → [[Phase 4 - Cutover]]
6. Anytime later: plug USB again → update/repair mode
```

---

## One-time: enable auto-run on the firewall

After Ubuntu is installed on the **firewall Mac Mini**, run once:

```bash
curl -fsSL https://raw.githubusercontent.com/peteedoo/project-template/cursor/mac-mini-firewall-2baf/mac-mini-firewall/scripts/install-usb-watcher.sh | sudo bash
```

Or from the USB:

```bash
sudo bash /mnt/minifwsetup/install-usb-watcher.sh
```

---

## What happens when you plug in

| Situation | Auto behavior |
|-----------|---------------|
| First plug (not configured) | Full [[Phase 2 - MINIFWSETUP USB|setup]] |
| Already a firewall | **Update mode** — refresh docs, `minifw apply`, preflight |
| Keyboard + monitor attached | Prompts: "Run setup? [Y/n]" |
| Headless (no keyboard) | Waits 15s, then continues automatically |

Watch logs:

```bash
journalctl -t minifw-usb -f
```

Skip all prompts (fully unattended):

```bash
echo 'MINIFW_NO_PROMPT=1' | sudo tee -a /etc/environment
```

---

## What this is NOT

| Not this | Because |
|----------|---------|
| A file server | It's a firewall/router only |
| Auto on macOS | Plug-and-play watcher runs on **Ubuntu on the firewall Mac Mini** |
| Auto on first Ubuntu install | Watcher needs one-time install (above) |

macOS cannot auto-run USB scripts (security). Your **M4 Mac** builds the stick; the **firewall Mac Mini** runs it.

---

## After first setup

`setup.sh` installs the watcher automatically (step 8). Future plugs just work.

---

## Related

- [[MINIFWSETUP USB]]
- [[Phase 1 - Install Ubuntu]]
- [[Phase 4 - Cutover]]
- [[Backup and Rollback]]
