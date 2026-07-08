---
tags: [home, moc]
aliases: [Master Build Guide, Start Here]
---

# MiniFW — Master Build Guide

> **Hardware:** 2014 Mac Mini · 16 GB RAM · 256 GB HDD  
> **ISP:** Google Fiber · **Wi-Fi:** TP-Link Deco XE75  
> **Goal:** Mac Mini replaces Google Fiber Network Box as firewall/router

This is the **start page** for the Obsidian vault. Follow the phases in order. Each step links to a detailed note.

---

## Quick path (TL;DR)

1. [[Phase 0 - Before You Start]] — buy parts, photo wiring, prep rollback kit
2. [[Phase 1 - Install Ubuntu]] — boot from Ubuntu USB, install Server 24.04
3. [[Phase 2 - MINIFWSETUP USB]] — build stick on laptop, run `sudo ./setup.sh` on Mac Mini
4. [[Phase 3 - Pre-Cutover Testing]] — prove Mac Mini works **before** touching Fiber Jack
5. [[Phase 4 - Cutover]] — unplug Network Box, wire Fiber Jack → Mac Mini
6. [[Phase 5 - Post-Cutover]] — harden, label cables, reboot test
7. [[Phase 6 - Maintenance]] — monthly tasks

**Internet down?** → [[Triage - Internet Down]] · **Need to undo everything?** → [[Backup and Rollback]]

---

## Build phases

### [[Phase 0 - Before You Start]]
Shopping list, photograph wiring, save offline docs, prepare rollback kit.  
⏱ ~30 min · **Do not skip**

### [[Phase 1 - Install Ubuntu]]
Flash Ubuntu Server 24.04 USB, install on Mac Mini, temporary internet via Network Box.  
⏱ ~1–2 hours

### [[Phase 2 - MINIFWSETUP USB]]
Create the [[MINIFWSETUP USB]] — one Terminal paste on your Mac.  
⏱ ~30 sec · Then plug into firewall Mac Mini → `sudo ./setup.sh`

### [[Phase 3 - Pre-Cutover Testing]]
Mac Mini on test subnet while Network Box still runs house internet. Run [[Preflight Checklist]].  
⏱ ~30 min · **Gate: all checks must pass**

### [[Phase 4 - Cutover]]
Disconnect Network Box. Fiber Jack → Mac Mini WAN. Deco in AP mode.  
⏱ ~15 min · **Schedule 1 hour window**

### [[Phase 5 - Post-Cutover]]
Reserve Deco IP, disable bloat, reboot test, label cables.  
⏱ ~30 min

### [[Phase 6 - Maintenance]]
Monthly updates, quarterly rollback kit check.  
⏱ ongoing

---

## Network reference

| Topic | Note |
|-------|------|
| Full topology | [[Topology Overview]] |
| Your ISP setup | [[Google Fiber and Deco XE75]] |
| IP addresses | [[IP Address Plan]] |

```
Fiber Jack → Mac Mini WAN (USB Ethernet)
                 ↓
            Mac Mini LAN → Switch → Deco XE75 (AP mode) + devices
```

See [[Google Fiber and Deco XE75]] for wiring photos and LED meanings.

---

## Operations (when things go wrong)

| Situation | Open this |
|-----------|-----------|
| Internet down, no AI help | [[Triage - Internet Down]] |
| Need old setup back in 5 min | [[Backup and Rollback]] |
| One-screen emergency steps | [[Emergency Card]] |
| Stuck 15+ min during cutover | [[Backup and Rollback#Rollback procedure (5 minutes)]] |

**Google Fiber support:** 1-866-777-7550 (use cellular)

---

## Reference

| Topic | Note |
|-------|------|
| `minifw` CLI | [[minifw Commands]] |
| netplan, firewall.yaml | [[Config Files]] |
| USB stick contents | [[MINIFWSETUP USB]] |
| Vet checklist | [[Preflight Checklist]] |

---

## Abort rule

Rollback immediately if after **15 minutes** you still have no internet:

→ [[Backup and Rollback]]

Rollback is not failure. It restores service while you debug with keyboard + monitor.

---

## Vault map

```
Home (you are here)
├── Build/
│   ├── Phase 0 – Before You Start
│   ├── Phase 1 – Install Ubuntu
│   ├── Phase 2 – MINIFWSETUP USB
│   ├── Phase 3 – Pre-Cutover Testing
│   ├── Phase 4 – Cutover
│   ├── Phase 5 – Post-Cutover
│   └── Phase 6 – Maintenance
├── Network/
│   ├── Topology Overview
│   └── Google Fiber and Deco XE75
├── Operations/
│   ├── Backup and Rollback
│   ├── Triage - Internet Down
│   └── Emergency Card
└── Reference/
    ├── MINIFWSETUP USB
    ├── Preflight Checklist
    ├── IP Address Plan
    ├── minifw Commands
    └── Config Files
```

**Open this folder in Obsidian:** `mac-mini-firewall/obsidian/`
