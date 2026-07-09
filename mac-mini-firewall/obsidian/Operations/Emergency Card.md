---
tags: [operations, emergency]
aliases: [INTERNET-DOWN, Rollback Card]
---

# Emergency Card

← [[Home]] · Full triage → [[Triage - Internet Down]] · Rollback → [[Backup and Rollback]]

**Print this or save to phone.** Also installed on Mac Mini at `/root/INTERNET-DOWN.txt` after [[Phase 2 - MINIFWSETUP USB]].

---

```
═══════════════════════════════════════════════════════════════════
  INTERNET DOWN — DO THIS FIRST
═══════════════════════════════════════════════════════════════════

1. Fiber Jack powered? (adapter plugged in, light on)

2. STUCK 15+ MIN? → ROLLBACK (5 minutes):
   • Unplug Mac Mini (optional)
   • Fiber Jack Ethernet → Network Box WAN (globe, LEFT port)
   • Network Box blue LAN → Deco (same as before)
   • Network Box power on → wait 3 GREEN LEDs
   • Deco app → Router mode (not AP) if no Wi-Fi

3. Google Fiber: 1-866-777-7550 (use cell data)

4. Mac Mini debug (keyboard + monitor):
   ip -br addr
   ping -c 3 1.1.1.1
   sudo minifw status

5. Full guide: Triage - Internet Down (Obsidian / /opt/minifw/docs/)

═══════════════════════════════════════════════════════════════════
```

---

## Related

- [[Backup and Rollback]]
- [[Triage - Internet Down]]
- [[MINIFWSETUP USB]]
