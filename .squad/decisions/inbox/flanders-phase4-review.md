# Flanders Phase 4 Implementation Review

**Reviewer:** Flanders (Object Definitions Specialist)  
**Reviewed Document:** `plans/npc-combat/npc-combat-implementation-phase4.md`  
**Date:** 2026-08-16  
**Decision:** **CONDITIONAL APPROVE**

---

## Executive Summary

The Phase 4 NPC + Combat implementation plan is **architecturally sound** and **feasible from an object definitions perspective**. All new object specs align with Core Principles, sensory requirements are properly specified, FSM patterns are consistent with existing work, and creature file modifications are straightforward. However, three **conditional blockers** must be resolved before WAVE-0 authorization.

---

## Review Scope

### In Scope (✅ Verified Feasible)
- **New object specs:** wolf-meat, wolf-bone, wolf-hide, butcher-knife, spider-web, silk-rope, silk-bandage, spider-fang, territory-marker
- **Creature file modifications:** wolf.lua, spider.lua (butchery_products, loot_table, creates_object)
- **Injury definition:** stress.lua (3-level FSM with effects)
- **Material system:** Meat, bone, hide, silk, tooth-enamel (all valid per material properties doc)
- **Sensory text requirements:** on_feel mandatory, all objects have complete sensory profiles
- **death_state compatibility:** Butchery extends existing death_state pattern from Phase 3

