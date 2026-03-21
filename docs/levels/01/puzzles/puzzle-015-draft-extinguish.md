# Puzzle 015: Draft Extinguish

**Status:** 🔴 Theorized  
**Difficulty:** ⭐ Level 1 (Trivial)  
**Zarfian Cruelty:** Merciful (soft failure, immediate recovery)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Environmental/Spatial (State Change) + Transformation/State Mutation  
**Author:** Sideshow Bob  
**Last Updated:** 2026-07-22  
**Critical Path:** NO — occurs on the critical path route but does NOT block it

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Deep Cellar → Hallway (stairway transition, during Puzzle 011) |
| **Objects Required** | Lit candle (existing), stairway draft (environmental effect) |
| **Objects Created** | None — candle mutates from `lit` → `extinguished` (existing FSM state) |
| **Prerequisite Puzzles** | 001 (Light the Room — must have a lit candle) |
| **Unlocks** | Nothing — teaches EXTINGUISH/RELIGHT verbs |
| **GOAP Compatible?** | Yes — "relight candle" triggers GOAP chain (find match, strike, apply) |
| **Multiple Solutions?** | 3 (relight candle, use lantern instead, continue in darkness by feel) |
| **Estimated Time** | < 1 min |

---

## Overview

As the player ascends the stone stairway from the Deep Cellar toward the Hallway, a gust of warm air from the manor above rushes down the stairwell and extinguishes their candle. The stairway acts as a natural chimney — cold dense air below, warm air above, and the pressure differential creates intermittent downdrafts. This is a real phenomenon in stone stairwells of medieval buildings.

The player's candle flame gutters and dies. Darkness returns. The player must relight the candle (using matchbox and a fresh match), continue upward by feel toward the warmth and faint light under the door, or — if they completed Puzzle 010 — their oil lantern is wind-resistant and stays lit.

This is the lightest-touch puzzle in Level 1. It's a single environmental event with an immediate, obvious recovery. Its purpose is purely tutorial: teach the player that candles can go out, that RELIGHT (or LIGHT) restores them, and that environmental conditions affect fire. It also retroactively rewards players who found the oil lantern — a tangible "I'm glad I explored" moment.

---

## Trigger Mechanism

### The Chimney Effect

The stone stairway connects two spaces at different temperatures:
- **Deep Cellar:** 9°C, moisture 0.3, still air
- **Hallway:** ~18°C (heated manor), moving air

When the player enters the stairway, they move through a temperature gradient. The stairway is a vertical stone shaft — a natural chimney. The pressure differential between the cold cellar and the warm hallway creates downdrafts that gust intermittently. These gusts are strong enough to extinguish an unprotected candle flame but not a shielded lantern.

### Engine Mechanism

The stairway exit (passage `deep-cellar-hallway-stairway`) needs an `on_traverse` environmental effect:

```
on_traverse = {
    wind_effect = {
        strength = "gust",
        extinguishes = { "candle" },        -- objects without wind_resistant = true
        spares = { wind_resistant = true },  -- oil lantern survives
        message_extinguish = "Halfway up the stairway, a gust of warm air rushes down from above. Your candle flame gutters, flickers wildly — and goes out. Darkness swallows the stairwell.",
        message_spared = "A gust of warm air rushes down the stairway. Your lantern flame dances behind its glass chimney but holds steady.",
        message_no_light = nil               -- no message if player has no light
    }
}
```

**Implementation note for Bart:** This is the first `on_traverse` environmental effect. The pattern is: when a player moves through an exit, check for environmental effects that interact with carried objects. The candle's existing `lit → extinguished` FSM transition is triggered automatically — no new verb handler needed. The exit metadata declares the effect; the engine resolves it against carried object properties.

---

## Solution Paths

### Path 1: Relight the Candle (Primary — Teaches RELIGHT)

1. **Candle extinguished** — Automatic event during stairway traversal.
2. **Player types:** `LIGHT candle` or `RELIGHT candle`
3. **GOAP resolves:** Find match in matchbox → strike match on matchbox → light candle
4. **Result:** Candle relights. Player continues upward in light.
5. **Message on relight:** "The candle catches again, its flame small at first, then growing steadier. The draft has passed — for now."

**Teaching moment:** The player discovers that `RELIGHT` works — the candle isn't ruined, just extinguished. This is the core lesson. The candle's `extinguished` state preserves its remaining burn time (per Principle 3 — `remaining_burn` tracks partial consumption). The player doesn't lose resources except one match.

### Path 2: Oil Lantern Survives (Reward for Puzzle 010)

1. **Player carries lit oil lantern** (completed Puzzle 010)
2. **Draft gusts** — Lantern's `wind_resistant = true` property means the flame stays lit
3. **Message:** "A gust of warm air rushes down the stairway. Your lantern flame dances behind its glass chimney but holds steady."
4. **Result:** No interruption. Player continues in light.

