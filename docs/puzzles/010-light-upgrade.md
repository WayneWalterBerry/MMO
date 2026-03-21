# Puzzle 010: Light Upgrade (Optional)

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐ Level 2 (Introductory)  
**Zarfian Cruelty:** Merciful (completely optional, no failure state)  
**Classification:** 🔴 Theorized  
**Pattern Type:** Combination/Synthesis (Binary) + Transformation/State Mutation  
**Author:** Sideshow Bob  
**Last Updated:** 2026-07-22  
**Critical Path:** NO — optional upgrade, rewards exploration

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Storage Cellar |
| **Objects Required** | Oil lantern (on shelf), wine bottle with oil (on wine rack), fire source (candle or match) |
| **Objects Created** | Lantern-lit (state mutation of oil lantern) |
| **Prerequisite Puzzles** | 006 (Iron Door Unlock — must be in Storage Cellar) |
| **Unlocks** | Superior light source (longer burn time than candle, brighter, wind-resistant) |
| **GOAP Compatible?** | Partial — GOAP can resolve "light lantern" if lantern is fueled and fire source available, but cannot resolve "fill lantern with oil" without player combining them |
| **Multiple Solutions?** | 1 primary (find oil, fill lantern, light); alternate: skip entirely and rely on candle |
| **Estimated Time** | 2–5 min (if player explores thoroughly) |

---

## Overview

By the time the player reaches the Storage Cellar, their candle may be burning low — it's been alight since the Bedroom, and each room transition consumes burn time. On a dusty shelf sits an old oil lantern, dry and dark. Nearby on the wine rack, among the bottles of spoiled wine, one bottle contains lamp oil (distinguishable by smell — "acrid and oily, not vinous"). If the player pours the oil into the lantern and lights it, they gain a superior light source: longer burn time, brighter illumination, and resistance to drafts that might extinguish a candle.

This puzzle is entirely optional. The candle is sufficient to complete Level 1's critical path if the player is efficient. But the lantern rewards the observant explorer with insurance against running out of light in the deeper, darker cellars ahead — a tangible reward for thoroughness. The design follows the Outer Wilds principle (Frink §2.4 [17]): knowledge is the key. The player who understands that light is a consumable resource, and who plans ahead, is rewarded.

---

## Solution Path

### Primary Solution: Find Oil, Fill Lantern, Light It

1. **Discover the oil lantern** — On a shelf along the wall. LOOK: "A brass oil lantern sits on the shelf, its glass chimney clouded with soot. The reservoir is dry — no wick flame without fuel." FEEL: "Cold brass, a hinged door on one side. The reservoir feels empty."
2. **TAKE oil lantern** — Player picks up the lantern. It's one-handed (has a handle).
3. **Examine wine rack** — Several bottles sit on the rack. Most contain wine (or are empty). One contains oil.
4. **SMELL wine bottles** — Most smell of vinegar or stale wine. One stands out: "This bottle smells sharp and acrid — not wine. Lamp oil, perhaps." The oil bottle is distinguishable by smell, not by sight (bottles look identical with dusty labels).
5. **TAKE oil bottle** — Player takes the oil bottle.
6. **POUR oil INTO lantern** or **FILL lantern WITH oil** — Player fills the lantern's reservoir. Message: "You pour the thick, acrid oil into the lantern's reservoir. It fills with a satisfying gurgle."
   - Lantern transitions from `empty` → `fueled` state. Wick is now saturated.
7. **LIGHT lantern** — Player applies fire source (candle flame, lit match). Message: "You hold your candle flame to the lantern wick. It catches, and a warm, steady glow fills the glass chimney — brighter and steadier than the candle's guttering flame."
   - Lantern transitions from `fueled` → `lit` state. Properties: `casts_light: true`, extended burn time (14400 game seconds — double the candle), `wind_resistant: true`.

### Alternative: Skip Entirely

