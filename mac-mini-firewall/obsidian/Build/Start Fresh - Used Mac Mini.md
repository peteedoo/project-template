---
tags: [build, phase-1, used-hardware]
aliases: [Factory Reset, Wipe Mac Mini, Pawn Shop Mac]
---

# Start Fresh — Used Mac Mini

← [[Home]] · Next → [[Phase 1 - Install Ubuntu]]

You bought a Mac Mini with someone else's account still on it. **Don't try to log into their account.** Wipe the drive and install Ubuntu for the firewall.

---

## What you're doing

| Don't | Do |
|-------|-----|
| Guess their password | Erase the entire drive |
| "Clean up" their macOS user | Install Ubuntu Server (fresh OS) |
| Use macOS as the firewall | Ubuntu + MiniFW only |

The old macOS will be **completely gone**. That's what you want.

---

## What you need

- **Ubuntu Server 24.04** on a USB stick (installer) — separate from MINIFWSETUP
- USB keyboard + HDMI monitor (or borrow for setup)
- Internet on another device to download Ubuntu

Flash Ubuntu: [balenaEtcher](https://etcher.balena.io) or [Ubuntu download](https://ubuntu.com/download/server)

---

## Step 1 — Boot from Ubuntu USB

1. Plug **Ubuntu installer USB** into the Mac Mini
2. Plug in **keyboard + monitor**
3. Power on and **hold the Option key** until you see boot drives
4. Select **EFI Boot** or the orange **Ubuntu** icon (not Macintosh HD)
5. Choose **Install Ubuntu Server**

---

## Step 2 — Erase the old user's disk

During Ubuntu install, at **Guided storage configuration**:

| Screen | Choose |
|--------|--------|
| Storage | Use entire disk (256 GB) |
| Confirm | **Yes, erase all data** — this wipes macOS and the old user |
| Partition | Default is fine |

That removes everything the pawn shop left on there.

---

## Step 3 — Install settings

| Setting | Value |
|---------|-------|
| Hostname | `mac-mini-fw` |
| Username | **your** name (new account) |
| Password | pick something you'll remember |
| OpenSSH | **Yes** (remote access later) |
| Featured snaps | Skip all |

Wait for install to finish → reboot → remove Ubuntu USB when prompted.

---

## Step 4 — First login

You should see a **text login** (Ubuntu Server has no desktop). Log in with the username/password you just created.

```bash
# Verify you're on Ubuntu, old macOS is gone
ls /
uname -a
```

---

## Optional — erase macOS only (if you want macOS back later)

Only do this if you need macOS for something else. **Not needed for the firewall.**

1. Restart, hold **Cmd + R** → Recovery
2. **Disk Utility** → select internal drive → **Erase**
3. Format: **APFS** (or Mac OS Extended if older)
4. Quit Disk Utility → **Reinstall macOS**

For MiniFW, skip this — go straight to Ubuntu.

---

## Step 5 — Continue firewall setup

1. [[MINIFWSETUP USB]] — build stick on your M4 Mac
2. [[Plug and Play Firewall]] — enable watcher, plug USB
3. [[Phase 3 - Pre-Cutover Testing]] → [[Phase 4 - Cutover]]

---

## If Option boot doesn't show Ubuntu USB

- Try a different USB port (USB 2 ports often work better on 2014 Mac Minis)
- Re-flash the Ubuntu USB
- Reset NVRAM: power off, power on, immediately hold **Option + Cmd + P + R** for 20 seconds

---

## Related

- [[Phase 1 - Install Ubuntu]]
- [[Phase 0 - Before You Start]]
- [[Home]]
