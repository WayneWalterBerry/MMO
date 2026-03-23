# Puzzle 031: Triage Under Pressure

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐⭐ Level 5  
**Cruelty Rating:** Tough (resource scarcity creates real dilemmas; wrong choices have lasting consequences)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — multiple simultaneous injuries, all pipeline-routed  
**New Objects Needed:** ❌ None (uses all existing injury and treatment objects)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Any area after a major hazard event (collapse, combat, multi-trap gauntlet) |
| **Objects Required** | bandage (existing), cloth (existing), wine-bottle (existing — antiseptic), well-bucket/rain-barrel (existing — burn treatment) |
| **Objects Created** | None — puzzle is pure injury management |
| **Prerequisite Puzzles** | 020 Wine Wound Wash (antiseptic knowledge), 029 Bandage Before Climb (injury gating) |
| **GOAP Compatible?** | Partial — GOAP can resolve individual treatments but can't prioritize triage order |
| **Multiple Solutions?** | Many — treatment order varies based on injury assessment |
| **Estimated Time** | 15–30 min (first-time), 5–10 min (experienced) |

---

## Real-World Logic

**Premise:** Triage — the art of prioritizing treatment when resources are scarce and multiple injuries demand attention simultaneously — is the foundation of emergency medicine. Every EMT, every combat medic, every disaster responder knows: you can't treat everything at once. You assess, prioritize, and treat the most life-threatening condition first. Bleeding stops first. Breathing is checked. Broken bones are stabilized. The common cold is ignored.

**Why it's satisfying:** The player has just survived something catastrophic — a building collapse, a multi-trap gauntlet, a disastrous fall. They're injured in multiple ways simultaneously: bleeding from a gash, burned on one arm, a crushing wound on the leg, possibly poisoned. They have limited treatment supplies. The injury system is ticking. The puzzle isn't "find the treatment" — it's **"which treatment first?"**

**What makes it real:** This is what field medics actually do. The satisfaction comes from mastering a skill that transcends gaming — reading your body's condition, assessing urgency, making hard choices about scarce resources, and getting it right.

---

## Overview

The player sustains 3–4 simultaneous injuries from a single catastrophic event or a rapid series of hazards. Each injury has different urgency:

| Injury | Urgency | Tick? | Treatment | Available? |
|--------|---------|-------|-----------|------------|
| **Bleeding (arm)** | 🔴 Critical — health drain per tick | Yes (fast) | Bandage | Limited cloth supply |
| **Burn (hand)** | 🟡 Moderate — health drain per tick (slower) | Yes (slow) | Cold water | Water source may be distant |
| **Crushing wound (leg)** | 🟡 Moderate — mobility impaired | No tick | Splint + rest | Reduces movement speed |
| **Poisoned (ingestion)** | 🔴 Critical — lethal if untreated | Yes (escalating) | Specific antidote | Antidote may not be nearby |

The player must diagnose all injuries (`EXAMINE injuries`), assess which are ticking (lethal urgency), check available supplies, and treat in the optimal order. Wrong order = more health lost. Wrong treatment = resources wasted on non-critical injuries while critical ones escalate.

---

## Solution Path

### Optimal Triage (Expert Path)
1. **Assess:** `EXAMINE injuries` — full injury report with severity and tick rates
2. **Prioritize:**
   - Bleeding is fastest tick → treat first
   - Poison is escalating → treat second (if antidote available)
   - Burn is slow tick → treat third
   - Crushing wound is non-ticking → treat last (or not at all)
3. **Execute:**
   1. `APPLY bandage TO arm` — stops bleeding tick immediately
   2. `DRINK antidote` — stops poison escalation (if antidote found)
   3. `POUR water ON hand` — cools burn (if water available)
   4. `REST` — crushing wound recovers over time
4. **Result:** Minimum health loss. All critical injuries addressed.

### Sub-Optimal but Survivable (Common Path)
1. Player treats injuries in arbitrary order
2. Treats burn before bleeding (burn is painful but slower)
3. Bleeding continues ticking while burn is being treated
4. More total health lost, but ultimately recoverable
5. **Result:** Survives, but in worse condition

### Catastrophic (Panic Path)
1. Player panics and tries to move/flee instead of treating
2. Each movement turn costs health from ticking injuries
3. Crushing wound slows movement (costs extra turns)
4. Player eventually must stop and treat — now with less health
5. **Result:** Survivable if player stops moving soon enough

### Resource-Scarcity Variant
1. Only 2 bandages for 3 wounds
2. Player must decide: which wounds get bandaged?
3. Bleeding (lethal tick) gets priority over minor cut (self-healing)
4. **Teaches:** Not all injuries need treatment. Minor cuts heal on their own.

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Treat minor injury before critical one | Critical injury ticks while time is wasted | Re-prioritize immediately — critical injuries first |
| Use all bandages on non-critical wounds | No bandage for bleeding wound — health drains | Tear cloth from blanket/clothes for emergency bandage |
| Poison escalates to Stage 2 (hallucinations) | Room descriptions become unreliable | Injuries verb remains honest — trust it over room text |
| Player freezes (takes no action) | All ticking injuries accumulate damage | ANY treatment is better than none |
| Wrong treatment for wrong injury | Bandage on poison (doesn't help), water on cut (doesn't help) | No harm done, but resources and time wasted |
| All injuries untreated for 10+ turns | Unconsciousness from accumulated damage | Game continues from unconscious state — wake with partial recovery |

---

## What the Player Learns

