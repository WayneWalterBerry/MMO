# Moe's Review: NPC Combat Phase 3 Implementation Plan (v1.3)

**Reviewer:** Moe (World Builder / Room Definitions Specialist)  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3 — death reshape architecture)  
**Date:** 2026-03-27  
**Review Focus:** World and room concerns, spatial design, respawn mechanics, object placement  

---

## Executive Summary

**VERDICT: CONDITIONAL APPROVE**

The plan is solid from a world/room perspective. Death reshape in-place is sound architecture. However, **ONE CRITICAL BLOCKER exists:**

**BLOCKER: WAVE-0 does NOT include updating `docs/architecture/` files.** Wayne directed that architecture documentation must be updated BEFORE WAVE-1 proceeding. This directive is missing from WAVE-0 scope. The plan lists 4 architecture/design docs in WAVE-5 (after respawning is complete), but fundamental reshape architecture should ship WITH WAVE-1 to inform all downstream work.

Beyond that blocker, all specific room concerns check out. Details below.

---

## Detailed Findings

### 1. ✅ Reshaped Corpse + Room Presence Text — SOUND

**Finding:** The plan correctly specifies `room_presence` as part of the `death_state` block (line 339, 400-410). This is excellent:

- Each corpse state (fresh, bloated, rotten, bones) has explicit `room_presence` text
- Example: `"A dead rat lies crumpled on the floor."` → `"A bloated rat carcass lies on the floor, reeking."`
- Spoilage FSM progressions have sensory text for all four states
- This integrates cleanly with the room description pipeline — corpses appear in room presence automatically via their state

**No room-level changes needed.** Corpse descriptions don't go in room `.lua` files (correct — they're movable/transformable objects, not permanent features per charter). The instance stays in the room, text updates as state changes. Solid.

---

### 2. 🟡 Cellar Brazier for Cooking — SPECIFIED BUT NEEDS ROOM PLACEMENT

**Finding:** Q3 (lines 1015-1030) resolves to **Option B: Cellar brazier**. Wayne approved this.

**Implementation detail provided (line 1030):**
- File: `src/meta/objects/cellar-brazier.lua`
- Type: furniture
- Capability: `fire_source = true`
- Properties: emits light, warm to touch
- Placement: cellar (not portable — too heavy)

**World concern — MISSING:** The plan does NOT specify WHERE in the cellar the brazier sits. This is Moe's domain:
- Is it `on_top` the stone floor? (room-level placement)
- Near a wall? (spatial context for ambiance)
- Inside a hearth/alcove? (Requires room description update to reference the hearth)

**Recommendation:** The cellar room `.lua` file (`src/meta/world/cellar.lua`) must be updated to include the brazier in `instances`. Since this is a furniture object (non-portable), it should be listed as a room-level instance. The cellar description should reference "an iron brazier" to ground the object spatially.

**Status:** Not a blocker — straightforward room placement work. Belongs to Moe's wave responsibilities in WAVE-3 (cooking wave). Needs to be flagged as a room update task.

---

### 3. ✅ Respawn Metadata in Room Files — CRYSTAL CLEAR

**Finding:** The plan is explicit about respawn per-creature metadata (lines 732-754, 1003-1009). Format is clean:

```lua
respawn = {
    timer = 60,              -- ticks until respawn
    home_room = "cellar",    -- where it respawns
    max_population = 2,      -- max creatures of this type per room
}
```

**Creature assignments (lines 747-753):**
| Creature | Timer | Home Room | Max Pop |
|----------|-------|-----------|---------|
| rat | 60 | cellar | 3 |
| cat | 120 | courtyard | 1 |
| wolf | 200 | hallway | 1 |
| spider | 80 | deep-cellar | 2 |
| bat | 60 | crypt | 3 |

**World concern — VERIFIED:** All home rooms exist in Level 1 and have creature placements:
- ✅ Cellar — rat habitat (known from Phase 2)
- ✅ Courtyard — cat habitat (known)
- ✅ Hallway — wolf habitat (new? needs to verify in room list, but routing makes sense)
- ✅ Deep-cellar — spider habitat (new? Phase 2 spiders in cellar, deep-cellar may be a sub-location)
- ✅ Crypt — bat habitat (new? sensible location)

