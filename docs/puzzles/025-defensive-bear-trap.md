# Puzzle 025: Defensive Bear Trap

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐ Level 4  
**Cruelty Rating:** Tough (wrong placement wastes the trap; injury to player if they trigger it themselves)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — bear trap crushing-wound routes through pipeline; NPC injury  
**New Objects Needed:** ✅ bait-meat (or use existing object as lure), NPC/creature system for pursuer

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Narrow passage, doorway, or corridor with chokepoint |
| **Objects Required** | bear-trap (existing), bait (new or existing food item), knowledge of pursuer's path |
| **Objects Created** | bear-trap transitions to "triggered" state when pursuer steps on it |
| **Prerequisite Puzzles** | Player has encountered (and is being pursued by) a threat |
| **GOAP Compatible?** | No — requires strategic planning, spatial reasoning, and timing |
| **Multiple Solutions?** | 3 (trap + bait, barricade the door, hide and let pursuer pass) |
| **Estimated Time** | 10–20 min (first-time), 3–5 min (repeat) |

---

## Real-World Logic

**Premise:** Traps are humanity's oldest defensive technology. Before weapons, before walls, people dug pit traps and set snares to protect themselves from predators. A bear trap in a doorway, baited to draw a threat through it, is a survival technique as old as civilization.

**Why it's satisfying:** Something is hunting the player — footsteps echoing behind them, getting closer. They enter a room with one way in and one way out. On a shelf, a bear trap. The player sets the trap in the doorway, places bait beyond it (so the pursuer must walk THROUGH the trap to reach the bait), and hides. The pursuer enters, steps on the trap — SNAP. The threat is neutralized. The player turned the hunter into the hunted.

**What makes it real:** This is how trapping works. Location, bait, patience. The bear trap already exists in the game as a hazard — this puzzle flips it into a tool.

---

## Overview

