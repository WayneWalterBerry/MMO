# Puzzle 021: Improvised Torch

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐ Level 3  
**Cruelty Rating:** Polite (recoverable with consequences)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ✅ Yes — fire_source tool chain, burn injury on misuse  
**New Objects Needed:** ❌ None (uses existing objects in new combination)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Any dark area after candle/torch has been consumed |
| **Objects Required** | rag (existing), oil-flask (existing), crowbar or stick-like object (existing) |
| **Objects Created** | improvised-torch (composite mutation) |
| **Prerequisite Puzzles** | 001 Light the Room (teaches fire mechanics) |
| **GOAP Compatible?** | No — GOAP won't infer crafting recipe; player must reason it |
| **Multiple Solutions?** | 2 (rag+oil+handle = torch, or rag+oil alone = hand-held flaming cloth) |
| **Estimated Time** | 5–10 min (first-time), 2–3 min (repeat) |

---

## Real-World Logic

**Premise:** Humans have made torches for 400,000 years. Wrap cloth around a stick, soak it in oil, light it. Every survival manual, every medieval soldier, every cave-dweller knew this. When your candle burns out and the oil lantern is empty, you improvise.

**Why it's satisfying:** The player's candle has burned to a stub and gone dark. The oil lantern ran dry. They're in a room with a rag, an oil flask, and a crowbar. The game never tells them "combine rag + oil + crowbar." But the answer is obvious to anyone who thinks like a person: *make a torch.* The crafting system rewards the player's real-world knowledge, not memorized game recipes.

---

## Overview

The player has exhausted their primary light sources (candle burned out, torch consumed, lantern empty). They're in darkness again. Somewhere nearby they have — or can find — a rag, an oil flask, and a handle (crowbar, stick, bone). The puzzle is realizing they can construct an improvised torch from these components.

This puzzle teaches: **the crafting system follows real-world logic.** If an action makes physical sense, the game supports it. There's no recipe list — there's physics and common sense.

---

## Solution Path

### Primary Solution (Full Torch)
1. Player is in darkness (light sources consumed)
2. `TAKE rag` — acquire cloth/rag
3. `WRAP rag AROUND crowbar` — attach cloth to handle (compound action)
4. `POUR oil ON rag` — soak the wrapped rag with oil from flask
5. `STRIKE match ON matchbox` — ignite a match (if available)
6. `LIGHT rag WITH match` — ignite the oil-soaked rag
7. **Result:** Improvised torch created — provides light, burns for 15–20 minutes

### Alternative Solution A (Hand-Held Flaming Rag)
1. `POUR oil ON rag` — soak rag directly
2. `LIGHT rag WITH match` — ignite it
3. **Result:** Flaming rag in hand — short burn time (2–3 min), risk of burn injury to hand
4. **Trade-off:** Faster to make, but dangerous and brief

### Alternative Solution B (Oil on Existing Torch Stub)
1. If player has a burned-out torch stub: `POUR oil ON torch` — re-fuel the stub
2. `LIGHT torch WITH match`
3. **Result:** Revived torch — moderate burn time

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Light dry rag (no oil) | Burns out in 15 seconds — flash of light, then dark | Find oil and try again with another cloth |
| Hold flaming rag bare-handed | Burn injury (minor) after 30 seconds | Drop rag, bandage hand, try wrapping on handle next time |
| Pour oil but no ignition source | Oily rag sits inert — "It's wet and smells of oil" | Find matches or another fire source |
| Use all oil on rag (overpour) | Oil flask empty; rag drips and sputters | Still works, but can't refuel lantern later |
| Wrap rag too loosely | Rag falls off handle when moved — needs re-wrapping | `TIE rag TO crowbar` for secure attachment |
| Try to light oil flask directly | Oil flask ignites! Violent fire — burn injury, flask destroyed | ⚠️ Harsh failure — teaches respect for accelerants |

---

## What the Player Learns

