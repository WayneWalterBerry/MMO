# Design Review: NPC Combat Phase 3 Implementation Plan v1.3
## Comic Book Guy (CBG), Creative Director

**Date:** 2026-03-27  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3 — death reshape architecture)  
**Review Scope:** Game design mechanics, food economy, combat-loot patterns, respawning, template switching

---

## VERDICT: **CONDITIONAL APPROVE** ⚠️

The architecture change is SOLID from a game design perspective — death-state reshaping is elegant and strengthens D-14. The food economy is well-balanced. BUT: **CRITICAL BLOCKER on WAVE-0 identified.**

---

## CRITICAL BLOCKER

### **BLOCKER-1: Architecture Documentation MISSING from WAVE-0**

**Issue:** Wayne Berry directed (in v1.3 changelog) that "WAVE-0 must include updating all affected architecture docs in `docs/architecture/` **before proceeding to WAVE-1**."

**Plan Status:** The WAVE-5 section assigns Brockman 4 documentation files:
- `docs/architecture/engine/creature-death-reshape.md`
- `docs/architecture/engine/creature-inventory.md`
- `docs/design/food-system.md`
- `docs/design/cure-system.md`

**The Problem:** These are assigned to **WAVE-5 only** — AFTER respawning is done. Wayne's directive clearly states these must be in **WAVE-0, BEFORE WAVE-1 starts.** The plan violates this.

**Why This Matters:** 
- Bart will implement `reshape_instance()` in WAVE-1 without architecture docs explaining WHY it exists or HOW to use it
- Flanders will add `death_state` blocks to creature files without documented patterns
- Nelson's tests will be written to undocumented patterns
- Future developers will be confused about D-14 vs mutation vs reshape

**Fix Required (BLOCKER):** Move the 4 documentation files to **WAVE-0 assignments for Brockman**, specifically:
1. `docs/architecture/engine/creature-death-reshape.md` — explain the in-place reshape pattern, `reshape_instance()` function, why NOT `mutation.mutate()`, `death_state` metadata block format, GUID preservation
2. `docs/architecture/engine/creature-inventory.md` — inventory metadata format, death drop pipeline, containment reuse
3. `docs/design/food-system.md` — cook verb, edibility tiers, mutation chain (corpse→cooked meat), spoilage FSM, food effects
4. `docs/design/cure-system.md` — healing interactions metadata, cure eligibility, antidote pattern

Add Brockman to WAVE-0 assignments. Update GATE-0 criteria to include: `[ ] All 4 documentation files exist and are complete`.

---

## DESIGN REVIEW — CLEARED ISSUES

### 1. Food Economy: ✅ SOUND

**Analysis:**
The plan specifies kill→cook→eat loop must be **net-positive**:

| Creature | Damage to Kill | Cooked Nutrition | Heal Effect | Net HP | Verdict |
|----------|---|---|---|---|---|
| Rat | 5 HP | 15 | +3 heal | **+3 net** | ✅ Good |
| Cat | 8 HP | 20 | +4 heal | **+4 net** | ✅ Good |
| Bat | 3 HP | 10 | +2 heal | **+2 net** | ✅ Good |

**Design Assessment:**
- The numbers create player incentive: "Kill a rat, cook it, regain health" is a LOOP, not a dead-end
- This rewards skillful play: harder kills (cat) yield better loot
- Risk is baked in: bat meat carries disease risk even cooked (10% food-poisoning), so players must choose when it's worth it
- **Classic game design pattern:** This mirrors *Zork* style resource management (lamp oil preservation) and *Dwarf Fortress* food/water cycles

**Feedback:** Keep these numbers as-is. They're balanced.

---

### 2. Spoilage & Cooking Mechanics: ✅ WELL-DESIGNED

**Spoilage FSM on dead corpses:**
```
fresh (30 ticks) → bloated (40 ticks) → rotten (60 ticks) → bones (permanent)
```

- Fresh: cookable, edible (if user eats raw, risky)
- Bloated: cookable=false, edible=false (flavor/safety concern)
- Rotten: absolutely no (ew factor)
- Bones: skeletal remains, not edible, not cookable, but useful for crafting (Phase 4 bonus)

