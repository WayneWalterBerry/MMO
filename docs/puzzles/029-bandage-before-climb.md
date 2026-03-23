# Puzzle 029: Bandage Before Climb

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty Rating:** Polite (always recoverable — fall causes injury, not death)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — injury capability gating + fall injury on failure  
**New Objects Needed:** ❌ None (all objects exist)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Any room with vertical passage — rope climb, ivy wall, ladder |
| **Objects Required** | bandage (existing), rope-coil (existing) or ivy (existing), cloth (existing) |
| **Objects Created** | None (injury state change + bandage application) |
| **Prerequisite Puzzles** | Player must have an arm/hand injury (from any source) |
| **GOAP Compatible?** | Partial — GOAP can resolve "treat injury" but won't connect to "then climb" |
| **Multiple Solutions?** | 2 (treat injury then climb, or find alternate non-climbing path) |
| **Estimated Time** | 5–10 min (first-time), 2–3 min (repeat) |

---

## Real-World Logic

**Premise:** You can't climb a rope with a gashed hand. You can't grip ivy with crushed fingers. Physical injuries limit physical capabilities — this is basic human experience. A rock climber with a hand injury wraps it before attempting a route. A soldier field-dresses a wound before a forced march. Treatment isn't just healing — it's restoring capability.

**Why it's satisfying:** The player reaches a vertical passage — a rope hanging down, or ivy covering a wall. They try to climb. The engine responds: "You grab the rope and pull. Pain explodes through your injured hand — your grip fails. You slide back down." The player realizes: the injury isn't just health damage — it's a capability gate. They must treat the wound first. Bandage the hand, test the grip, climb. The sequence feels right because it IS right.

**What makes it real:** Every climber, every athlete, every manual laborer knows this: injury → treatment → capability restored. The game makes this explicit and mechanical.

---

## Overview

The player has a hand or arm injury (minor-cut from glass shard, bleeding from knife, crushing-wound from bear trap — any source). They encounter a vertical obstacle that requires grip strength: a rope to climb, ivy to scale, a ledge to pull themselves up to.

The obstacle is impassable while the injury is untreated. The game explicitly gates the climb on injury state: **injured hand/arm → cannot grip → cannot climb.** Treatment (bandaging, splinting) restores the "grip" capability, allowing the climb.

This teaches: **injuries aren't just health numbers — they're capability restrictions.** A bleeding hand can't hold a rope. A crushed foot can't walk a balance beam. Treatment isn't optional healing — it's functional restoration.

---

## Solution Path

### Primary Solution (Treat → Climb)
1. Player has arm/hand injury (any source)
2. Player encounters rope-climb or ivy-wall
3. `CLIMB rope` — **FAILS:** "You grab the rope and haul. Your injured hand screams in protest — fingers won't close properly. You can't get a grip. You slide back down."
4. Player realizes: injury must be treated first
5. `EXAMINE injuries` — "Your left hand has a deep cut across the palm. Blood makes everything slippery."
6. `APPLY bandage TO hand` — "You wrap the bandage tightly around your palm. The pressure hurts, but your fingers can close now."
7. `CLIMB rope` — **SUCCESS:** "Your bandaged hand grips the rope — not perfectly, but enough. You haul yourself upward, hand over hand, teeth gritted against the pain."
8. **Result:** Player ascends. Injury is treated. Capability restored.

### Alternative Solution A (Non-Climbing Path)
1. Player finds an alternate route that doesn't require climbing
2. Stairs, ramp, door on the same level — longer path but no grip required
3. **Result:** Bypasses the climb entirely. Injury still exists but doesn't gate progress.
4. **Trade-off:** More time, possibly more resource consumption (torches, etc.)

### Alternative Solution B (Improvised Grip Aid)
1. Player wraps cloth around the rope (not around their hand) — creates better grip surface
2. `WRAP cloth AROUND rope` — "The rough cloth gives the rope a grippable texture"
3. `CLIMB rope` — works even with untreated injury, but slower and more painful
4. **Result:** Partial success — climbs but takes minor additional damage from exertion on injured hand
5. **Teaches:** There's more than one way to solve a capability restriction

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Attempt climb with untreated injury | Grip fails — slide back down. No additional injury if caught early | Treat injury, try again |
| Attempt climb with untreated injury (persistent) | After 2nd failed attempt: fall — additional bruise injury (3 damage) | Treat BOTH injuries (original + fall bruise), then climb |
| No bandage material available | Can't treat injury conventionally | Tear cloth from blanket/bedsheets/clothing. Or use cloth-on-rope method |
| Bandage hand but injury is on arm/shoulder | Bandage on wrong location — still can't grip | Re-examine injury, apply bandage to correct body part |
| Climb succeeds but bandage loosens at top | Bandage falls — injury reopens | Find more bandage material on the upper level |

---

## What the Player Learns