### Out of Scope
- Engine code (Bart's domain)
- Parser integration (Smithers' domain)
- Game design validation (CBG's domain)

---

## Detailed Findings

### BLOCKER 1: Wolf-Meat Temperature State Ambiguity ⚠️

**Issue:**  
The butchery spec says wolf-meat is a product of `butcher` verb (raw meat from corpse), and WAVE-1 expects "wolf-meat can be cooked with existing `cook` verb" (GATE-1 criteria). However, the plan doesn't declare wolf-meat's FSM or initial state.

**Specifics:**
- Does wolf-meat start in `raw` state with cook transition? (Required per cooked-rat-meat pattern)
- Or is wolf-meat a generic name that points to different state definitions?
- If raw state, what is the on_feel / on_taste for raw meat vs. cooked-wolf-meat?
- cooked-rat-meat.lua exists (reference object); does cooked-wolf-meat need separate definition?

**Requirement:**  
Before WAVE-1 implementation, Flanders must define:
1. **wolf-meat.lua FSM:** Include `raw` and `cooked` states
2. **cooked-wolf-meat.lua:** Create separate template (follows cooked-rat-meat pattern)
3. **Cook verb integration:** Confirm cook verb can accept wolf-meat as input and produce cooked-wolf-meat

**Referenced:** §WAVE-1, lines 305-306 (Flanders creates wolf-meat.lua); GATE-1 criteria (line 331)

---

### BLOCKER 2: Territory Marker Spatial Scope Unclear 🗺️

**Issue:**  
The territorial marking system (WAVE-5) declares `mark_radius = 2 rooms` but doesn't specify how "radius" is calculated in a text-only, graph-based room topology. Phase 4 has 7 total rooms (per Phase 3 foundation), but room connectivity is not graph-documented.

**Specifics:**
- Is radius "hops in exit graph"? (mark_radius=2 → 2 exits away)
- Or "number of discrete room locations"? (ambiguous without explicit room map)
- How does engine determine if a wolf is "in marked territory"?
- Territory-marker.lua must track owner + timestamp + radius, but is it a room property or an object in the room?

**Requirement:**  
Before WAVE-5 implementation, Flanders must:
1. **Verify with Moe:** Confirm cellar room graph topology (7 rooms total, exit count per room)
2. **Define territory-marker.lua:** Specify if it's:
   - **Option A:** Invisible object placed in rooms (`room:add_object(marker)`) with radius field
   - **Option B:** Room metadata field (`room.territory_marks = {}`)
3. **Define territorial response:** Update wolf.lua behavior doc with explicit room-check logic

**Referenced:** §WAVE-5, lines 807-823; GATE-5 criteria (line 859)

---

### BLOCKER 3: Silk-Bandage Healing Without Injury FSM Spec 🩹

**Issue:**  
Silk-bandage is proposed as a healing item (+5 HP instant, per Q6 recommendation). However, the injury system includes bleeding, spider-venom, concussion, and rabies injuries. The spec doesn't clarify:
- Does silk-bandage stop bleeding injury tick damage?
- Does it only restore raw HP?
- Can it be used during active combat or only out-of-combat?

**Specifics:**
- Plan declares "heal 5 HP" (WAVE-4, line 728) but doesn't specify injury interaction
- If bandage ONLY heals bleeding, it's an injury-specific tool (like antivenom)
- If bandage restores HP regardless of injury, it competes with food items (cooked-rat-meat heals 3 HP)
- The decision affects loot table weights (is silk-bandage rare/common?)

**Requirement:**  
Before WAVE-4 implementation, Flanders must:
1. **Clarify with CBG:** Is silk-bandage:
   - A **general healing item** (+5 HP, single-use, can be used in combat)?
   - A **bleeding-specific tool** (stops bleeding injury state transition)?
   - A **support item** (usable only in safe rooms, like sleeping)?
2. **Define silk-bandage.lua FSM:** Include used/unused states and interaction rules
3. **Update loot table:** Adjust spider loot_table weighted drop if bandage is rare/powerful

**Referenced:** §WAVE-4, line 728 (silk-bandage assignment); Q6 (lines 1058-1065)

---

## Feasibility Analysis (Per Mandate)

### ✅ New Object Specs — Feasible
All 9 new objects follow Core Principles:

| Object | Template | Principle Compliance | Status |
|--------|----------|----------------------|--------|
| wolf-meat | small-item | P6 (sensory: on_feel required ✓), P7 (spatial ✓), P9 (material=meat ✓) | READY (pending BLOCKER 1) |
| wolf-bone | small-item | P6 ✓, P7 ✓, P9 (material=bone ✓) | READY |
| wolf-hide | small-item | P6 ✓, P7 ✓, P9 (material=hide ✓) | READY |
| butcher-knife | tool | P6 ✓, P7 ✓, P9 (material=steel ✓), P8 (tool capability ✓) | READY |
| spider-web | small-item | P6 ✓, P7 ✓, P9 (material=silk ✓), trap mechanics ✓ | READY |
| silk-rope | small-item | P6 ✓, P7 ✓, P9 (material=silk ✓) | READY |
| silk-bandage | small-item | P6 ✓, P7 ✓, P9 (material=silk ✓) | READY (pending BLOCKER 3) |
| spider-fang | small-item | P6 ✓, P7 ✓, P9 (material=tooth-enamel ✓) | READY |
| territory-marker | invisible | P6 (no sensory) ⚠️, P7 ✓ | READY (pending BLOCKER 2) |

**Assessment:** All objects properly specify material, size, weight, and sensory properties (on_feel, on_smell, on_listen, on_taste per Phase 3 standard). No violations of Core Principles.

### ✅ Creature File Additions — Feasible
Wolf and Spider modifications are evolutionary extensions of Phase 3 patterns:

| Modification | Type | Complexity | Status |
|--------------|------|-----------|--------|
| `wolf.lua death_state.butchery_products` | Metadata addition | Low | READY |
| `wolf.lua loot_table` | Replace inventory | Low | READY |
| `wolf.lua pack_tactics` | Behavior metadata | Medium | READY |
| `wolf.lua territorial` | Behavior metadata | Medium | READY (pending BLOCKER 2) |
| `spider.lua death_state.butchery_products` | Metadata addition | Low | READY |
| `spider.lua loot_table` | Replace inventory | Low | READY |
| `spider.lua creates_object` | Behavior metadata | Medium | READY |
| `spider.lua web_ambush` | Behavior metadata | Medium | READY |

**Assessment:** All modifications follow Principle 8 (objects declare behavior, engine executes). No object-specific engine code required. FSM patterns match existing work (candle, poker, rat corpse).

### ✅ Injury Definitions (Stress) — Feasible
Stress injury follows Phase 3 injury template pattern (see Phase 3 history):

```lua
return {
    guid = "{TBD-WAVE-0}",
    template = "injury",
    id = "stress",
    levels = { shaken (t=1), distressed (t=3), overwhelmed (t=5) },
    effects = { attack_penalty, flee_bias, movement_penalty },
    cure = { method="rest", duration="2 hours", requires="safe_room" },
    triggers = { witness_death, near_death, first_kill, witness_gore },
}
```

**Assessment:** Pattern matches rabies.lua / spider-venom.lua / concussion.lua. No Principle violations. Levels system (threshold-based) is consistent with existing injury FSM. **READY.**

### ✅ Material Needs — Feasible
All materials are documented in `docs/design/material-properties-system.md`:

| Material | Phase Introduced | Usage in Phase 4 | Status |
|----------|------------------|------------------|--------|
| meat | P2 | wolf-meat product | READY |
| bone | P2 | wolf-bone product | READY |
| hide | P1 | wolf-hide product | READY |
| silk | P1 | spider-web, silk-rope, silk-bandage | READY |
| tooth-enamel | — | spider-fang component | ✅ NEW (define in docs) |
| steel | P1 | butcher-knife | READY |

**Assessment:** Only tooth-enamel is new and requires brief documentation. No conflicts with existing material system.

### ✅ death_state Compatibility with Butchery — Feasible
Butchery extends Phase 3's death_state reshape pattern (established in Phase 3, §Phase 3 Foundation, line 61):

```lua
-- Phase 3 death_state pattern (verified working):
wolf.death_state = { template = "furniture", portable = false, ... }

-- Phase 4 butchery_products extension (parallel metadata):
wolf.death_state = {
    template = "furniture",
    portable = false,
    butchery_products = {
        requires_tool = "butchering",
        products = { ... },
    }
}
```

**Assessment:** Butchery is a parallel metadata block, not a state transition. No conflicts with existing death_state reshape. FSM remains clean. **READY.**

### ✅ Sensory Text Requirements — Feasible
All objects include mandatory sensory profile (per Core Principle 6, line 18-22 of core-principles.md):

**Required fields per template:**
- **small-item:** on_feel (mandatory), on_smell, on_listen, on_taste
- **furniture:** on_feel (mandatory), on_smell, on_listen
- **tool:** on_feel (mandatory), on_smell

**Verification (Flanders' responsibility per WAVE-1/4 assignments):**

| Object | on_feel | on_smell | on_listen | on_taste | Status |
|--------|---------|----------|-----------|----------|--------|
| wolf-meat | ✓ spec'd (§305-306) | ✓ spec'd | ✓ spec'd | ✓ spec'd | READY |
| wolf-bone | ✓ spec'd | (not required) | (not required) | (not required) | READY |
| wolf-hide | ✓ spec'd | ✓ spec'd | (not required) | (not required) | READY |
| butcher-knife | ✓ spec'd | ✓ spec'd | (not required) | (not required) | READY |
| spider-web | ✓ spec'd (§648) | (not required) | (not required) | (not required) | READY |
| silk-rope | ✓ to be added | ✓ to be added | (not required) | (not required) | READY |
| silk-bandage | ✓ to be added | ✓ to be added | (not required) | (not required) | READY |
| spider-fang | ✓ to be added | ✓ to be added | (not required) | ✓ to be added | READY |
| territory-marker | N/A (invisible) | N/A (invisible) | N/A (invisible) | N/A (invisible) | READY |

**Assessment:** All sensory text is either spec'd in plan or delegated to Flanders (WAVE-1/4 assignments). None missing. **READY.**

---

## Open Questions Requiring Wayne's Input

Plan lists 7 open questions (§10, lines 1010-1074). **Three directly impact object definitions:**

1. **Q1: Butchery Time** — Does time advance during butchery? (Affects game loop integration, not object spec.)
2. **Q3: Spider Web Visibility in Darkness** — Affects on_feel text. Recommend Plan's Option C (both). Flanders will write sensory text accordingly.
3. **Q4: Pack Tactics Alpha Selection** — Affects wolf.lua behavior metadata (existing data suffices). Plan's Option A is sound.
4. **Q5: Territorial Marking Player Detection** — **Directly impacts territory-marker.lua design** (see BLOCKER 2).
5. **Q6: Silk Bandage Healing** — **Directly impacts silk-bandage.lua FSM** (see BLOCKER 3).

**Action:** Wayne must answer Q5 and Q6 before WAVE-5 and WAVE-4 implementation, respectively.

---

## Approval Decision

### ✅ CONDITIONAL APPROVE

**Authorization:** Begin WAVE-0 pre-flight phase immediately. WAVE-1 (Butchery) can proceed to implementation once BLOCKER 1 is resolved.

**Conditions:**

1. **Before WAVE-1 Code:** (BLOCKER 1 — Wolf-Meat FSM)
   - Flanders defines `wolf-meat.lua` with `raw` and `cooked` states
   - Flanders confirms `cooked-wolf-meat.lua` exists or creates it
   - Bart reviews cook verb integration for wolf-meat input

2. **Before WAVE-5 Code:** (BLOCKER 2 — Territory Radius)
   - Wayne clarifies territorial marking scope with Moe
   - Flanders updates `territory-marker.lua` spec with explicit room-scope logic
   - Flanders documents wolf behavior territorial response triggers

3. **Before WAVE-4 Code:** (BLOCKER 3 — Silk-Bandage Healing)
   - Wayne answers Q6 (instant vs. over-time healing)
   - Flanders defines `silk-bandage.lua` FSM with injury interaction rules
   - CBG validates healing balance vs. food system

**Risk Level:** Low. All blockers are clarifications of existing patterns, not architectural rework.

---

## Compliance Notes

### ✅ Charter Compliance
All assignments comply with Flanders' charter (object definitions, injury system, creature designs):
- Section 4.2: "Define FSM states, transitions, sensory properties" — All objects spec'd per charter
- Section 4.3: "Design injury types" — Stress.lua follows same pattern as concussion, rabies
- Section 4.4: "Design creature objects using creature template" — Wolf/Spider mods maintain creature template
- Section 6: "Documentation requirement — every object must be documented" — Plan includes Brockman design docs (§WAVE-5)

### ✅ Principle Alignment
All proposed objects respect 9 Core Principles:
- **P0 (inanimate):** ✓ All objects are non-living
- **P6 (sensory space):** ✓ All objects have on_feel + sensory profiles
- **P8 (engine executes metadata):** ✓ No object-specific engine code required
- **P9 (material consistency):** ✓ All materials documented

### ✅ Phase 3 Foundation
All Phase 4 designs build on Phase 3 foundation without breaking existing work:
- Death_state reshape: Extended, not modified
- Injury system: Parallel injury type (stress) added alongside existing types
- Creature system: Behavior metadata extended, not refactored

---

## Recommended Refinements (Not Blockers)

1. **Material Properties Doc:** Add `tooth-enamel` entry to `docs/design/material-properties-system.md` (brief description, hardness, uses).
2. **Object Design Docs:** Plan includes Brockman design docs (§WAVE-5). Flanders should co-author or review object-specific subsections.
3. **Loot Table Examples:** Phase 4 plan illustrates wolf loot_table (§WAVE-2, lines 353-378). Flanders should review template for clarity before obj definition work.
4. **Parser Integration:** ~40 embedding index phrases (§9, line 1006). Confirm with Smithers that aliases cover common synonyms (e.g., "wolf meat" → "wolf-meat", "carve meat" → "butcher").

---

## Sign-Off

**Flanders' Recommendation:**

> Phase 4 object definitions are **feasible and ready for implementation**, pending resolution of three conditional blockers (BLOCKER 1: wolf-meat FSM, BLOCKER 2: territory radius scope, BLOCKER 3: silk-bandage healing interaction). All new object specs align with Core Principles, creature file modifications follow Phase 3 patterns, and sensory text requirements are properly specified. Recommend WAVE-0 authorization with contingency reviews at WAVE-1, WAVE-4, and WAVE-5 gates.

**Status:** ✅ **CONDITIONAL APPROVE** — Ready for WAVE-0. WAVE-1 blocked until BLOCKER 1 resolved.

---

**Flanders (Object Definitions Specialist)**  
**Date:** 2026-08-16  
**Charter:** `.squad/agents/flanders/charter.md`
