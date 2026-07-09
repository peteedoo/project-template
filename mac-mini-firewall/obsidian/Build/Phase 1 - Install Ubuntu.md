---
tags: [build, phase-1]
---

# Phase 1 — Install Ubuntu

← [[Phase 0 - Before You Start]] · [[Home]] · Next → [[Phase 2 - MINIFWSETUP USB]]

⏱ ~1–2 hours

---

## 1.1 Create Ubuntu install USB

1. Download [Ubuntu Server 24.04 LTS](https://ubuntu.com/download/server)
2. Flash with [balenaEtcher](https://etcher.balena.io) (Mac/Windows) or `dd` (Linux)
3. Plug into Mac Mini, hold **Option** at boot, select USB drive

---

## 1.2 Install options

| Setting | Value |
|---------|-------|
| Hostname | `mac-mini-fw` |
| Username | your choice (e.g. `admin`) |
| Install OpenSSH | **Yes** |
| Disk | Use entire 256 GB HDD |
| Wi-Fi | Skip |

---

## 1.3 Temporary internet (before cutover)

**Recommended — Option A:** Plug Mac Mini **built-in Ethernet** into **Network Box blue LAN port**. Mac Mini gets internet from Network Box while you configure. House internet unchanged.

**Option B:** Keyboard + monitor only; finish networking at [[Phase 4 - Cutover]].

---

## 1.4 Update system

```bash
sudo apt update && sudo apt upgrade -y
sudo reboot
```

---

## Done when

- [ ] Ubuntu Server 24.04 installed
- [ ] Can login (console or SSH)
- [ ] System updated and rebooted

→ Continue to [[Phase 2 - MINIFWSETUP USB]]
