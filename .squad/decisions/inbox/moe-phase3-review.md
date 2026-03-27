# Moe — Phase 3 Plan Review (World/Room Perspective)

**Author:** Moe (World Builder)
**Date:** 2026-08-16
**Plan Reviewed:** `plans/npc-combat/npc-combat-implementation-phase3.md` v1.0
**Requested By:** Wayne "Effe" Berry

---

## Verdict: CONDITIONAL APPROVE

Phase 3 is architecturally sound from a world perspective. The creature lifecycle loop does not require room file changes, and the mutation-based corpse system respects room composition principles. However, there are **3 blockers** and **4 concerns** that need resolution before execution.

---

## 1. Room Impacts — Do Any Waves Require Room File Changes?

**Finding: NO room file changes required for WAVE-0 through WAVE-4. WAVE-5 has a gap.**

The plan is well-designed here. Corpse objects (WAVE-1) appear dynamically via mutation — the dead-rat object gets placed into the room registry at runtime, not in the `.lua` room file. Loot drops (WAVE-2) similarly instantiate to the room floor through the engine. The `cook` verb (WAVE-3), cure system (WAVE-4) — none of these touch room files.

**However:** The antidote-vial (WAVE-4, line 486) says "location TBD by Moe — study shelf or cellar cabinet." That's my call, and I'll make it:

> **DECISION: Antidote-vial placement → storage-cellar wine-rack.**
> The storage cellar already has a wine rack with bottles. A small vial tucked among bottles is thematically perfect — the player finds it while scavenging supplies. It rewards thorough exploration of the storage area. The spider lives in deep-cellar (one room north), so the cure is close but requires backtracking.

This means `storage-cellar.lua` needs a one-line addition to the wine-rack contents:
```lua
{ id = "antidote-vial", type = "Antidote Vial", type_id = "{GUID}" },
```
**Owner: Moe** (room file change) + **Flanders** (object file).

---

## 2. Respawning — BLOCKER #1: Home Room Assignments Are Wrong

**Severity: BLOCKER — must fix before WAVE-5 implementation.**

The respawn table on line 555-561 assigns `home_room` values that contradict the actual room files:

| Creature | Plan Says `home_room` | Actual Room Placement | Status |
|----------|-----------------------|-----------------------|--------|
| rat | `start-room (cellar)` | `cellar.lua` → `cellar-rat` | ⚠️ Ambiguous — says "start-room" with "(cellar)" in parens |
| cat | `courtyard` | `courtyard.lua` → `courtyard-cat` | ✅ Correct |
| wolf | `hallway` | `hallway.lua` → `hallway-wolf` | ✅ Correct |
| spider | `deep-cellar` | `deep-cellar.lua` → `deep-cellar-spider` | ✅ Correct |
| bat | `crypt` | `crypt.lua` → `crypt-bat` | ✅ Correct |

**Issue 1 — Rat home_room ambiguity:** The plan says `start-room (cellar)` which is contradictory. The rat is placed in `cellar.lua`, so `home_room` must be `"cellar"`. The parenthetical "(cellar)" suggests Bart meant cellar but wrote start-room. This MUST be clarified — a wrong home_room means the rat respawns in the bedroom (where the player starts!) instead of the cellar.

**Issue 2 — Rat max_population = 3 in the cellar:** The cellar is a small room (2 objects + 2 exits). Three rats in a 2-exit cellar creates a potential "rat gauntlet" that blocks the critical path (cellar is mandatory to reach storage-cellar and deep-cellar). Recommend `max_population = 2` or ensure rats don't block movement.

**Required fix:** Change rat row to `home_room = "cellar"`, consider reducing `max_population` to 2.

---

## 3. Respawning — BLOCKER #2: No Room Spawn-Point System

**Severity: BLOCKER — design gap, not a code gap.**

The respawn engine (line 537-548) says "a new instance spawns" when the timer expires, but doesn't specify WHERE in the room the creature appears. Currently, creature instances in rooms are declared as room-level entries (e.g., `{ id = "cellar-rat", type_id = "..." }`). They don't use spatial relationships (`on_top`, `underneath`, etc.) — they're just "in the room."

**This is actually fine for Phase 3** — creatures are room-level entities, not spatially nested. But I want this explicitly documented in the plan:

> Respawned creatures appear as room-level registry objects, equivalent to their original placement. No spatial sub-location (on_top, underneath, etc.) applies to creatures.

If Phase 4 ever adds creatures that nest (e.g., "rat under the barrel"), the respawn system would need spawn-point metadata. For now, room-level is correct.

**Required fix:** Add a single sentence to the respawn engine design (Section 4, WAVE-5) clarifying spawn position = room-level. This prevents Bart from over-engineering spatial creature spawning.

---

## 4. Environmental — BLOCKER #3: Q3 (Brazier) Creates Room File Obligation

**Severity: BLOCKER — blocks WAVE-3 cook→eat loop if unresolved.**

Q3 (line 795-807) recommends a cellar brazier as the Level 1 fire source for cooking. The plan recommends Option B but marks it as an open question pending Wayne's input.

**From a world perspective, I endorse Option B (cellar brazier) but with a location change:**

The cellar (`cellar.lua`) already has a torch-bracket (empty iron bracket). A brazier beside the torch-bracket is thematically consistent — medieval cellars had braziers for warmth and light.

