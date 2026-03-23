# Puzzle 022: Smoke Draft Reveal

**Status:** 🔴 Theorized  
**Difficulty:** ⭐⭐⭐⭐ Level 4  
**Cruelty Rating:** Polite (no unwinnable states)  
**Author:** Sideshow Bob (Puzzle Master)  
**Last Updated:** 2026-07-28  
**Uses Effects Pipeline:** ❌ No direct pipeline use (uses existing fire/light systems)  
**New Objects Needed:** ✅ incense-stick (or use existing incense-burner with fuel)

---

## Quick Reference

| Field | Value |
|-------|-------|
| **Room(s)** | Sealed room with hidden exit (crypt, cellar, or walled chamber) |
| **Objects Required** | Any smoke source (candle, incense-burner, torch), match/fire source |
| **Objects Created** | Hidden exit revealed (room state mutation — new exit appears) |
| **Prerequisite Puzzles** | 001 Light the Room (fire mechanics), any puzzle that puts player in sealed room |
| **GOAP Compatible?** | No — GOAP cannot infer "use smoke to find draft" |
| **Multiple Solutions?** | 3 (smoke observation, feel for draft by hand, brute-force search walls) |
| **Estimated Time** | 10–20 min (first-time), 3–5 min (repeat) |

---

## Real-World Logic

**Premise:** Smoke follows air currents. This is how firefighters find ventilation in burning buildings, how spelunkers locate cave exits, and how medieval builders tested chimney drafts. If a room has a hidden opening — a crack, a loose stone, a concealed door — and air is flowing through it, smoke will drift toward it and reveal it.

**Why it's satisfying:** The player is trapped in a room with no visible exit. They've examined every wall, every surface. Nothing. But they have a candle. When they hold it near the walls, the flame flickers — and in one spot, it flickers *hard*. There's a draft. Something is behind that wall. The smoke from the candle (or incense) drifts toward a specific section, revealing a hidden passage.

**What makes it real:** This is physics, not magic. Air moves through gaps. Smoke makes air movement visible. The player who thinks "Where is the air coming from?" solves the puzzle. The player who thinks "I need to find the hidden switch" does not.

---

## Overview

The player enters a room that appears sealed — no doors, no visible exits (or only the way they came in, now blocked). The room description mentions "the air is slightly cool" or "a faint breeze touches your skin." These are sensory clues that air is entering the room from somewhere.

The puzzle: **use smoke to make the air current visible, then trace it to the hidden exit.**

A lit candle, torch, or incense produces visible smoke. Holding the smoke source near walls reveals where the draft is strongest. At that point, the player can EXAMINE, PUSH, or FEEL the wall section to discover the hidden passage.

---

## Solution Path

### Primary Solution (Smoke Observation)
1. Player enters sealed room — description mentions cool air or faint breeze
2. Player has lit candle, torch, or incense
3. `HOLD candle NEAR wall` — or simply `LOOK AT candle` while near walls
4. **Engine response:** "The candle flame dances wildly, pulled toward the east wall. Thin smoke trails drift eastward."
5. `EXAMINE east wall` — "Looking more carefully at the east wall, you notice the mortar between two stones is crumbling. A thin gap runs vertically."
6. `PUSH east wall` or `PUSH stone` — the loose stones shift, revealing a narrow passage
7. **Result:** Hidden exit revealed — new room connection established

### Alternative Solution A (Feel the Draft)
1. No smoke source needed
2. `FEEL walls` — systematic tactile exploration
3. "As your hand passes the east wall, you feel cool air on your palm. A draft."
4. `EXAMINE east wall` → `PUSH stone`
5. **Result:** Same outcome, but takes longer and requires the player to think of checking for drafts manually

### Alternative Solution B (Brute Force — Examine Everything)
1. `EXAMINE north wall`, `EXAMINE south wall`, `EXAMINE east wall`, `EXAMINE west wall`
2. East wall examine reveals: "The mortar here seems newer than the rest. Slightly different color."
3. `PUSH east wall` → passage opens
4. **Result:** Works, but the visual clue is subtle. Most players won't try all four walls without a prompt.

### Alternative Solution C (Incense Trail)
1. If player has incense-burner (existing object): `LIGHT incense`
2. Heavy smoke production — even more obvious visual trail
3. "Thick incense smoke gathers near the ceiling, then flows steadily toward the east wall, disappearing into a crack you hadn't noticed."
4. `EXAMINE crack` → `PUSH stone`
5. **Result:** Most dramatic and clear solution

---

## Failure Modes

| Failure | Consequence | Recovery |
|---------|-------------|----------|
| No fire source available | Can't produce smoke; must use FEEL or brute-force alternatives | Always solvable without smoke (just harder) |
| Examine walls but miss draft clue | Player feels stuck; room seems sealed | FEEL hint: "Cool air on your skin" nudges toward walls |
| Push wrong wall section | "The wall is solid stone. It doesn't budge" | Redirect to the right section — no penalty |
| Light a fire without ventilation | Room fills with smoke — player coughs, mild discomfort | Smoke still reveals the draft; this IS the solution working |
| Waste all fire sources before reaching this room | Must find draft by touch alone | FEEL works — slower but solvable |

