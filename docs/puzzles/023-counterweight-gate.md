# Puzzle 023: Counterweight Gate

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty Rating:** Polite (fully recoverable)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — crushing injury if player is under gate when counterweight removed  
**New Objects Needed:** ✅ pressure-plate, portcullis/heavy-gate, counterweight-platform

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Gatehouse, cellar entrance, or fortified passage |
| **Objects Required** | cobblestone (existing), large-crate (existing), grain-sack (existing), any heavy objects |
| **Objects Created** | Gate transitions from closed → open when weight threshold met |
| **Prerequisite Puzzles** | None (standalone mechanical puzzle) |
| **GOAP Compatible?** | Partial — GOAP can place objects on surface but can't calculate weight |
| **Multiple Solutions?** | 3+ (different weight combinations; also brute force with crowbar) |
| **Estimated Time** | 5–15 min (first-time), 2–3 min (repeat) |

---

## Real-World Logic

**Premise:** Counterweight mechanisms are ancient engineering. Castle portcullises, drawbridges, even elevators work on the principle: put enough weight on one side, the other side moves. Medieval castles used counterbalanced gates that required specific weight to operate — a security feature that ensured only someone who understood the mechanism (or had enough heavy objects) could open the passage.

**Why it's satisfying:** The player finds a heavy iron gate blocking their path. Nearby, a stone platform with an obvious depression and chain running up to a pulley system. The logic is mechanical, visible, and tactile: *put heavy things on the platform until the gate lifts.* No magic words, no hidden switches — just physics.

---

## Overview

A heavy iron gate (portcullis) blocks a passage. Next to it is a stone platform connected to a chain-and-pulley counterweight system. When enough weight is placed on the platform, the chain pulls taut and the gate rises. The required weight is approximately 50 kg — more than any single object the player carries, but achievable by combining several heavy objects.

The puzzle teaches: **objects have weight, and weight has mechanical consequence.** The player must inventory their belongings, assess which objects are heavy enough, and place a sufficient combination on the platform.

---

## Solution Path

### Primary Solution (Multiple Heavy Objects)
1. Player encounters closed portcullis with chain-and-pulley mechanism
2. `EXAMINE platform` — "A flat stone platform with a depression, connected by iron chain to a pulley above the gate"
3. `EXAMINE chain` — "The chain runs from the platform, up through a pulley, and connects to the gate's counterweight. The platform is empty — the gate is down"
4. Player places objects on platform:
   - `PUT cobblestone ON platform` — chain creaks, gate lifts slightly (partial)
   - `PUT grain-sack ON platform` — gate lifts further but not enough
   - `PUT large-crate ON platform` — gate lifts fully, locks into open position
5. **Result:** Gate is open. Player can pass through.

### Alternative Solution A (Single Very Heavy Object)
1. If player has found a single very heavy object (anvil, stone block — if available)
2. `PUT anvil ON platform`
3. **Result:** Gate opens with one object

### Alternative Solution B (Crowbar Brute Force)
1. `PRY gate WITH crowbar` — player forces the gate up manually
2. **Result:** Gate opens, but only while player holds it. Need to prop it.
3. `PROP gate WITH crowbar` — crowbar wedged under gate
4. **Result:** Gate stays open, but crowbar is now unavailable
5. **Trade-off:** Lose crowbar (useful tool) to bypass the weight puzzle

### Alternative Solution C (Player Stands on Platform)
1. `STAND ON platform` — player's own weight counts toward threshold
2. Gate lifts partially but not enough with player alone
3. Place additional objects while standing on platform
4. **Problem:** Gate opens, but player is ON the platform — stepping off resets it
5. Must leave an object to substitute for player's weight before stepping off
6. **Result:** Teaches conservation of weight — can't just use yourself

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Not enough weight on platform | Gate lifts partway then drops back | Find more heavy objects and try again |
| Remove object from platform while under gate | ⚠️ Gate crashes down — crushing injury (Effects Pipeline) | Treat injury, replace weight on platform |
| Use crowbar to prop gate, then need crowbar later | Crowbar is stuck under gate | Return and `TAKE crowbar` — gate closes again |
| Put fragile object on platform | Object might break under chain tension (vase shatters) | Use sturdier objects |
| Try to lift gate by hand | "The gate is far too heavy to lift manually" | Use the mechanism or crowbar |

---

## What the Player Learns