**Teaching moment:** The lantern is BETTER than the candle in concrete, experienced terms. The player who explored thoroughly is rewarded. Per Frink §2.4 [17] (Outer Wilds): knowledge is the key — the player who understands light-as-resource and upgraded gets a smoother ride.

### Path 3: Continue in Darkness (Navigation by Feel)

1. **Candle extinguished** — and player has no matches left, or chooses not to relight
2. **Player types:** `GO UP` or `FEEL` or `CLIMB`
3. **Sensory clues guide them:** Warmer air from above, faint light under the door at the top, smooth worn steps underfoot
4. **Result:** Player reaches the hallway in darkness. The hallway has its own light sources (torches, described in Puzzle 011).

**Teaching moment:** Even without light, progress is possible. FEEL works. Environmental clues (warmth, faint light) guide navigation. This reinforces the Puzzle 001 lesson — darkness is a limitation, not a wall.

---

## What the Player Learns

1. **EXTINGUISH exists** — Fire can be put out by environmental forces, not just player action. The candle's `lit → extinguished` transition fires from wind, not from typing "extinguish." The player sees the verb in action before they ever need to use it themselves.
2. **RELIGHT restores extinguished candles** — The candle isn't destroyed when blown out. It can be relit. The `extinguished` state is different from `spent` (burned out). This distinction matters for resource management in later levels.
3. **Wind affects fire** — Environmental conditions interact with object states. This foreshadows Level 2+ scenarios where wind, water, or other environmental forces affect the player's tools.
4. **The lantern is superior** — If the player has the lantern, they experience its `wind_resistant` property firsthand. The lantern's advantage isn't just longer burn time — it's environmental resilience. This reward makes Puzzle 010 feel worthwhile.
5. **GOAP handles relighting** — The relight chain (find match → strike → apply) is GOAP-resolvable. The player learns that the engine helps with repetitive tool chains, reinforcing confidence in the system.

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Candle blown out, no matches left | Must navigate in darkness | FEEL + warmth guide player upward; hallway has its own light |
| Player panics and goes back down | Returns to Deep Cellar (still dark) | Can return to stairway and try again |
| Player tries to shield candle | No mechanic for this (yet) — draft still extinguishes | Relight or accept darkness |
| Player has no light source at all | Already navigating by feel | No change — draft has no effect |

### Failure Reversibility

**Impossible to fail permanently.** The candle can be relit (if matches remain), the lantern is immune, and the player can always navigate by feel. The hallway at the top has its own light sources. This is Zarfian Merciful — the player cannot get stuck, lose progress, or suffer irreversible consequences.

---

## Objects Required

### Existing Objects (No Changes Needed)

| Object | Role | Relevant Properties |
|--------|------|---------------------|
| **candle** | Victim of draft | `states: {unlit, lit, extinguished, spent}`. Transition `lit → extinguished` (verb: "extinguish", aliases: "blow", "put out", "snuff"). Transition `extinguished → lit` (verb: "light", alias: "relight"). `remaining_burn` preserved across extinguish/relight. |
| **oil-lantern** | Draft-immune alternative | `wind_resistant: true` when lit. Draft does not affect it. |
| **matchbox + matches** | Relight tools | Standard fire chain. GOAP auto-resolves. |

### New Properties Needed (for Bart / Moe)

| Change | Owner | Description |
|--------|-------|-------------|
| **Stairway exit `on_traverse` effect** | Moe (room metadata) + Bart (engine) | The exit `deep-cellar-hallway-stairway` needs an `on_traverse` property that checks carried objects for `casts_light = true` AND `wind_resistant ~= true`, and triggers their `extinguish` FSM transition. See Engine Mechanism section above. |
| **Engine: `on_traverse` handler** | Bart | New pattern: exits can declare environmental effects that fire during player traversal. This is the first instance but the pattern should be generic (future uses: water crossings that extinguish all fire, narrow passages that block large objects, etc.). |

### No New Objects Needed

This puzzle uses entirely existing objects. The candle's FSM already supports the full `lit → extinguished → lit` cycle. The oil lantern already declares `wind_resistant: true`. The only new work is the environmental trigger on the stairway exit.

---

## Design Rationale

### Why the Stairway?

**Physics:** Stone stairwells in medieval buildings are natural chimneys. The temperature differential between cellar (9°C) and hallway (~18°C) creates pressure-driven airflow. Gusts in stairwells are a documented real-world phenomenon — anyone who's lived in an old building with a basement staircase knows the draft. Per Frink §4.1 [26]: puzzles should reflect real-world physics that players intuitively understand.