1. **Crafting follows physics** — if it makes sense in real life, it works in the game
2. **Components have properties** — rag absorbs oil, oil is flammable, handle provides safe grip
3. **Quality of construction matters** — hand-held rag burns you; wrapped-on-handle doesn't
4. **Resource management carries forward** — oil used for torch can't fuel lantern
5. **Fire is dangerous** — lighting oil carelessly causes injury (Effects Pipeline burn)
6. **Multiple crafting tiers** — quick-and-dirty (rag alone) vs. proper (rag + oil + handle)

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **SMELL rag** | "It smells of dust and old burlap" | Before oiling — flammable material hint |
| **SMELL oil-flask** | "The unmistakable smell of lamp oil — sharp, petroleum-like" | Identifying the fuel source |
| **FEEL rag** | "Rough burlap, loosely woven. It would soak up liquid easily" | Hints at absorption property |
| **FEEL crowbar** | "Heavy iron bar, good grip. About two feet long" | Suitable as handle |
| **LOOK at rag after oiling** | "The rag glistens with oil, dripping slightly" | Confirms oil absorption |
| **SMELL after oiling** | "The oily rag reeks of fuel. One spark and it would catch" | Direct flammability hint |

---

## Prerequisite Chain

**Objects:** rag (✅), oil-flask (✅), crowbar (✅), matchbox + match (✅)  
**Verbs:** WRAP/TIE (needs compound action support), POUR ON (✅ with target), LIGHT WITH (✅)  
**Mechanics:** Fire-source tool chain (✅), composite object creation (✅ exists for other objects)  
**Puzzles:** 001 Light the Room (teaches fire mechanics), 010 Light Upgrade (teaches oil identification)

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| rag | material | normal, oiled, burning, charred | `absorbs_liquid: true`, `flammable: true` | ✅ (needs state expansion) |
| oil-flask | consumable | full, half, empty | `provides: lamp-oil`, `flammable_liquid: true` | ✅ |
| crowbar | tool/handle | normal | `provides: prying_tool, handle` | ✅ |
| matchbox + match | fire source | normal, lit, burnt | `provides: fire_source` | ✅ |
| improvised-torch | composite (created) | burning, extinguished, spent | `casts_light: true`, `burn_time: 1200s` | ❌ (crafted dynamically) |

---

## Design Rationale

**Why these objects?** All exist in the game already. The rag is a flavor object that gains mechanical purpose. The oil flask is currently only for the lantern — this gives it a second use. The crowbar is a tool that doubles as a handle. No new objects needed — just new interactions between existing ones.

**Why Level 3?** The core insight (make a torch from rag + oil + handle) requires multi-step planning and isn't suggested by the game. GOAP won't auto-resolve it. But anyone who's watched a survival show or lit a campfire will get it.

**Why this matters for game flow:** Light sources are consumable and finite. Players will inevitably run out. The improvised torch teaches them that the game doesn't dead-end when resources deplete — creativity provides alternatives.

---

## GOAP Analysis

GOAP cannot resolve this puzzle. The planner knows "I need light" and can find existing light objects, but it has no recipe for "construct improvised torch from components." The player must:

1. Recognize the need (dark, no light sources)
2. Inventory their materials (rag, oil, handle)
3. Reason about the combination (rag + oil = flammable; handle = safe grip)
4. Execute the craft steps manually

This is a pure player-reasoning puzzle. GOAP provides no scaffolding.

---

## Effects Pipeline Integration

**Burn injury on misuse (hand-held flaming rag):**
```lua
-- Rag in "burning" state, held in hand without handle
on_tick_effect = {
    type = "inflict_injury",
    injury_type = "burn",
    source = "improvised-torch",
    location = "hand",
    damage = 3,
    message = "The flames lick at your fingers. You can't hold this much longer!",
}
```

**Oil flask ignition (trying to light the flask directly):**
```lua
-- oil-flask, transition: attempt to light directly
effect = {
    { type = "inflict_injury", injury_type = "burn", source = "oil-flask",
      damage = 8, message = "The oil erupts! Flames engulf your hand and arm." },
    { type = "narrate", message = "The flask shatters in a ball of fire, spraying burning oil." },
    { type = "mutate", target = "self", field = "state", value = "destroyed" },
}
```

All injury effects route through the pipeline — no hardcoded verb logic.

---

## Notes & Edge Cases

- **Candle stub as alternative handle:** If player has a candle-holder, wrapping rag around it could also work
- **Thread/rope binding:** Player might `TIE rag TO crowbar WITH thread` — should be supported
- **Rain/water extinguishes:** If improvised torch enters a wet area, it can be extinguished
- **Indoor fire hazard:** Using torch near flammable objects (curtains, bed) should be dangerous
- **No softlock:** Player can always wait for dawn or find another light source path

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Flanders adds WRAP/TIE compound actions and rag state expansion