**Game Design Impact:**
- Creates **time pressure:** Player can't stockpile infinite rat corpses. They must cook them before they spoil.
- Educates player about real-world decay (bloated → rotten)
- Sets up Phase 4 crafting (bones → tools/decorations)

**Mechanics Check:**
- Sensory text updates per state (`on_smell = "Overwhelming rot"` in rotten state) — excellent, drives immersion
- Each state has distinct room_presence text — NPCs can see corpse decay without opening it

**Verdict:** Excellent design. No changes needed.

---

### 3. Template Switching (Creature→Object): ✅ D-14 ALIGNED

**Architecture Decision:**
Instead of swapping to a separate `dead-rat.lua` file (which would be mutation), creatures are **reshaped in-place** by applying a `death_state` metadata block from within the creature's own `.lua` file.

**Example (from plan):**
```lua
-- rat.lua contains BOTH living + dead forms
death_state = {
    template = "small-item",      -- reshape to small-item template
    name = "a dead rat",
    -- ... sensory, container, food, spoilage FSM metadata
}
```

**D-14 Analysis:**
- **Principle 1 Check:** Code IS the object definition ✅ — the creature file IS its death form
- **Principle 14 (D-14):** "Code mutation IS state change" ✅ — the instance literally changes shape
- **No File Swap:** Unlike `mutation.mutate()` (which loads a new .lua file), `reshape_instance()` transforms the existing instance
- **GUID Preservation:** Same creature GUID persists through death — this is **stronger than v1.2** which created new dead-creature GUIDs

**Comparison to v1.2 (old dead-creature files):**
- v1.2 approach: kill rat → `mutation.mutate("dead-rat.lua")` → separate file, new GUID tracking
- v1.3 approach: kill rat → `reshape_instance()` → same instance, same GUID, metadata overlay

**Verdict:** v1.3 is **significantly better design**. It aligns D-14 perfectly: the code literally becomes different, no abstraction layer. 5 fewer .lua files to maintain.

---

### 4. Combat-Loot Pattern with Reshaped Corpses: ✅ WORKS

**Design Pattern:**
1. Kill wolf → wolf instance reshapes to "furniture" template (too large to carry)
2. Wolf `death_state.container` metadata: `capacity = 5` (medium container)
3. Wolf drops gnawed-bone in inventory → bone appears on room floor
4. Player takes bone

**Container Mechanics Check:**
- Reshaped corpses CAN be containers ✅ — corpse has container metadata post-reshape
- Inventory items instantiate to room floor ✅ — not inside corpse (good: prevents "loot is hidden inside dead body")
- Dead wolf stays in room as furniture ✅ — can't carry it, but it blocks movement/is scenery

**Game Design Impact:**
- Wolf becomes a "loot anchor" — something that stays in the room, rewards exploration, can be examined
- Gnawed-bone becomes a crafting component (Phase 4 likely: tools, decorations)
- Multiple creatures in room don't create "inventory pile" problem — items scatter uniquely per corpse

**Verdict:** Clean pattern. No issues.

---

### 5. Creature Respawning Design: ✅ SENSIBLE

**Respawn Model:**
```lua
respawn = {
    timer = 60,              -- ticks between death and respawn
    home_room = "cellar",    -- where new instance spawns
    max_population = 3,      -- never more than 3 rats in cellar at once
}
```

**Respawn Rules (from plan):**
- Creature only respawns if **player is NOT in the home room** (prevents "spawn in player's face")
- Population cap prevents overrun (max_population check)
- Each creature type has independent timer

**Creature Respawn Config (good balance):**
| Creature | Timer | Home | Max Pop | Rationale |
|---|---|---|---|---|
| rat | 60 | cellar | 3 | Breed fast, plentiful |
| cat | 120 | courtyard | 1 | Solitary, territorial |
| wolf | 200 | hallway | 1 | Apex predator, rare |
| spider | 80 | deep-cellar | 2 | Web-builders, common |
| bat | 60 | crypt | 3 | Colony, nocturnal |

**Game Design Assessment:**
- **Extinction Prevention:** ✅ Players won't permanently deplete rats by killing them all (good)
- **Pacing:** Rats respawn faster (timer=60) than cats (timer=120) or wolves (timer=200) — mirrors real ecology
- **Room Ecology:** Each room has its own population ceiling — prevents hallway from becoming "wolf spawning factory"
- **Player Agency:** Player can manage creatures by respawn manipulation (e.g., staying out of cellar to let rats repopulate if food is low)