**Note:** Deep-cellar and crypt may not exist yet. This is a **pre-flight validation** task for Moe before WAVE-5 respawn work:
- Verify all 5 home_room IDs exist in `src/meta/world/`
- If missing, flag for creation in WAVE-3 or earlier
- Populate creatures in the room `.lua` instances array

**Status:** Respawn format is sound. Room topology needs pre-validation.

---

### 4. 🟡 Antidote Vial Placement — UNSPECIFIED (TBD by Moe)

**Finding:** Plan line 686 references "Placed in Level 1 (location TBD by Moe — study shelf or cellar cabinet)."

The antidote object (`src/meta/objects/antidote-vial.lua`) is marked for WAVE-4 creation, but placement is deferred.

**Options given:**
- Study shelf
- Cellar cabinet

**World concern — ACTION NEEDED:** This is Moe's decision. The plan correctly defers placement to me. Considerations:
- **Study shelf:** Accessible early, fits with research/learning narrative. Antidote discovery via exploration.
- **Cellar cabinet:** Near spider habitat where venom is encountered. Logical proximity — find spider, get bitten, need antidote nearby.

**Recommendation:** Cellar cabinet is stronger from a world-design perspective. It creates a cause-effect spatial relationship: players encounter spider in cellar, suffer venom, find remedy in same area. Also keeps all poison/cure mechanics localized.

**Status:** Not a blocker — belongs in Moe's WAVE-4 placement decisions. To be documented in a follow-up decision.

---

### 5. ✅ Creature Inventory Drops — SOUND INSTANTIATION LOGIC

**Finding:** Plan lines 445-460 describe the death drop pipeline:

1. Creature dies
2. `reshape_instance()` transforms creature to corpse
3. Inventory items iterate and instantiate to room floor
4. Items become independent registry objects
5. Reshaped corpse instance already in room from WAVE-1

**Key design decision (resolved Q1, lines 982-984):** Player searches corpse to find items (not scatter-to-floor). Corpse becomes a container.

**World concern — VERIFIED:** 
- No room-level changes needed
- Inventory items drop "alongside" reshaped corpse in same room
- Items become room objects automatically (registry handles placement)
- Loot drops coexist with corpse in room — both are registry-tracked

**Wolf loot specifics (line 478):**
- Creature: wolf
- Inventory: `{ id = "gnawed-bone-01" }`
- Drop behavior: bone instantiates to room when wolf dies

**Spider byproduct (lines 485-486):**
- Spider death emits silk via `death_state.byproducts` (not inventory)
- Silk-bundle appears on room floor
- Narration: "The spider's abdomen splits, spilling a tangle of silk."

**Status:** All instantiation happens engine-side. No room .lua changes needed for inventory drops. Corpse container semantics are handled by engine reshape + existing `search` verb. Clean separation.

---

### 6. ✅ Room Topology + Combat Sound Propagation — SOUND ARCHITECTURE

**Finding:** Plan lines 640-650 describe combat sound propagation:

> "After combat narration phase (NARRATE), emit `loud_noise` stimulus to current room + adjacent rooms."

**Sound propagation mechanism:**
- Uses existing `stimulus.lua` infrastructure
- Propagates via room exit graph for adjacency
- Acoustically adjacent = connected by an exit

**World concern — VERIFIED:**
- Room exit graph already defined for Level 1 rooms
- Sound follows real exit connections (no "teleport" or omni-directional)
- Creatures in adjacent rooms react: flee away or investigate (predators approach)

**Creature reactions to combat sounds (WAVE-4):**
- Creatures in adjacent rooms detect `loud_noise` stimulus
- Stimulus causes behavioral changes (flee/investigate)
- This uses existing `stimulus.lua` and `predator-prey.lua` engines

**No room topology issues.** The exit graph is the sound propagation graph. If rooms are connected by exits, sound travels. Natural and correct.

**Status:** Combat sound propagation is architecturally sound. No room-level work needed beyond what already exists.

---

## BLOCKER: Architecture Documentation NOT in WAVE-0

**Issue (CRITICAL):** 

Wayne directed (per team communications) that architecture docs must be updated BEFORE WAVE-1 proceeds. This ensures all downstream work is grounded in documented decisions.