1. **Injuries gate capabilities** — not just health damage, but functional restrictions
2. **Treatment restores function** — bandaging isn't just health recovery; it enables actions
3. **The body part matters** — hand injury affects grip; leg injury affects walking; eye injury affects sight
4. **Self-assessment is a skill** — `EXAMINE injuries` tells you what's wrong and where
5. **Preparation before action** — treat first, act second. Field medicine.
6. **The game's injury system has teeth** — injuries aren't abstract numbers; they change what you can do

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LOOK at rope** | "A thick hemp rope hanging from above. It looks climbable — if you can grip it" | Hint: grip is required |
| **FEEL rope** | "Rough hemp. Good grip... for an uninjured hand" | Direct capability hint |
| **FEEL hand (injured)** | "Your hand throbs. Blood seeps between your fingers. Closing your fist sends pain shooting up your arm" | Injury limits grip — connection to climb |
| **LOOK at injury** | "A deep cut across your palm, still bleeding. The wound needs treatment" | Diagnosis hint |
| **FEEL bandage (after application)** | "Tight, secure. Your fingers can close now, though it hurts" | Capability restored confirmation |
| **LISTEN (failed climb)** | "The rope creaks as you slide back down. Your hand is too weak" | Failure reinforcement |

---

## Prerequisite Chain

**Objects:** bandage (✅), rope-coil (✅) or ivy (✅), cloth (✅ — alternate bandage source)  
**Verbs:** CLIMB (✅ basic verb), APPLY bandage (✅), EXAMINE injuries (✅)  
**Mechanics:** Injury → capability gating (❌ new — injury system needs to restrict specific verbs based on injury location), grip check on climb (❌ new — climb verb checks hand/arm injury state)  
**Puzzles:** Any puzzle that caused the hand/arm injury (glass shard, knife, bear trap)

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| bandage | treatment | clean, applied, soiled | `heals: [bleeding, minor-cut]`, `restores_capability: grip` | ✅ (needs capability restore) |
| rope-coil | furniture/tool | hanging, climbed | `requires_capability: grip`, `leads_to: upper_room` | ✅ (needs capability check) |
| ivy | climbable surface | normal | `requires_capability: grip`, `is_climbable: true` | ✅ (needs capability check) |

**New mechanic: Capability Gating**
```lua
-- Injury system gates capabilities
-- When hand injury is active and unbandaged:
player.capabilities.grip = false

-- After bandaging:
player.capabilities.grip = true  -- restored

-- Rope/ivy object checks:
climb_requirements = {
    capability = "grip",
    failure_message = "Your injured hand can't grip the rope. You need to treat that wound first.",
}
```

---

## Design Rationale

**Why injury-as-gate?** This is the purest expression of the injury system's design philosophy: injuries aren't just health points — they're functional restrictions. A bleeding hand doesn't just cost HP; it prevents climbing. This makes injuries REAL in a way that pure health damage never can.

**Why Level 3?** The concept is simple (treat injury → restore capability → perform action), but the player must connect three systems: injury assessment, treatment, and capability requirements. The puzzle requires understanding the injury system at a deeper level than "take damage, heal damage."

**Why climbing specifically?** Climbing is a primal physical action. Everyone intuitively understands you need working hands to climb a rope. The connection between "hand injury" and "can't climb" requires zero game-logic explanation — it's just physics.

---

## GOAP Analysis

GOAP can partially resolve this. If the player types `CLIMB rope` and GOAP detects the grip capability gate, it COULD plan: find bandage → apply to hand → climb rope. This is a good candidate for GOAP auto-resolution of the treatment step, letting the player focus on the discovery that treatment is required.

**Manual insight:** Realizing WHY the climb fails (injury-gated, not just "can't climb").  
**GOAP-resolved:** Finding and applying bandage once player understands the gate.

---

## Effects Pipeline Integration

**Fall injury on persistent climb attempts:**
```lua
-- Rope-climb, second failed attempt with untreated injury
effect = {
    type = "inflict_injury",
    injury_type = "bruised",
    source = "fall",
    location = "torso",
    damage = 3,
    message = "You lose your grip halfway up. The fall knocks the wind out of you.",
}
```

**Injury capability gating (systemic, not per-object):**
The injury engine checks `player.injuries` against `object.climb_requirements.capability` before allowing the climb transition. This is engine-level logic, but the capability requirements are declared in object metadata (Principle 8).

---

## Notes & Edge Cases

- **Leg injury variant:** Future expansion — leg injuries gate walking, running, jumping. Same mechanic, different body part.
- **Over-bandaging:** Player might bandage unnecessarily (arm instead of hand). Specific body-part targeting matters.
- **Both hands injured:** If BOTH hands are injured, even bandaging one might not restore full grip. Player needs to treat both.
- **Bandage degrades during climb:** Strenuous activity might cause bandage to loosen. Player might need to re-bandage at the top.
- **Weight matters:** Heavy inventory makes climbing harder (even with treated hands). Future expansion of capability system.
- **No softlock:** Alternate non-climbing path always exists. Injury treatment + climb is the fast path, not the only path.

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs capability-gating system in injury engine → Flanders adds climb_requirements to rope/ivy objects