The player can ignore the lantern and proceed with the candle. If the candle burns out in the Deep Cellar, the player must navigate by non-visual senses (FEEL, SMELL, LISTEN) — harder but not impossible. The game is never softlocked by lack of light.

### GOAP Behavior

- "LIGHT lantern" → GOAP detects `requires: fuel` guard (lantern is empty). GOAP does NOT know which bottle contains oil — this is a discovery/sensory puzzle.
- After player manually fills the lantern: "LIGHT lantern" → GOAP resolves fire source chain (find match, strike it, apply to lantern wick).
- GOAP handles the mechanical lighting; the player handles the oil discovery.

---

## What the Player Learns

1. **Resource upgrading** — Tools can be improved. A candle is good; a lantern is better. This teaches players to look for upgrades, not just minimum-viable tools. Per Frink's escape room research (§3.3): "solution to puzzle A becomes a tool for puzzle B."
2. **SMELL as puzzle mechanic** — The oil bottle is identified by smell, not sight. This deepens the multi-sensory interaction system introduced in the Bedroom. Per Frink's §6.4: "Cross-Sensory Deduction" — combining LOOK (bottles look the same) with SMELL (one smells different) to identify the correct object.
3. **Material properties matter** — Oil is flammable fuel. The lantern needs oil to function. This is the first explicit material-combination puzzle, foreshadowing the richer material-physics puzzles in later levels (per Frink's §6.3: material properties create new puzzle types).
4. **Light is a strategic resource** — The candle burns down. The lantern burns longer. Planning ahead (fuel management) is rewarded. This reinforces the consumable pressure from Puzzle 001 at a new scale.
5. **Optional content rewards thoroughness** — Players who explore every shelf and bottle find the lantern. Players who rush miss it. The game rewards curiosity without punishing haste.

---

## Failure Modes & Consequences

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| Never find the oil lantern | No impact — candle still works | Continue with candle |
| Find lantern but not oil | Lantern remains dry and useless | Search wine bottles by SMELL |
| Pour wine (not oil) into lantern | Wick won't light (wine isn't fuel). "The wick sputters and dies — that liquid isn't lamp oil." | Try other bottles; SMELL to find oil |
| Light lantern without glass chimney | Burns but poorly (future design: chimney can be cleaned/replaced) | Still provides light, just reduced |
| Run out of candle before finding lantern | Must navigate by FEEL/SMELL/LISTEN | Can still find and light lantern using matches directly |

### Failure Reversibility

**No failure possible.** This is a purely optional enhancement. The player cannot be worse off for attempting it. Even pouring the wrong liquid is a soft lesson, not a punishment. Zarfian Merciful: impossible to get stuck.

---

## Objects Required

### Existing Objects
- **Candle/candle-holder** — player's existing light source (fire source for lighting lantern)
- **Matches** — backup fire source if candle is extinguished

### New Objects Needed (for Flanders)

| Object | Type | Key Properties | Notes |
|--------|------|----------------|-------|
| **oil-lantern** | Light source (upgradeable) | `states: {empty, fueled, lit, extinguished, spent}`, `container: {accepts: ["lamp_oil"]}`, `casts_light: true` when lit, `burn_time: 14400`, `wind_resistant: true` when lit, `hands_required: 1` | Composite object: brass body + glass chimney + wick. Key feature: burns 2x longer than candle. |
| **oil-bottle** | Container (consumable) | `states: {sealed, open, empty}`, `contains: lamp_oil`, `on_smell: "Sharp and acrid — not wine. Lamp oil, perhaps."`, looks identical to wine bottles visually | On wine rack among wine bottles. Only distinguishable by SMELL. |
| **wine-bottle** (×2-3) | Container (flavor) | `states: {sealed, open, empty}`, `contains: wine` or empty, `on_smell: "Sour vinegar"` or `"Stale, spoiled wine"` | Red herrings on wine rack. Same visual appearance as oil bottle. |