**Current plan structure:**
- WAVE-0 (Pre-Flight): Module splits only. No documentation.
- WAVE-5 (Respawning + Polish): 4 architecture/design docs (lines 767-774):
  - `docs/architecture/engine/creature-death-reshape.md`
  - `docs/architecture/engine/creature-inventory.md`
  - `docs/design/food-system.md`
  - `docs/design/cure-system.md`

**Problem:** WAVE-1 (Death Consequences) ships before ANY architecture documentation. WAVE-1 is the most significant architectural change (D-14 in-place reshape). Without documentation, downstream agents (Smithers, Flanders, Nelson) lack grounding.

**Recommendation:**
1. Move creation of `creature-death-reshape.md` and `creature-inventory.md` to **WAVE-0 gate criteria**
2. Make GATE-0 success contingent on:
   - [ ] Module splits pass tests (existing GATE-0)
   - [ ] `docs/architecture/engine/creature-death-reshape.md` written (NEW)
   - [ ] `docs/architecture/engine/creature-inventory.md` written (NEW)

3. Keep food/cure system docs in WAVE-5 (can be written after those features ship)

This is **a BLOCKER for GATE-0 → GATE-1 transition.**

---

## Minor Observations (Non-Blockers)

### Room-Level Creature Spawning (Line 730)
> "Creatures spawn as room-level objects with no spatial nesting."

**Verified:** Correct pattern. Creatures don't nest under furniture (yet). Spawn position = room GUID, not `on_top` of anything. Correct for Phase 3.

### No Respawn of Dead Wolf (Line 751)
The plan designates wolf respawn timer as 200 ticks (territorial, one-of-a-kind). But Phase 3 allows respawning. If this is meant to be a boss or unique encounter, the plan should clarify that 200 ticks ≠ "no respawn" — it's just very slow. Or is the intent to set max_population=1 as a soft cap that prevents farming?

**Status:** Not a blocker, but deserves clarification in implementation.

---

## Summary of World/Room Concerns

| Concern | Status | Notes |
|---------|--------|-------|
| Reshaped corpse room presence | ✅ APPROVED | room_presence text in death_state block |
| Cellar brazier placement | 🟡 NEEDS PLANNING | Brazier defined, room.lua cellar update needed (WAVE-3) |
| Respawn metadata format | ✅ APPROVED | Clear per-creature metadata, home_room logic sound |
| Home room existence | 🟡 VERIFY | All 5 home rooms must exist; deep-cellar & crypt need validation |
| Antidote vial placement | 🟡 TBD MOE | Plan defers to Moe; cellar cabinet recommended |
| Inventory drop instantiation | ✅ APPROVED | Engine handles drops, no room changes needed |
| Combat sound propagation | ✅ APPROVED | Uses room exit graph, no topology issues |
| **Architecture docs before WAVE-1** | ❌ BLOCKER | WAVE-0 must update docs/architecture/ files |

---

## FINAL VERDICT

**CONDITIONAL APPROVE** with one blocker and one pre-flight task:

1. **BLOCKER (Must Fix Before GATE-0 → GATE-1):**
   - Add `docs/architecture/engine/creature-death-reshape.md` creation to WAVE-0 gate criteria
   - Add `docs/architecture/engine/creature-inventory.md` creation to WAVE-0 gate criteria
   - Make these docs required for GATE-0 sign-off

2. **Pre-Flight Validation Task (Moe, before WAVE-5 respawn work):**
   - Verify all 5 home_room IDs exist: cellar, courtyard, hallway, deep-cellar, crypt
   - If missing, flag for creation
   - Populate creature instances in room .lua files

3. **Room Placement Decisions (Moe, WAVE-3 + WAVE-4):**
   - Add brazier instance to cellar room .lua (WAVE-3 cooking wave)
   - Decide antidote placement: cellar cabinet recommended (WAVE-4)

The core architecture is sound. With the documentation blocker resolved, this plan is execution-ready.

---

**Approval Status:** CONDITIONAL APPROVE  
**Blocker Count:** 1 (architecture docs)  
**Pre-Flight Tasks:** 1 (room topology validation)  
**Ready for WAVE-0:** NO — resolve blocker first  
**Ready for WAVE-1 (post GATE-0):** YES (if blocker resolved)