**Narrative:** The draft signals transition. Cold cellar air below, warm manor air above. The gust that extinguishes the candle is the environment TELLING the player they're between two worlds — the oppressive underground and the warmer surface. It's a moment of brief vulnerability before the relief of reaching the hallway.

**Pacing:** This occurs during Puzzle 011 (Ascent to Manor), which is the simplest critical-path puzzle — pure navigation. Adding the candle-extinguish event gives the stairway a moment of tension without adding complexity. One quick disruption, one quick fix, then the player emerges into the hallway's warmth and light.

### Why Not a Separate Room?

CBG's analysis suggested "a draft in the stairway." Making this an exit-traversal event (not a room) keeps it lightweight. The stairway isn't a room — it's a transition between rooms. The draft happens during that transition. This keeps the puzzle integrated into existing navigation rather than creating a new space.

### Why This Teaches EXTINGUISH Better Than a Forced Verb

The player doesn't type EXTINGUISH — the environment does it TO them. This is more powerful than a tutorial prompt: the player experiences extinguishment as a consequence, then must figure out the recovery (RELIGHT). They learn the concept through disruption, not instruction. Per Frink §2.1 [11] (The Witness): the best tutorials never tell you the rules — they show you the results.

### Cross-Puzzle Synergy

- **Puzzle 001 (Light the Room):** Taught the player to LIGHT a candle. This puzzle teaches that lighting isn't permanent.
- **Puzzle 010 (Light Upgrade):** The optional lantern proves its worth here. Players who skipped the lantern face a minor setback; players who found it sail through. This validates the optional exploration.
- **Puzzle 004 (Inventory Management):** If the player dropped the matchbox to free hands, they can't relight here. Lesson: keep your fire tools accessible.

---

## GOAP Analysis

### What GOAP Resolves
- "LIGHT candle" / "RELIGHT candle" → find match → strike on matchbox → apply flame → candle lit
- Standard fire chain, depth 3-4 depending on matchbox state

### What GOAP Cannot Resolve
- N/A — this is a 1-step recovery puzzle. The "aha" is recognizing what happened and knowing to relight.

### GOAP Interaction
After the candle goes out, the player types "light candle" and GOAP handles everything. This is intentional — the puzzle teaches the CONCEPT (candles can go out), not the MECHANICS (find a match, strike it). GOAP handles the tedious recovery so the player focuses on the lesson.

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **FEEL (stairway)** | "A draft of warmer air gusts down the stairway" | Wind exists here — fire at risk |
| **SMELL (after extinguish)** | "Candle smoke — a thin trail of acrid tallow smoke curls upward in the draft" | Confirms the candle was just lit; it went out, not burned out |
| **LISTEN (stairway)** | "The wind moans softly through the stairwell, echoing off stone" | Auditory confirmation of airflow |
| **FEEL (candle, extinguished)** | "The wick is warm and waxy. A wisp of smoke rises from it. The candle is out, but the wick isn't spent — it could be relit." | Explicit hint that RELIGHT is possible |

---

## Related Puzzles

- **Requires:** Puzzle 001 (Light the Room) — must have lit candle
- **Occurs during:** Puzzle 011 (Ascent to Manor) — same stairway transition
- **Rewards:** Puzzle 010 (Light Upgrade) — lantern is immune to draft
- **Teaches toward:** Level 2 wind/stealth mechanics (blow out candle for darkness, relight for visibility)
- **Contrasts with:** Puzzle 001 — learning to light vs. learning that light isn't permanent

---

## Handoff Notes

### For Flanders (Object Designer)
No new objects needed. The candle's existing FSM already handles `lit → extinguished → lit` transitions perfectly. The oil lantern's `wind_resistant = true` property is already defined. This puzzle is 100% environmental — it's about the ROOM triggering an existing object transition, not about new object behavior.

### For Moe (World Builder)
The stairway exit (`deep-cellar-hallway-stairway` in `deep-cellar.lua`) needs an `on_traverse` environmental wind effect. This effect should:
1. Check if the player carries any object with `casts_light = true` and WITHOUT `wind_resistant = true`
2. Trigger that object's `extinguish` FSM transition
3. Display the appropriate message (extinguish or spared)

The stairway room description already mentions "a faint draft of warmer air descends from above" — this is the clue. The draft description is already written; the EFFECT of the draft is new.

### For Bart (Architect)
This introduces the `on_traverse` exit-effect pattern. The concept: exits can declare environmental effects that fire when the player moves through them. This is a generic pattern — future uses include water crossings, narrow passages, hot rooms, etc. The first implementation is simple: check carried objects against a property filter, trigger an FSM transition if the filter matches.

---

*"The best tutorial moments aren't lessons — they're little disasters that teach you something you didn't know you needed. A gust of wind. A dead flame. A moment of 'oh no' followed immediately by 'oh, I can fix this.' That's learning." — Sideshow Bob*