**Potential Issue (Minor - Not a Blocker):**
The plan says "Spawn position: room-level objects with no spatial nesting." This is correct for Phase 3, but flags a future consideration: Phase 4 creatures might spawn nested (e.g., "bat in chandelier"). The respawn metadata should future-proof for spawn_point metadata. **Recommendation (Phase 4 scope):** Add comment in `docs/architecture/engine/creature-respawning.md` (if it gets written in Phase 4) noting that room-level is v1 and spawn-point is future.

**Verdict:** Respawning is well-balanced. No changes needed for Phase 3.

---

## MECHANICAL CONSISTENCY CHECKS

### Raw Meat Consequences: ✅ RISKY BUT VIABLE

**Rule (from plan):**
- Eat raw meat (`food.raw == true` AND `food.edible != true`) → inflict food-poisoning injury
- Eat cooked meat (`food.edible == true`) → safe, nutrition effect

**Design Intent:** Player CAN eat raw rat corpse (desperate survival), but pays a cost (disease). This mirrors *Zork* danger-for-reward mechanics.

**Example Flow:**
1. Kill rat
2. `eat dead rat` (without cooking)
3. On-taste warning from sensory text
4. Food-poisoning inflicted (nausea + 20-tick duration)
5. Player learns: "Cook first or suffer"

**Verdict:** Good teaching mechanic. Reward is optional risk-taking. ✅

---

## CRITICAL QUESTION: Mutation Chain Clarity

**Pattern (from WAVE-3 section):**
- Reshaped creature (dead rat, `death_state.crafting.cook` declared) → `mutation.mutate()` → cooked-rat-meat.lua

**Question:** When player cooks a dead rat, does the engine call:
- `mutation.mutate(dead_rat_instance, "cooked-rat-meat.lua")` ✅ OR
- `reshape_instance(dead_rat_instance, cooked_recipe_metadata)` ❌

**Plan Answer (line 602):** "The cook verb reads from `obj.crafting.cook` (following the `sew` pattern). When cooking a reshaped corpse, `mutation.mutate()` IS used to transform the dead-rat instance into `cooked-rat-meat.lua` — this is a legitimate file-swap mutation."

**Design Assessment:** ✅ CORRECT. The cooked meat is a **genuinely new object type**, not a state of the corpse. File-swap mutation is appropriate here. The death_state reshape is a ONE-TIME in-place transform; the cook transform is a SECOND file-swap mutation. Two different patterns, both legitimate.

---

## SUMMARY OF FINDINGS

| Issue | Status | Severity | Resolution |
|-------|--------|----------|-----------|
| Architecture docs missing from WAVE-0 | BLOCKER | 🔴 Critical | Move Brockman's 4 docs to WAVE-0 before WAVE-1 starts |
| Food economy balance | ✅ Cleared | — | No changes needed |
| Spoilage & cooking mechanics | ✅ Cleared | — | No changes needed |
| Template switching (D-14 alignment) | ✅ Cleared | — | No changes needed |
| Combat-loot with corpse containers | ✅ Cleared | — | No changes needed |
| Creature respawning balance | ✅ Cleared | — | No changes needed |
| Raw meat consequences | ✅ Cleared | — | No changes needed |
| Mutation chain clarity | ✅ Cleared | — | No changes needed |

---

## FINAL RECOMMENDATION

**CONDITIONAL APPROVE** pending resolution of **BLOCKER-1**.

The game design is excellent. The in-place reshape pattern is a clean evolution of D-14. The food economy creates meaningful player choices. Respawning prevents extinction without trivializing resource scarcity. But the plan VIOLATES Wayne's explicit directive to document architecture in WAVE-0.

**Action Required Before WAVE-1:**
1. Assign Brockman to WAVE-0 documentation tasks (4 files)
2. Update GATE-0 criteria to include documentation gates
3. Ensure all 4 docs exist and are complete before any WAVE-1 code begins

Once this blocker is cleared, proceed with confidence.

---

**Signed:** Comic Book Guy (cbg)  
**Role:** Creative Director, Design Department Lead  
**Date:** 2026-03-27T{time}Z