1. **Objects have weight** — weight is a game property, not just flavor text
2. **Mechanical systems follow physics** — counterweights, pulleys, balance
3. **Multiple objects combine to solve a problem** — no single "key" object
4. **Trade-offs exist** — crowbar bypass costs a valuable tool
5. **Environmental hazards are real** — standing under a heavy gate when the weight shifts is dangerous
6. **Observation reveals mechanism** — the chain-pulley system is visible and examinable

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LOOK at gate** | "A heavy iron portcullis blocks the passage. Thick chains run from its frame up to the ceiling" | First encounter |
| **LOOK at platform** | "A flat stone platform, slightly depressed, with a groove for objects. An iron chain leads from it upward to a pulley" | Examining the mechanism |
| **FEEL platform** | "Cold stone, worn smooth by use. The depression is sized for objects, not people" | Tactile investigation |
| **LISTEN** | "When you push the platform down with your hand, you hear chains clink and the gate creak slightly upward" | Testing the mechanism |
| **LOOK at chain** | "The chain connects platform to gate through a pulley system. When the platform sinks, the gate rises" | Understanding the mechanics |
| **FEEL gate** | "Iron bars, cold and immovable. You can see through the gaps to the passage beyond" | Confirming the obstacle |

---

## Prerequisite Chain

**Objects:** cobblestone (✅), large-crate (✅), grain-sack (✅), crowbar (✅ for alternate solution)  
**Verbs:** PUT ON (✅), PRY (✅ crowbar verb), STAND ON (needs compound), PROP (needs new verb)  
**Mechanics:** Weight system (❌ new — objects need `weight` property used mechanically), counterweight threshold  
**Puzzles:** None required

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| cobblestone | portable heavy | normal | `weight: 15` | ✅ (needs weight value) |
| large-crate | portable heavy | normal | `weight: 25` | ✅ (needs weight value) |
| grain-sack | portable heavy | tied, untied | `weight: 12` | ✅ (needs weight value) |
| crowbar | tool | normal, wedged | `weight: 5`, `provides: prying_tool` | ✅ |
| pressure-platform | furniture | empty, partial, triggered | `weight_threshold: 50`, `connected_to: portcullis` | ❌ New |
| portcullis | furniture | closed, partial, open | `blocks_exit: true` (closed), `counterweight_chain: platform` | ❌ New |

---

## Design Rationale

**Why counterweight?** It's the most intuitive mechanical puzzle possible. Everyone understands "heavy things make other things move." No abstraction needed — the player sees the chain, sees the platform, understands the relationship.

**Why Level 3?** The core concept (put weight on platform) is simple. The challenge is finding enough heavy objects and managing the weight budget. Multi-step but not lateral-thinking.

**Why the crushing injury?** Actions have consequences. If you remove the counterweight while standing under the gate, the gate falls on you. This is physically obvious and teaches spatial awareness around mechanical systems.

---

## GOAP Analysis

GOAP can partially resolve: `open gate` → find heavy objects → place on platform. But GOAP cannot calculate weight thresholds or determine which combination of objects meets the requirement. The player must:

1. Understand the mechanism (observation)
2. Assess available heavy objects (inventory check)
3. Calculate or estimate weight requirements (trial and error)
4. Execute placement in correct order

GOAP handles object acquisition and placement. The player handles weight estimation.

---

## Effects Pipeline Integration

**Crushing injury when gate falls on player:**
```lua
-- portcullis, transition: open → closed (weight removed while player underneath)
effect = {
    type = "inflict_injury",
    injury_type = "crushing-wound",
    source = "portcullis",
    location = "torso",
    damage = 12,
    message = "The gate crashes down! Iron bars slam into your shoulders and back, driving you to the ground.",
}
```

This uses the same `crushing-wound` injury type as the bear trap, routed through the Effects Pipeline.

---

## Notes & Edge Cases

- **Weight persistence:** Objects placed on platform stay there. Player can leave and return — gate stays open as long as weight is sufficient
- **Object retrieval:** Player can `TAKE cobblestone FROM platform` — but gate may close if weight drops below threshold
- **Stacking order doesn't matter:** Platform cares about total weight, not arrangement
- **Future expansion:** Pressure plates in other rooms could use the same weight-threshold system
- **Player weight:** Player could stand on platform to contribute, but must solve the "step-off" problem
- **No softlock:** Crowbar alternate always works even with zero heavy objects

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs weight-threshold mechanic → Flanders builds platform + portcullis objects
