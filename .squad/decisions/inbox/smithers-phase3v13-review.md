# Smithers Parser/UI Review: NPC Combat Phase 3 v1.3

**Reviewer:** Smithers (UI Engineer)  
**Date:** 2026-08-17  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase3.md` (v1.3)  
**Scope:** Parser and UI concerns for death reshape, food system, combat polish  

---

## VERDICT: ⚠️ CONDITIONAL APPROVE

Phase 3 plan is architecturally sound for parser/UI scope. **BLOCKER identified:** Architecture documentation requirement missing from WAVE-0 gate.

---

## Detailed Findings

### 1. Cook Verb Handler ✅ APPROVED

**Section:** WAVE-3, Cook Verb (line 532-548)

**Strengths:**
- Clean pattern: `handlers["cook"] = function(ctx, noun)` mirrors existing `sew` handler in crafting.lua
- Alias chain complete: `cook`, `roast`, `bake`, `grill` (line 545-546) — standard culinary verbs
- Recipe sourced from object metadata (`obj.crafting.cook`), not handler logic (Principle 8 ✓)
- Works identically for both standalone food objects and reshaped creature instances

**Parser Integration:** 
- Embedding index updates will be needed for new aliases (planned in WAVE-3 at line 898)
- Synonym table already tracks `cook` aliases across all variants
- No disambiguation issues: "cook" unambiguously routes to food objects via sensory/containment context

**Status:** ✅ APPROVED — follows established patterns, aliases complete

---

### 2. Eat Handler Extensions ✅ APPROVED

**Section:** WAVE-3, Eat Handler (line 552-558)

**Raw Meat Messaging:**
- Raw meat eating allowed with consequences (line 556): `obj.cookable == true && obj.edible != true && obj.food.raw == true`
- Warning message sequence clear: 
  1. First: sensory text (`obj.on_taste`) 
  2. Then: flavor description ("The raw flesh tastes foul")
  3. Finally: consequence narration ("Your stomach rebels immediately")
- Food poisoning inflicted via existing injury system (lines 556-557)

**Gating Logic:**
- Raw grain rejection (line 556): If `cookable == true && raw != true`, reject with hint
- Excellent UX: hint guides player to cooking action ("Try cooking it first")

**Food Effects Pipeline:**
- Integrates with existing `effects` processing (line 557)
- Additive (doesn't replace existing eat logic) — runs AFTER success (per risk register, line 935)
- Supports: `narrate` (message), `heal` (HP restore), `inflict_injury` (food poisoning)

**Status:** ✅ APPROVED — messaging is clear, gating prevents bad states

---

### 3. Kick Verb Routing ✅ APPROVED

**Section:** WAVE-4, Kick Verb (line 642-651)

**Alias Chain:**
```lua
handlers["kick"] = handlers["hit"]
```
Simple and correct. The alias chain is:
1. `kick` → routes to `hit` handler (line 648)
2. Combat pipeline resolves naturally from there
3. Player's hand inventory (weapons) automatically chosen in combat resolution

**Parser Perspective:**
- No new parser logic needed
- `kick rat` unambiguous: creature is only sensible target for combat verb in visible scope
- Embedding index will learn `kick` → combat context automatically (neural semantic matching in Tier 2)

**Status:** ✅ APPROVED — minimal, correct, integrates seamlessly

---

### 4. Witness Narration for Death/Reshape ⚠️ CONDITIONAL APPROVE

**Section:** WAVE-1, Reshape Instance (line 228-315)

**Death Narrative Flow:**
1. Creature's health reaches 0 → `reshape_instance()` called (engine-side)
2. Instance template switches: "creature" → "small-item" or "furniture"
3. Sensory properties overwritten from `death_state` block
4. Instance remains in room with new properties

**Player Sees:**
- Combat narration ends, creature is dead (output from combat handler)
- Instance is now reshaped to dead form with `room_presence` text
- Next `look` shows dead creature by new `room_presence` value (e.g., "A dead rat lies crumpled on the floor" from rat.lua death_state, line 339)

**Gap Identified:** 
No explicit **reshape narration** specified. What text does player see when the instance transforms? Current plan assumes:
- Combat handles narration of death → "The rat collapses, dead"
- Reshape is silent/internal
- On next `look`, player sees the new `room_presence` text

**Recommendation:**
- If instant feedback needed: Add `reshape_narration` optional field to death_state: `reshape_narration = "The rat's body goes rigid, cooling in place."` 
- If "look" discovery is sufficient: Current design is fine (less spammy)

**Status:** ⚠️ CONDITIONAL APPROVE — Design works but needs clarity on whether reshape produces its own narration or is silent.

---

### 5. Parser Disambiguation — GUID Switching ✅ APPROVED

**Section:** WAVE-1, Death Reshape (line 228-315)

**Core Challenge:** Same GUID has different keywords before/after death
- **Living rat:** keywords = `{"rat", "rodent", "vermin"}`
- **Dead rat:** keywords = `{"dead rat", "rat corpse", "rat carcass", "dead rodent", "rat"}`

**Parser Handles This Correctly:**
1. **Tier 1 (Exact Alias):** Lookup `dead rat` → finds reshaped instance (since keywords include both live+dead terms)
2. **Tier 2 (Embedding):** Semantic match on "dead" vs "living" disambiguates if ambiguous
3. **Tier 4 (Context):** Recent commands ("attack rat", then "take rat") inform which form is expected
4. **Tier 5 (Fuzzy):** Typos like "ded rat" still resolve to correct instance

**Keyword Strategy in death_state (line 338):**
```lua
keywords = {"dead rat", "rat corpse", "rat carcass", "dead rodent", "rat"}
```
Includes full spectrum. Creature registry lookups work because:
- GUID uniqueness maintained (same instance)
- Keywords are merged at runtime on reshape (death_state keywords replace living keywords)
- Parser doesn't know about GUID switching — just sees updated keyword set

**No Parser Changes Needed:** ✅ Registry already handles this via instance attribute updates. Principle 8 preserved.

**Status:** ✅ APPROVED — Parser handles GUID reuse elegantly via keyword updates

---

### 6. Combat Sound Propagation Narration ⚠️ CONDITIONAL APPROVE

**Section:** WAVE-4, Combat Sound Propagation (line 683-691)

**API Design Specified at Line 691:**
> "Smithers provides the narration API; Bart calls it from the engine."

**Issue:** No narration API defined in the plan.

**Current Gap:**
- Bart's code emits `loud_noise` stimulus (engine-side)
- Creatures in adjacent rooms react (flee/investigate)
- **But:** What narration reaches the player?

**Missing Specification:**
1. If player is in combat room: "The air fills with the sounds of combat. A distant door creaks — something flees."
2. If player is in adjacent room: "You hear violent sounds from the [adjacent room name]. Something crashes."
3. If player is far away: No narration (sound doesn't propagate that far)

**Recommendation:**
- Define `emit_combat_sound(room, intensity, narration)` in `combat/narration.lua`
- Parameters: `room` (origin), `intensity` (0-10), `narration` (witness text template)
- Call from combat FSM when combat round completes
- Supports: attractor feedback loop (player hears danger → creates drama)

**Status:** ⚠️ CONDITIONAL APPROVE — Architecture is sound, but narration API specification is incomplete. Recommend adding to WAVE-4 scope before GATE-4.

---

## ⚠️ BLOCKER: Architecture Documentation Not Scheduled in WAVE-0

**Critical Issue Identified:**

The plan schedules architecture documentation in **WAVE-5** (Brockman, section line 767-774):
- `docs/architecture/engine/creature-death-reshape.md`
- `docs/architecture/engine/creature-inventory.md`
- `docs/design/food-system.md`
- `docs/design/cure-system.md`

**Your Directive:** Wayne directed architecture docs must be updated in WAVE-0 before proceeding to WAVE-1.

**Current Plan Gap:** 
- WAVE-0 (line 177-219) lists module splits, GUID pre-assignment, test verification
- GATE-0 criteria (line 205-218) includes no documentation checkpoints
- No Brockman assignments in WAVE-0 dependency graph

**Impact:**
- If docs are needed before WAVE-1, GATE-0 criteria must include: "All architecture docs stubbed/completed"
- Brockman must be added to WAVE-0 parallel tracks alongside Bart/Nelson
- Current v1.3 GATE-0 timeline (estimated at line 41 as "1 day") may extend to 1.5-2 days

**Recommendation:**
1. Confirm with Wayne: Are architecture docs (creature-death-reshape.md, creature-inventory.md) prerequisites for WAVE-1?
2. If YES: Add Brockman documentation task to WAVE-0 with GATE-0 checklist: "All 2 architecture docs drafted"
3. If NO (docs can ship in WAVE-5): Clarify in decisions.md that documentation is a WAVE-5 delivery

**Status:** 🛑 BLOCKER — Cannot approve WAVE-0 launch without clarifying this requirement.

---

## Summary Assessment

| Category | Status | Notes |
|----------|--------|-------|
| Cook verb aliases | ✅ APPROVED | Pattern matches `sew`, aliases complete |
| Eat raw meat messaging | ✅ APPROVED | Clear UX, consequences well-defined |
| Kick routing | ✅ APPROVED | Minimal, correct, no parser impact |
| Death reshape narration | ⚠️ CONDITIONAL | Design sound; clarify if reshape is silent or narrated |
| Parser GUID switching | ✅ APPROVED | Registry handles elegantly |
| Combat sound narration API | ⚠️ CONDITIONAL | Architecture sound; API spec incomplete |
| **Architecture docs in WAVE-0** | 🛑 **BLOCKER** | Required by Wayne directive but missing from plan |

---

## Action Items for Plan Revision

1. **URGENT:** Clarify with Wayne whether architecture docs (creature-death-reshape.md, creature-inventory.md) are WAVE-0 prerequisites
2. If YES: Revise WAVE-0 to include Brockman documentation task
3. Define reshape narration behavior (silent vs. narrated)
4. Specify `emit_combat_sound()` API for WAVE-4 narration integration
5. Update GATE-0 and GATE-4 criteria with doc/API specifications

---

**Reviewer Recommendation:** 
🟠 **Conditional Approve for WAVE-1+ scope** (cook, eat, kick, sound, death reshape are parser/UI sound) 
🛑 **Hold WAVE-0 launch** until architecture documentation requirement is clarified and integrated into the plan.

**Signature:** Smithers, UI Engineer  
**Charter:** `.squad/agents/smithers/charter.md`