---

## What the Player Learns

1. **Environmental physics are real** — air currents, smoke behavior, drafts through cracks
2. **Sensory verbs reveal hidden information** — FEEL detects drafts, LOOK at fire shows flicker direction
3. **"No exit" doesn't mean no exit** — the game rewards thorough investigation
4. **Tools have observational uses** — a candle isn't just for light; it's a draft detector
5. **The environment gives clues before you ask** — "cool air" in room description is the hint
6. **Multiple approaches work** — smoke is elegant, touch is reliable, brute force is slow but valid

---

## Sensory Hints

| Sense | Hint | When |
|-------|------|------|
| **FEEL** (ambient) | "The air in this room is slightly cool, as if from somewhere unseen" | Room entry — first clue |
| **FEEL walls** | "Your hand feels cold air seeping through a crack near the east wall" | Active tactile investigation |
| **LOOK at candle** | "The candle flame leans persistently to the east, trailing smoke" | While holding lit candle |
| **LOOK at smoke** | "Wisps of smoke curl toward the east wall and vanish into a thin gap" | Explicit smoke observation |
| **LISTEN** | "A faint whistling — almost sub-audible — seems to come from the east" | Wind through a narrow gap |
| **SMELL** | "The air smells different here — fresher, like outside air mixing in" | Near the hidden exit |
| **LOOK east wall** | "The mortar between these stones is lighter than the rest. Newer?" | Visual clue (subtle) |

**Sensory escalation:** The room whispers its secret through multiple senses. Players who use more senses get more clues. The smoke method is the most dramatic and clear.

---

## Prerequisite Chain

**Objects:** Any lit smoke source — candle (✅), torch (✅), incense-burner (✅ object exists, needs "lit" state)  
**Verbs:** HOLD NEAR (new compound — or use proximity detection), PUSH (✅), EXAMINE (✅), FEEL (✅)  
**Mechanics:** Smoke visibility system (❌ new — engine needs to track "smoke visible" state when fire source is in room), room state mutation on wall push (similar to trap-door reveal)  
**Puzzles:** 001 Light the Room (fire source chain), any puzzle leading to sealed room

---

## Objects Required

| Object | Type | State(s) | Key Properties | Built? |
|--------|------|----------|----------------|--------|
| candle (or any fire source) | light/tool | lit | `produces_smoke: true`, `flame_visible: true` | ✅ (needs smoke property) |
| incense-burner | container/tool | empty, loaded, lit, spent | `produces_heavy_smoke: true` when lit | ✅ (needs state expansion) |
| sealed-wall-section | furniture (hidden) | sealed, cracked, open | `has_draft: true`, `blocks_exit: true` | ❌ New room element |

**New room element: sealed-wall-section**
- Not a portable object — a room feature
- States: `sealed` (no visual clue without smoke), `cracked` (player has found the gap), `open` (passage revealed)
- Transition: sealed → cracked on `EXAMINE` after smoke/draft discovery; cracked → open on `PUSH`
- Principle 8: All logic in the wall-section metadata — draft direction, smoke behavior, reveal trigger

---

## Design Rationale

**Why smoke?** It's visceral. The player watches their candle flame lean sideways, sees smoke trail toward a wall, and *follows it*. This is exploration-as-physics, not exploration-as-pixel-hunting. It teaches players to observe their tools, not just use them.

**Why Level 4?** The core insight — "smoke reveals air currents" — is non-obvious in a game context. Most players don't think of fire as an observational tool. It requires lateral thinking: the candle isn't just for seeing, it's for *detecting*. The puzzle has multiple solutions but the elegant one requires a conceptual leap.

**Why this room?** Sealed rooms are common in dungeon/manor settings. A bricked-up passage, a collapsed tunnel, a hidden crypt entrance — all realistic scenarios for a draft-through-crack setup.

---

## GOAP Analysis

GOAP cannot resolve this puzzle. The planner has no concept of "use smoke to find hidden exit." The player must:

1. Notice the environmental clue (cool air)
2. Connect fire → smoke → air current → hidden gap
3. Manually hold fire source near walls
4. Discover and open the passage

GOAP can assist with sub-steps (finding fire source, lighting candle) but the core insight is entirely manual.

---

## Notes & Edge Cases

- **Wind extinguishing:** The existing wind/draft mechanic (on_traverse extinguishes candles) could be repurposed here — if the candle goes out near the east wall, that ITSELF is a clue
- **Torch vs. candle:** Torch flame is bigger and more visible, making the draft effect more dramatic; candle is subtler but still works
- **Darkness:** The puzzle works best with a lit source (you see the flame flicker). In total darkness, FEEL is the only available sense
- **Replayability:** Once the player learns "smoke finds drafts," they'll use this technique proactively in future sealed rooms
- **No softlock:** The room always has a FEEL-based solution even without fire

---

## Status

🔴 Theorized — Awaiting Wayne's review.

**Owner:** Sideshow Bob  
**Next:** Wayne approves → Bart designs smoke-visibility mechanic → Flanders builds sealed-wall-section object