**However**, the plan's comment "cook your rat kill right where you found it" misunderstands the map. The rat spawns in the cellar, but the cook→eat loop requires a fire source. If the brazier is also in the cellar, the entire kill→cook→eat arc happens in one room. That's fine for the minimal loop, but consider: should we instead place the brazier in the **storage-cellar**? Arguments:

- Storage cellar has grain-sack (Phase 3 adds grain-handful cookable). Grain + fire in same room = natural "pantry" feel.
- Forces the player to carry the dead rat one room north (minor navigation challenge).
- Keeps the cellar as a "transit + danger" room (rat encounter), storage-cellar as "resource + crafting" room.

**My recommendation: Brazier in storage-cellar.** But this is Wayne's call.

**Required fix:** Wayne must resolve Q3 before WAVE-3. Once resolved, Moe adds the brazier instance to the chosen room file, Flanders creates the object.

---

## 5. Spatial — Corpses as Room Objects

**Finding: Well-handled. No concerns.**

The plan correctly treats corpses as standard room objects with `room_presence` text. Dead creature objects (WAVE-1, line 209-222) are required to have `room_presence` per sensory requirements on line 221. The dead-wolf (furniture template, not portable) stays where the wolf died — this naturally creates spatial storytelling.

**One note:** Dead-wolf with `template = "furniture"` means it appears in the room view like any furniture. The wolf's `room_presence` when dead is already defined in `wolf.lua` line 55: `"A dead wolf sprawls across the floor."` However, the MUTATED dead-wolf.lua object needs its own `room_presence` that differs from the creature's FSM dead-state text. Flanders should be aware that the dead-wolf **object** is a different entity from the wolf **creature** in dead state — it needs independently authored sensory text.

**No room file changes needed for corpses.** The engine handles runtime placement.

---

## 6. Spatial — Corpses Blocking Movement

**Finding: NOT addressed in the plan. Minor concern.**

Dead-wolf is `template = "furniture"` and `portable = false`. Could a dead wolf block an exit? The current exit traversal system checks player fit and carry constraints, but doesn't check for "obstacle objects blocking the exit direction." A wolf corpse sprawled across a doorway is realistic but potentially game-breaking if it blocks the only exit.

**Recommendation:** Add a note in WAVE-1 that dead creature objects do NOT have `blocks_exit` or any movement-blocking property. Corpses are flavor, not obstacles. If we ever want blocking corpses (e.g., a dead dragon filling a corridor), that's a Phase 4+ feature.

---

## 7. Map Flow — Does Phase 3 Change the Player Journey?

**Finding: Minimal impact, but combat sound propagation (WAVE-4) has implications.**

The player journey through Level 1 is unchanged:
- Bedroom → cellar → storage-cellar → deep-cellar → hallway (critical path)
- Optional: bedroom → courtyard (window escape), deep-cellar → crypt (side area)

Phase 3 adds creatures dying and respawning along this path, but doesn't add rooms, exits, or change connectivity.

**However, combat sound propagation (WAVE-4, line 490-498) introduces a new map-flow concern:**

> "Emit `loud_noise` stimulus to current room + adjacent rooms. Creatures in adjacent rooms may flee away from combat sounds. Predators in adjacent rooms may investigate (approach)."

This means fighting the rat in the cellar could attract the spider from deep-cellar (two rooms away — cellar → storage-cellar → deep-cellar). Wait — the spider is in deep-cellar, which is NOT adjacent to cellar. The rooms between them are:
- cellar → (north) → storage-cellar → (north) → deep-cellar

So cellar combat sound reaches storage-cellar (adjacent), not deep-cellar. That's fine. But:

- Fighting the spider in deep-cellar emits sound to storage-cellar AND crypt (both adjacent). No creatures currently in storage-cellar, bat in crypt. A bat attracted by combat sounds could create an unexpected multi-creature encounter.
- Fighting the wolf in hallway emits sound to... deep-cellar (down), bedroom (south), and Level 2 rooms (north/west/east). The bedroom adjacency means a player retreating to the bedroom after a wolf fight could have creatures following.

**Recommendation:** The plan should document which room-pairs are "acoustically adjacent" for sound propagation, or confirm it just uses the exit graph. This matters for world design — I need to know if adding rooms later changes creature attraction patterns.

---

## Summary

| # | Type | Item | Status |
|---|------|------|--------|
| 1 | **BLOCKER** | Rat `home_room` must be `"cellar"`, not `"start-room (cellar)"` | Fix before WAVE-5 |
| 2 | **BLOCKER** | Respawn spawn-position must document "room-level, no spatial nesting" | Add sentence to WAVE-5 |
| 3 | **BLOCKER** | Q3 (fire source / brazier) must be resolved before WAVE-3 | Wayne decision needed |
| 4 | Concern | Rat `max_population = 3` may overwhelm cellar — recommend 2 | Discuss with Bart |
| 5 | Concern | Dead-wolf object needs independently authored `room_presence` (not reuse creature FSM text) | Note for Flanders |
| 6 | Concern | Corpses should explicitly NOT block exits | Add note to WAVE-1 |
| 7 | Concern | Combat sound propagation adjacency should be documented for world design | Add to WAVE-4 |

**Antidote-vial placement decided:** storage-cellar wine-rack (Moe responsibility, one-line room file edit).

---

**Verdict: CONDITIONAL APPROVE** — Fix the 3 blockers (all are small clarifications, not redesigns) and I'm fully on board. The plan respects room composition principles, doesn't require room file rewrites, and the mutation-based corpse system is exactly right for the world layer.

— Moe