1. **Triage is a skill** — prioritizing treatment order saves more health than finding better treatments
2. **Not all injuries are equal** — ticking injuries outrank non-ticking; fast ticks outrank slow ticks
3. **The `injuries` verb is your best tool** — diagnosis before treatment
4. **Resource scarcity forces hard choices** — 2 bandages, 3 wounds. Choose wisely.
5. **Inaction is the worst choice** — doing nothing while injuries tick is the fastest path to death
6. **The game's injury system is deep** — multiple simultaneous injuries with different behaviors and treatments
7. **Self-composure under pressure** — the game rewards the player who stays calm, assesses, and acts methodically

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **FEEL** (global) | "Everything hurts. Your arm throbs. Your hand burns. Your leg won't bear weight" | Immediate post-event — overwhelming |
| **EXAMINE injuries** | Full diagnostic: injury list with type, location, severity, tick rate | Critical information source |
| **LOOK at self** | "You're a mess. Blood on your arm, burns on your hand, your leg buckled under you" | Visual confirmation of multi-injury state |
| **SMELL** | "Blood and singed skin. The air smells like a battlefield" | Atmospheric urgency |
| **LISTEN** | "Your heartbeat is loud in your ears. Racing. You need to calm down and think" | Internal urgency — meta-hint to stop and assess |
| **FEEL individual injuries** | "Your arm wound: deep, bleeding steadily. Your hand: blistered, hot. Your leg: swollen, immobile" | Per-injury detail for prioritization |

---

## Prerequisite Chain

**Objects:** bandage (✅), cloth (✅), wine-bottle (✅), water source (✅), antidote (if poisoned — depends on game state)  
**Verbs:** APPLY (✅), POUR (✅), DRINK (✅), EXAMINE injuries (✅), REST (needs implementation for recovery)  
**Mechanics:** Multiple simultaneous injuries (✅ — injury system supports stacking), per-injury tick rates (✅), treatment matching (✅), resource counting (player assessment)  
**Puzzles:** 020 Wine Wound Wash (teaches antiseptic), 029 Bandage Before Climb (teaches injury-as-gate)

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| bandage | treatment | clean, applied, soiled | `heals: [bleeding, minor-cut]`, `healing_boost: 2` | ✅ |
| cloth | material | normal, torn | `can_become: bandage` | ✅ |
| wine-bottle | antiseptic | open, empty | `provides: antiseptic` (from Puzzle 020) | ✅ |
| water (well-bucket) | treatment | full, empty | `provides: cold_water` (burn treatment) | ✅ |
| antidote | consumable | sealed, open, empty | `cures: poisoned-nightshade` | ✅ (if exists in level) |

No new objects needed — this puzzle is pure systemic mastery of existing objects and mechanics.

---

## Design Rationale

**Why multi-injury triage?** This is the capstone puzzle for the injury system. Everything the player has learned — bandaging (001–005 area), antiseptic wine (020), injury gating (029), treatment matching (002/poison) — converges into a single crisis. Triage proves the player has mastered the system.

**Why Level 5?** Highest decision density in the game. 3–4 injuries simultaneously, each requiring different treatment, with ticking health drain creating time pressure. No single "right answer" — the optimal triage order depends on available resources, injury severity, and proximity to treatment sources. This is pure strategy.

**Why no new objects?** The puzzle IS the system. No new mechanics, no new objects, no new verbs. Just the injury system working at full complexity. This proves the system's depth: it doesn't need new content to create new challenges.

---

## GOAP Analysis

GOAP can resolve individual treatments: `treat bleeding` → find bandage → apply. But GOAP cannot prioritize treatment ORDER. If the player says `treat all injuries`, GOAP might treat the burn first (closest treatment) while the bleeding wound ticks.

The puzzle is the PRIORITIZATION — the meta-strategy that sits above individual treatment chains. This is pure player reasoning.

**GOAP-resolved:** Individual treatment steps (find bandage, apply bandage).  
**Manual:** Deciding WHICH injury to treat FIRST, and managing scarce resources across multiple wounds.

---

## Effects Pipeline Integration

All injuries in this puzzle are pipeline-routed:

```lua
-- Bleeding (from earlier injury source)
{ type = "inflict_injury", injury_type = "bleeding", damage = 4, tick_rate = "fast" }

-- Burn (from fire/explosion)
{ type = "inflict_injury", injury_type = "burn", damage = 3, tick_rate = "slow" }

-- Crushing wound (from collapse/impact)
{ type = "inflict_injury", injury_type = "crushing-wound", damage = 8, tick_rate = "none" }

-- Poison (from earlier ingestion)
{ type = "inflict_injury", injury_type = "poisoned-nightshade", damage = 10, tick_rate = "escalating" }
```

The Effects Pipeline's multi-effect array support means a single catastrophic event can fire all four injuries in one atomic block — consistent, ordered, all routed through `injuries.inflict()`.

---

## Notes & Edge Cases

- **Injury stacking limits:** The system should handle 4+ simultaneous injuries without breaking. Stress test.
- **Treatment order feedback:** After treating one injury, the `injuries` verb should reflect the change — one fewer ticking injury.
- **Unconsciousness threshold:** If total accumulated damage exceeds threshold, player goes unconscious. Game doesn't end — they wake up with some injuries partially healed (auto-stabilization).
- **Mirror feedback (from mirror design):** Looking in a mirror after multi-injury gives a vivid, harrowing description. Powerful narrative moment.
- **Replayability:** Different catastrophic events create different injury combinations. The triage puzzle is procedurally varied.
- **No softlock:** Even untreated, most injury combinations don't instantly kill. The player always has time to act — but less time the longer they wait.

---

## Status

🔴 Theorized — Awaiting Wayne's review. (Note: This puzzle requires no new engine work — it uses the injury system at full existing capability.)

**Owner:** Sideshow Bob  
**Next:** Wayne reviews → Nelson designs test scenarios for multi-injury triage → QA validates that 4-injury stacking works correctly