The player is being pursued by a hostile entity (creature, NPC, environmental threat). They discover a bear trap in a room along their escape route. Instead of avoiding the trap (which they've been taught to do — traps are dangerous), they must recognize it as a *tool* and deliberately set it as a defense.

The puzzle inverts the player's learned behavior. Previously, bear traps were hazards to avoid. Now, the bear trap is the solution. The player must:
1. Disarm the trap safely (if it's set)
2. Carry it to a chokepoint
3. Re-arm it in the pursuer's path
4. Optionally bait it to ensure the pursuer walks into it
5. Hide and wait

---

## Solution Path

### Primary Solution (Trap + Bait + Chokepoint)
1. Player is aware of pursuit (sound cues, environmental storytelling)
2. Player finds bear-trap (in "set" state — dangerous to touch)
3. `EXAMINE bear-trap` — "A vicious iron jaw trap, its teeth spread wide and cocked. One wrong move and it snaps shut."
4. `DISARM bear-trap` — uses careful manipulation to release tension (requires tool: stick, crowbar, or careful hands)
5. `TAKE bear-trap` — now portable (in "disarmed" state)
6. Move to chokepoint (doorway, narrow passage)
7. `SET bear-trap ON floor` or `PLACE bear-trap IN doorway` — arms the trap
8. `PUT meat BEYOND trap` — bait placed to lure pursuer through the trap
9. `HIDE` or move to a concealed position
10. **Trigger:** Pursuer enters room, moves toward bait, steps on trap → SNAP
11. **Result:** Pursuer is trapped — crushing-wound via Effects Pipeline. Threat neutralized.

### Alternative Solution A (Barricade)
1. Don't use the trap at all
2. `PUSH crate AGAINST door` — barricade the entrance
3. **Result:** Buys time but doesn't neutralize the threat. Pursuer eventually breaks through.
4. **Trade-off:** Temporary safety vs. permanent solution

### Alternative Solution B (Hide and Evade)
1. Find a hiding spot (wardrobe, behind curtains, under bed)
2. `HIDE IN wardrobe`
3. **Result:** Pursuer searches room and may or may not find player (stealth check)
4. **Trade-off:** Risky — if found, player is cornered

### Alternative Solution C (Stand and Fight)
1. Use knife, crowbar, or other weapon
2. Direct confrontation — risky, may cause injuries to player
3. **Result:** Varies based on combat (if system exists)

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Touch set trap without disarming | Crushing-wound to hand (15 damage — Effects Pipeline) | Treat injury, trap is now triggered (re-set it) |
| Set trap but no bait | Pursuer might avoid the trap (steps around it) | Place bait to ensure path through trap |
| Set trap in wrong location | Pursuer enters through different door or path | Move trap to correct chokepoint |
| Player steps on own trap | Crushing-wound to foot/leg — ironic failure | Treat injury, re-set trap (humbling lesson) |
| Pursuer arrives before trap is set | Player must improvise (fight, flee, hide) | Trap setup is time-sensitive — urgency mechanic |
| Use the only bait for something else | No lure — trap placement must be precisely in path | Position trap directly in doorway threshold (riskier) |

---

## What the Player Learns

1. **Hazards can become tools** — objects have dual nature (danger vs. defense)
2. **Strategic spatial thinking** — chokepoints, bait placement, line of approach
3. **Trap mechanics from the other side** — previously victim, now tactician
4. **Time pressure creates urgency** — pursuer is approaching; every turn counts
5. **Preparation rewards** — players who explore thoroughly have more options
6. **The game allows creative defense** — not just fight-or-flight

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **LISTEN** | "Heavy footsteps echo from the passage behind you. Getting closer." | Pursuit established — urgency |
| **LOOK at bear-trap** | "Iron jaws, spring-loaded. It's set and ready to snap shut on anything that touches it" | Discovery — tool recognition |
| **FEEL doorway** | "The doorway is narrow — barely wide enough for a person. Perfect chokepoint." | Spatial hint for trap placement |
| **SMELL bait** | "The meat smells strong, gamey. Anything hunting would pick up this scent." | Confirms bait effectiveness |
| **LISTEN** (after setting trap) | "The footsteps pause at the entrance. A sniffing sound. Then heavy steps moving forward..." | Tension building before trigger |
| **LISTEN** (trap triggers) | "SNAP! A shriek of metal and a howl of pain. Something just stepped into your trap." | Confirmation of success |

---

## Prerequisite Chain

**Objects:** bear-trap (✅ exists), bait-meat or food (❌ new), chokepoint room (level design)  
**Verbs:** DISARM (❌ new — careful manipulation), SET/ARM (❌ new — reverse of disarm), HIDE (❌ new — stealth action)  
**Mechanics:** Pursuit system (❌ new — NPC/creature follows player), trap triggering by NPC (❌ new — NPC traversal triggers `on_traverse`), NPC injury (❌ new — pipeline routes to NPC health)  
**Puzzles:** Any encounter that establishes the pursuer

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| bear-trap | trap/tool | set, disarmed, triggered | `effects_pipeline: true`, crushing-wound on contact | ✅ |
| bait-meat | consumable/lure | raw, placed | `scent_radius: 2`, `attracts: hostile_npcs` | ❌ New |
| chokepoint-doorway | room feature | normal | `width: narrow` (trap covers full width) | Level design |

**New bear-trap transitions needed:**
```lua
-- Disarming: set → disarmed (safe to carry)
{ from = "set", to = "disarmed", verb = "disarm",
  requires_tool = "prying_tool",  -- or careful hands
  message = "You carefully lever the jaw mechanism open and lock the release. The trap is now safe to handle." },

-- Re-arming: disarmed → set (dangerous again)
{ from = "disarmed", to = "set", verb = "set",
  message = "You pull the jaws apart and cock the spring mechanism. The trap is armed and deadly." },
```

---

## Design Rationale

**Why bear trap as defense?** The bear trap is already the game's signature contact-injury object. Flipping it from hazard to tool creates a satisfying narrative arc: the player was once the victim of traps, now they're the tactician. This teaches that the game world is consistent — objects behave the same regardless of who's using them.

**Why Level 4?** The core insight (use a hazard defensively) requires inverting learned behavior. The execution (disarm → carry → position → arm → bait → hide) is a multi-step chain with time pressure. One wrong move causes self-injury. This is advanced play.

**Why pursuit?** Time pressure transforms the puzzle from theoretical to urgent. The player isn't leisurely setting a trap — they're scrambling to prepare before something arrives. Every wasted turn is a turn closer to confrontation.

---

## GOAP Analysis

GOAP cannot resolve this puzzle. The planner has no model for "set trap to catch pursuer." The entire puzzle is:
1. Threat assessment (recognize you're being hunted)
2. Environmental scan (find the trap, identify the chokepoint)
3. Strategic planning (disarm, carry, position, arm, bait)
4. Execution under time pressure

All manual. No auto-resolution possible.

---

## Effects Pipeline Integration

**Bear trap on NPC (pursuer steps on trap):**
```lua
-- bear-trap, on_traverse effect (NPC triggers)
effect = {
    type = "inflict_injury",
    injury_type = "crushing-wound",
    source = "bear-trap",
    location = "leg",
    damage = 15,
    message = "The trap snaps shut with brutal force. The creature howls, its leg caught in iron jaws.",
}
```

**Bear trap on player (accidental self-trigger):**
```lua
-- Same effect, different narration for player
effect = {
    type = "inflict_injury",
    injury_type = "crushing-wound",
    source = "bear-trap",
    location = "foot",
    damage = 15,
    message = "SNAP! Blinding pain erupts from your foot. You've stepped on your own trap.",
}
```

Both paths route through the Effects Pipeline. The trap doesn't know or care who triggers it — Principle 8 compliance.

---

## Notes & Edge Cases

- **Trap reuse:** After triggering, the trap is in "triggered" state. Player can `RESET bear-trap` for future use (if not damaged)
- **Multiple traps:** If player finds more than one trap, they can set up a gauntlet
- **NPC behavior:** Pursuer must have pathfinding that routes through the chokepoint. If pursuer has alternate path, bait becomes essential to force the desired route
- **Ethical dimension:** The player is deliberately causing severe injury to a living thing. This is noted but not punished — survival is survival
- **Player softlock:** No. All alternate solutions (barricade, hide, fight) remain available even if trap fails
- **Sound design:** The SNAP of the trap should be one of the most satisfying moments in the game

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs pursuit/NPC traversal system → Flanders adds disarm/set transitions to bear-trap