---

## Design Rationale

### Why This Puzzle?

**Research grounding:** Frink's research highlights the Outer Wilds model (§2.4 [17]): "knowledge is the only key — no inventory gates." This puzzle inverts the typical IF pattern. The lantern and oil are both freely available in the room — there's no locked container or key required. The "gate" is the player's *understanding* that light is a depletable resource worth upgrading, and their *sensory skill* in identifying oil by smell. GOAP cannot solve this because the bottleneck is knowledge, not logistics.

**Sensory puzzle design:** Per Frink's §6.4, our multi-sensory system is our competitive advantage. This is the first puzzle where SMELL is the primary discovery channel (not just atmospheric). The oil bottle looks the same as wine bottles — only SMELL distinguishes it. This trains players for more sophisticated sensory puzzles in later levels.

**Progressive complexity (Witness model, §2.1 [11]):** Puzzle 001 taught "find fire source → light candle." Puzzle 010 teaches "find fuel → fill lantern → light lantern." Same structure, one more step. The addition of the fuel-filling step is the new concept; everything else is familiar.

**Resource management escalation:** CBG's level design notes (level-01-intro.md §Resource Scarcity) suggest candle duration should be "tight but sufficient for critical path." The lantern is the insurance policy for optional content (crypt, altar puzzle). This creates a natural reward: explorers get the lantern and can safely explore the crypt; speed-runners skip it and risk darkness in optional areas.

### Level Boundary Consideration

The **oil lantern** is a powerful tool that could trivialize "find light" puzzles in Level 2. Options:
1. Lantern oil runs out during Level 1 exploration (natural consumption)
2. Lantern glass chimney breaks during the stairway ascent (natural breakage)
3. Lantern is too large to fit through a narrow passage (containment constraint)

Recommend option 1: tune oil quantity so the lantern lasts through Level 1 optional content but is spent by the time the player reaches Level 2. Flag for CBG's boundary audit.

---

## GOAP Analysis

### What GOAP Resolves
- "LIGHT lantern" (when fueled) → find fire source → light lantern wick
- "TAKE lantern" → standard take action
- "OPEN oil bottle" → standard open action

### What GOAP Cannot Resolve (The Puzzle)
- Which bottle contains oil (sensory discovery, not inventory chain)
- That the lantern needs oil (player must read/feel the "empty reservoir" description and understand it)
- That oil exists in this room at all (discovery)

### GOAP Depth Analysis
- Fill + light chain: pour oil (1) → find fire source (2) → light lantern (3) = depth 3
- But the oil discovery is pre-GOAP — it's a knowledge gate

---

## Sensory Hints

| Sense | Clue | What It Reveals |
|-------|------|-----------------|
| **LOOK (lantern)** | "Glass chimney clouded with soot. Reservoir is dry." | Lantern exists but needs fuel |
| **FEEL (lantern)** | "Cold brass, hinged door. Reservoir feels empty." | Confirms need for fuel |
| **SMELL (oil bottle)** | "Sharp and acrid — not wine. Lamp oil, perhaps." | Identifies correct bottle |
| **SMELL (wine bottles)** | "Sour vinegar" / "Stale, spoiled wine" | Eliminates wrong bottles |
| **LOOK (wine rack)** | "Dusty bottles, labels peeling. They all look much the same." | Visual alone insufficient |

---

## Related Puzzles

- **Builds on:** Puzzle 001 (Light the Room) — same fire-source concept, upgraded tool
- **Enables:** Puzzle 012 (Altar Puzzle) and Puzzle 014 (Sarcophagus Puzzle) — both benefit from sustained light
- **Resource chain:** Candle (Bedroom) → Lantern (Storage) — ascending quality of light sources

---

*"The best upgrades in games are the ones you didn't know you needed until the moment you realize your old tool is about to fail. The lantern is that beautiful anxiety-to-relief pipeline." — Sideshow Bob*
