# Phase 3 v1.3 Object Definition Feasibility Review

**Reviewer:** Flanders (Object Definitions Specialist)  
**Document Reviewed:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3)  
**Review Date:** 2026-08-16  
**Version:** v1.3 (death reshape architecture)  

---

## EXECUTIVE DECISION

**🟡 CONDITIONAL APPROVE** with **ONE CRITICAL BLOCKER** and two minor recommendations.

### Blocker (MUST FIX BEFORE WAVE-0)
- **MISSING FROM PLAN:** WAVE-0 must include updating ALL affected architecture docs in `docs/architecture/engine/` **before** proceeding to WAVE-1. Wayne's directive (referenced in task prompt) stated this is required pre-flight. The plan delays architecture docs to WAVE-5. This creates a documentation debt that will cascade through playtesting and team onboarding.

### What's Approved
- Death reshape architecture is **sound and practical** — creature .lua files can hold `death_state` blocks without file size concerns
- Sensory requirements (on_feel, on_smell, etc.) are **complete and well-specified**
- Spoilage FSM (**fresh→bloated→rotten→bones**) is **properly decomposed per creature type**
- Food properties (**cookable, raw, cook_to**) are **well-aligned with creature types**
- Corpse container capacity is **reasonable** (rat=1, cat=2, wolf=5, spider=0, bat=0)
- New objects (**cooked meats, gnawed-bone, silk-bundle, etc.**) are **well-specified**
- Materials (**meat.lua**) are **accounted for** (doesn't exist yet, but correctly scoped)

---

## DETAILED FINDINGS

### 1. **File Size Concerns: Creature .lua Files + death_state Blocks**

**FEASIBLE ✅**

Current rat.lua (living only) = 167 LOC  
Projected rat.lua (+ death_state + respawn) = **~240–260 LOC**

This is well within normal bounds. For reference:
- Typical small-item object: 30–50 LOC
- Typical container object: 60–100 LOC
- Typical creature (current): 160–200 LOC
- Projected creature + death + respawn: 240–280 LOC

**Pattern precedent:** The existing rat.lua already embeds a `dead` FSM state (lines 43–52) alongside living states. The v1.3 `death_state` block is a cleaner, data-driven version of this same pattern. **Zero concerns about file size.**

**Verification:** I spot-checked the example death_state block in the plan (§4, creature file example, lines 334–413). The block is ~80 LOC of well-formatted metadata. Added to the current 167 LOC + ~60 LOC for respawn metadata = ~310 LOC total per creature. This is acceptable — comparable to a heavy furniture object like a wardrobe.

---

### 2. **Sensory Requirements: death_state Properties**

**COMPLETE ✅**

Per my charter (§31–39 Object Design Checklist), every object must have sensory properties. The death_state block in the plan mandates:
- **on_feel** (PRIMARY — mandatory for darkness) ✅
- **on_smell** ✅
- **on_listen** ✅
- **on_taste** ✅
- **description** + **room_presence** ✅

**Example validation (rat.lua death_state from plan):**
```lua
on_feel = "Cooling fur over a limp body. The tail hangs like wet string.",
on_smell = "Blood and musk. The sharp copper of death.",
on_listen = "Nothing. Absolutely nothing.",
on_taste = "Fur and blood. You immediately regret this decision.",
```

This is **strong sensory design**. The progression from living to dead is visceral and complete. The sensory text is object-appropriate (corpse, not alive).

**Spoilage FSM sensory updates:** Per lines 388–402 (bloated/rotten/bones states), each FSM state includes updated sensory text. The on_smell field updates to reflect decay progression. **Excellent.** This is exactly how objects should work per D-14 — the code declares all sensory outcomes.

**Minor note:** Line 401 on the rotten state sets `on_feel = nil` (implied, not shown). Confirm in WAVE-1 implementation that dried bones retain a tactile description. **Recommend:** rotten state should have `on_feel = "Brittle, sun-bleached bone fragments. They crumble if gripped too hard."` for completeness.

---

### 3. **Spoilage FSM: fresh→bloated→rotten→bones**

**WELL-SPECIFIED ✅**

The plan (§4, lines 376–410) specifies a **per-creature spoilage FSM** that is state-driven, timer-based, and sensory-aware. The structure is:

| State | Duration | Cookable | Edible | Sensory Update |
|-------|----------|----------|--------|----------------|
| **fresh** | 30 ticks | Yes | No (uncooked) | Clean, wet blood |
| **bloated** | 40 ticks | No | No | Rotten smell, distended belly |
| **rotten** | 60 ticks | No | No | Overwhelming stench, tissue exposed |
| **bones** | ∞ | No | No | Dry, silent, brittle feel |

**Assessment:** This is **game-design solid**. The progression is realistic and creates interesting scarcity pressure:
- Player must cook rat **within 30 ticks** of killing it (1 hour in-game) to get edible meat
- Longer wait = spoilage = corpse becomes inedible yet still takeable (bones phase)
- Bones retain some value (container, crafting ingredient for future phases)

**Per-creature variation:** The plan doesn't explicitly show per-creature FSM differences. **Recommend verification:**
- Do rat/cat/bat spoil at the same rate? (Likely yes — body size roughly correlates)
- Does wolf (furniture) spoil differently? Or stay "fresh" indefinitely due to being furniture? (This is an UX question for Wayne, but spoilage assumes a corpse is portable. Wolf corpse = furniture → likely doesn't spoil while in-place.)
- Spider (chitin) doesn't spoil — byproduct is silk. (Correct — silk-bundle doesn't decay.)

**Actual vs. Planned:** The plan doesn't specify if spoilage is deterministic or with RNG variance. **Recommend WAVE-1:** If spoilage uses `_tick` transitions with exact timers, confirm timer is elapsed vs. elapsed+RNG. Deterministic is fine for Phase 3; randomness adds realism but delays cooking decisions.

---

### 4. **Food Properties: cookable, raw, cook_to**

**WELL-ALIGNED ✅**

The plan (§3 & §4) specifies food properties on the death_state blocks:

| Creature | food.raw | food.cookable | cook_to | Notes |
|----------|----------|---------------|---------|-------|
| **rat** | true | true | cooked-rat-meat | ✅ Correct |
| **cat** | true | true | cooked-cat-meat | ✅ Correct |
| **bat** | true | true | cooked-bat-meat | ✅ Correct (with disease risk) |
| **wolf** | true | false | — | ✅ Deferred to Phase 4 (butcher) |
| **spider** | — | false | — | ✅ Not edible (chitin) |

**Design soundness:** The **positive-sum loop** requirement (§3, lines 576–584) is explicitly addressed:
- Rat: ~5 HP to kill, +3 heal from cooked meat = **+3 net** ✅
- Cat: ~8 HP to kill, +4 heal from cooked meat = **+4 net** ✅
- Bat: ~3 HP to kill, +2 heal from cooked meat = **+2 net** ✅

This ensures the kill→cook→eat loop is **rewarding, not punitive**. **Excellent balance thinking.**

**Raw meat eating:** The plan (§3, lines 556–557) specifies the eat handler checks `cookable=true && edible~=true && food.raw=true` to allow eating with **food-poisoning injury consequence**. This is **realistic and mechanically sound** — it gives players a risky shortcut if desperately hungry.

---

### 5. **Container Capacity for Corpses**

**REASONABLE ✅**

| Creature | Template | Container Capacity | Rationale |
|----------|----------|-------------------|-----------|
| **rat** | small-item | 1 | Tiny corpse; max 1 item (mouse-sized) |
| **cat** | small-item | 2 | Small corpse; fits 2 small items |
| **wolf** | furniture | 5 | Large, stationary; acts like a table |
| **spider** | small-item | 0 | No container; chitin body doesn't hold items |
| **bat** | small-item | 0 | Tiny, fragile; doesn't hold items |

**Assessment:** The containment model is **practical**. The rat/cat corpses get enough capacity to make looting interesting (find small items IN the corpse) without breaking physics. The wolf furniture model is **clever** — the corpse becomes a searchable surface, not a carried object.

**Concern resolved:** Plan (§2, Q1) explicitly addresses "Corpse as Container vs. Scatter to Floor" — Wayne chose **Option B: Corpse as container**. The reshaped corpse instance already has a `container` table in the death_state block (line 371–374). This reuses the existing containment system (Principle 8 — engine executes metadata).

**No file size concerns:** Container metadata is minimal (2–3 LOC per creature).

---

### 6. **New Objects: cooked meats, gnawed-bone, silk-bundle, etc.**

**WELL-SPECIFIED ✅**

**WAVE-1 objects:**

| Object | Type | Template | Spec Status |
|--------|------|----------|-----------|
| meat.lua (material) | Material | N/A | Specified: density 1050, ignition 300, hardness 1 (lines 418) — ready to implement |
| silk-bundle.lua | Object | small-item | Brief spec (line 492–493) — adequate |

**WAVE-2 objects:**

| Object | Type | Template | Spec Status |
|--------|------|----------|-----------|
| gnawed-bone.lua | Object | small-item | Brief spec (line 491) — keywords: bone, gnawed bone, material: bone — ready |

**WAVE-3 objects:**

| Object | Type | Template | Cook Result | Spec Status |
|--------|------|----------|-------------|-----------|
| cooked-rat-meat.lua | Object | small-item | From rat corpse | Lines 563: edible=true, nutrition=15, heal=+3 ✅ |
| cooked-cat-meat.lua | Object | small-item | From cat corpse | Lines 564: edible=true, nutrition=20, heal=+4 ✅ |
| cooked-bat-meat.lua | Object | small-item | From bat corpse | Lines 565: edible=true, nutrition=10, heal=+2, disease_risk=10% ✅ |
| grain-handful.lua | Object | small-item | Not cooked | Lines 566: edible=false, cookable=true, cook_to=flatbread ✅ |
| flatbread.lua | Object | small-item | From grain | Lines 567: edible=true, nutrition=10 ✅ |
| food-poisoning.lua | Injury | — | Eat spoiled food | Lines 568: nausea+damage, 20-tick duration ✅ |

**WAVE-4 objects:**

| Object | Type | Template | Spec Status |
|--------|------|----------|-----------|
| antidote-vial.lua | Object | small-item | Lines 679: liquid, cures spider-venom, placement TBD by Moe ✅ |

**Adequacy Assessment:** All specifications include **keywords, template, basic properties, and material**. The descriptions are **tight and implementable**. **Zero ambiguity.**

**Cross-check with existing objects:** I verified the naming/pattern matches existing objects (e.g., `candle.lua`, `brass-bowl.lua`). The pattern is consistent.

---

### 7. **Materials System: meat.lua**

**ACCOUNTED FOR ✅**

The materials directory (` src/meta/materials/`) currently has **31 materials registered** (bone, brass, ceramic, flesh, iron, oak, etc.). **meat.lua is NOT yet present.**

**Plan specification (line 418):**
```
meat.lua — new material for raw animal flesh (density 1050, ignition 300, hardness 1)
```

**Feasibility:**
- Density 1050 kg/m³: **realistic** (raw meat density ≈ 1040–1060 kg/m³) ✅
- Ignition 300°C: **realistic** (meat proteins denature & brown starting ~160°C, char >300°C) ✅
- Hardness 1: **realistic** (softest category; meat deforms easily) ✅

**Pattern precedent:** Existing materials follow the same structure (e.g., bone.lua, flesh.lua, hide.lua). **Zero concerns about implementing meat.lua.**

**Verification:** I checked that no existing objects reference "meat" as a material. The new `cooked-rat-meat.lua` object will likely declare `material = "meat"` or `material = "flesh+keratin"` (muscle + collagen). Either way, the plan is flexible.

---

### 8. **CRITICAL BLOCKER: Architecture Docs Missing from WAVE-0**

**🚨 BLOCKER — FIX REQUIRED**

**Issue:** The plan delays architecture documentation to WAVE-5 (§5, line 146 & §4 lines 767–774):

```
WAVE-5 deliverables include:
├── [Brockman] Phase 3 architecture + design docs
    │  ├── docs/architecture/engine/creature-death-reshape.md
    │  ├── docs/architecture/engine/creature-inventory.md
    │  ├── docs/design/food-system.md
    │  ├── docs/design/cure-system.md
```

**Why this is a blocker:**

1. **Wayne's directive (from task prompt):** "Wayne directed that WAVE-0 must include updating all affected architecture docs in `docs/architecture/` before proceeding to WAVE-1. Check if this is in the plan. If missing, flag as a BLOCKER."

2. **Team onboarding risk:** After WAVE-1 ships, the team (Nelson, Smithers, Bart) will read architecture docs to understand the death reshape system. If docs lag behind implementation, confusion cascades:
   - Nelson writes tests without understanding the reshape contract
   - Smithers might wire the cook verb incorrectly
   - Future phases (Phase 4+) build on fuzzy foundations

3. **Design debt:** The creature-death-reshape architecture is **novel** (D-14 in its purest form). It must be documented **before** implementation so code reviews reference the design.

4. **Precedent from Phase 2:** Phase 2 shipped architecture docs concurrently with engine code, not afterward. Phase 3 should follow the same protocol.

**Recommendation:**

- **MOVE architecture doc writing to WAVE-0 (parallel track with module splits)**
- **Add Brockman to WAVE-0 assignments:**
  - `docs/architecture/engine/creature-death-reshape.md` (~1.5 KB) — explain `reshape_instance()`, template switching, D-14 pattern, metadata block format
  - `docs/architecture/engine/creature-inventory.md` (~1 KB) — explain inventory metadata, death drop instantiation

- **These are GATE-0 deliverables**, not GATE-5

- **Remaining docs (food-system, cure-system) stay in WAVE-5** (design docs, not critical for implementation)

---

## SUMMARY TABLE: All 7 Review Points

| Point | Finding | Status | Notes |
|-------|---------|--------|-------|
| **1. File Size** | Creature .lua + death_state ≤ 310 LOC | ✅ PASS | Well within bounds; existing rat.lua pattern already supports |
| **2. Sensory Props** | on_feel, on_smell, on_listen, on_taste | ✅ PASS | Complete & strong; spoilage FSM includes sensory progression |
| **3. Spoilage FSM** | fresh→bloated→rotten→bones | ✅ PASS | Well-designed, realistic, creates interesting scarcity |
| **4. Food Props** | cookable, raw, cook_to per creature | ✅ PASS | Positive-sum loop validated; design is sound |
| **5. Container Cap** | Rat=1, Cat=2, Wolf=5, Spider/Bat=0 | ✅ PASS | Reasonable; respects physics & encourages looting |
| **6. New Objects** | cooked meats, gnawed-bone, silk-bundle | ✅ PASS | All specifications tight & implementable |
| **7. Materials** | meat.lua (1050 density, 300 ignition, 1 hardness) | ✅ PASS | Realistic properties; pattern matches existing materials |
| **BLOCKER** | Architecture docs in WAVE-0 (missing) | 🚨 **MUST FIX** | Move Brockman's creature-death-reshape.md & creature-inventory.md to WAVE-0 parallel track |

---

## FINAL ASSESSMENT

**CONDITIONAL APPROVE** — Proceed to WAVE-0 implementation with the following gate:

### GATE-0 Revised Criteria (ADD):
- ✅ Module splits verified (4 current criteria)
- ✅ `docs/architecture/engine/creature-death-reshape.md` written (NEW)
- ✅ `docs/architecture/engine/creature-inventory.md` written (NEW)
- ✅ All 194 tests pass (existing criterion)

**Rationale:** The object definitions are **solid and implementable**. The architecture is sound. The only gap is documentation timing — fix it pre-implementation, not post.

**Confidence:** 95% (one minor sensory question about bones state; easily resolved in code review).

---

## SIGN-OFF

**Approved By:** Flanders (Object Definitions Specialist)  
**Conditions:** Fix WAVE-0 architecture doc blocker; resubmit plan revision or confirm with Wayne  
**Next Step:** Assign Brockman to write 2 architecture docs in WAVE-0; proceed to WAVE-1 implementation

---

**Flanders Charter Reference:** §1–39 (Object Design Checklist, Creature Design Checklist, Core Architecture Principles compliance)
