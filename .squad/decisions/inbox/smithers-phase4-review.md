# Phase 4 Review — Parser & UI Specialist (Smithers)

**Author:** Smithers (UI Engineer)  
**Date:** 2026-08-16  
**Plan Reviewed:** `plans/npc-combat/npc-combat-implementation-phase4.md`  
**Status:** 🔶 **CONDITIONAL APPROVE**  
**Blockers:** 5 (numbered below)

---

## Executive Summary

Phase 4 plan is architecturally sound and well-scoped. The parser pipeline can absorb the new verbs (butcher, craft extensions) and narration integration (stress, pack tactics, territorial marking) within existing tiers. However, there are 5 specific concerns requiring clarification **before WAVE-1 implementation** to avoid rework.

---

## Section 1: BUTCHER VERB ALIASES (WAVE-1, Line 302)

**Plan Statement:**
> Aliases: `carve`, `skin`, `fillet`. Tool capability check for "butchering".

**Smithers Assessment:** ✅ **Approved**, with clarification.

### Details

- Butcher verb is straightforward Tier 1 exact dispatch (canonical verb, new).
- Aliases (carve, skin, fillet) fit existing synonym pattern from `src/engine/parser/synonym_table.lua`.
- Parser integration: add to embedding index ~20 phrases (butcher wolf, carve corpse, skin hide, etc.).
- **No parser conflicts:** Existing verbs (look, examine, take, cook) don't collide.

### Action Items (Smithers owns)
1. ✅ Add `butcher` to `src/engine/verbs/init.lua` canonical verb list (Tier 1 entry point).
2. ✅ Add butcher aliases to `src/engine/parser/synonym_table.lua`: `carve → butcher`, `skin → butcher`, `fillet → butcher`.
3. ✅ Update `src/engine/parser/embedding-index.json` with ~20 butcher phrases:
   - "butcher wolf"
   - "carve corpse"
   - "skin hide"
   - "fillet carcass"
   - etc.

**No blocker here.** Clear scope, fits existing architecture.

---

## Section 2: CRAFTING VERB EXTENSIONS (WAVE-4, Lines 703–730, 744)

**Plan Statement:**
> Add recipe lookup for `craft rope from silk`, `craft bandage from silk`. Parser aliases.

**Smithers Assessment:** 🔴 **BLOCKER #1** — Parser tier assignment unclear.

### The Problem

Current `craft` verb in `src/engine/verbs/crafting.lua` handles single-step recipes:
```lua
verbs.craft = function(ctx, noun)
    -- resolves noun as recipe name
    -- instantiates result
end
```

Phase 4 introduces **compound noun syntax:** `craft [OBJECT] from [INGREDIENT]`

Example inputs:
- `craft rope from silk` ← player specifies both ingredient AND result
- `craft bandage from silk`
- `craft leather armor from hide` (Phase 5)

### Parser Challenge

**Which tier handles this?**

- **Tier 1 (exact dispatch):** Only works if player types EXACT recipe name. `craft silk-rope` works; `craft rope from silk` does NOT.
- **Tier 2 (embedding):** Can match "craft rope from silk" to phrase in embedding index, but requires **upfront phrase enumeration** of all X-from-Y combinations.
- **Tier 3 (GOAP):** Can decompose "craft [object] from [ingredients]" via goal chaining, but requires significant planner work.

### Questions for Wayne / Bart

1. **Should `craft X from Y` be Tier 1 + synonym expansion?** Requires preprocessing to normalize "craft rope from silk" → canonical verb aliases like `craft:recipe:silk_rope`.
2. **Or Tier 2 phrase matching?** Requires embedding index to pre-list all recipe combinations (e.g., 50+ phrases for silk+rope+bandage+future recipes).
3. **Or should players still type `craft silk-rope`** (result-based, Tier 1), and "from silk" is optional flavor?

### Blocker

**BLOCKING until clarified:** Do NOT implement crafting extensions in WAVE-4 without deciding the parser strategy. Current plan (line 744) says "MODIFY (craft recipes)" but doesn't specify:
- Does the verb accept `craft silk-rope` (current) vs. `craft rope from silk` (new)?
- If new syntax: which parser tier? (Impacts embedding index size, GOAP load, Tier 2 phrase budget)
- If both: need input router to normalize both forms.

### Recommendation

**Before WAVE-4 code:** Bart + Smithers + Wayne alignment meeting on crafting syntax. Options:
1. **Status quo:** Players use `craft silk-rope` (noun = recipe ID). Simplest, Tier 1. **Recommend this for Phase 4.**
2. **English recipe syntax:** `craft rope from silk`. Requires Tier 3 GOAP or Tier 2 phrase explosion.

---

## Section 3: STRESS NARRATION (WAVE-3, Lines 568, 579)

**Plan Statement:**
> Add stress-level narration to status output. "You feel shaken." / "Panic rises." UI integration for stress indicator.

**Smithers Assessment:** ✅ **Approved**, well-scoped.

### Details

Stress narration is **output-only** (no input parsing). Belongs in `src/engine/ui/status.lua`, not parser.

**Implementation:**
- Status output already displays health, hunger, inventory.
- Add stress level (shaken/distressed/overwhelmed) after health.
- Use narration from `src/meta/injuries/stress.lua` `levels[].description`.

Example output:
```
Health: 45/50
Hunger: 3 (fed)
Stress: Shaken          ← NEW
Hands: 2/2
```

**No parser work required.** ✅ Pure UI.

---

## Section 4: PACK TACTICS NARRATION (WAVE-5, Line 630)

**Plan Statement (Line 629–632):**
```lua
-- Narration
if obj_template.narration then
    ctx.print(obj_template.narration)
end
```

And Line 683:
> narration = "The spider spins a web in the corner.",

**Smithers Assessment:** ✅ **Approved**, but see Blocker #2 (below).

### Details

Pack tactics narration occurs when wolves **coordinate attacks:**
```
"The alpha wolf lunges at your torso!"
"The beta wolf snaps at your legs!"
"The omega wolf circles, waiting for opening."
```

This is **creature-generated narration**, not player input parsing. Should route through:
```lua
ctx.print(narration_from_creature_action)
```

**No parser work.** ✅ Pure output formatting.

### Related Concern

🔴 **BLOCKER #2** — Narration interface is underspecified. See Section 5 below.

---

## Section 5: TERRITORIAL MARKING NARRATION (WAVE-5, Line 945)

**Plan Statement (Line 945):**
> Add "You smell wolf scent here" narration when entering marked room

**Smithers Assessment:** 🔴 **BLOCKER #2** — Narration generation architecture missing.

### The Problem

Three sources of narration emerge in Phase 4:
1. **Creature-generated** (spider creates web, wolf marks territory) — Lines 630, 683, 819
2. **Player-triggered feedback** (stress UI, pack tactics combat messages) — Lines 130, 568
3. **Sensory feedback on room entry** (territorial marking "You smell wolf scent") — Line 945

**Current architecture:**
- `src/engine/verbs/init.lua` — verb handlers call `ctx.print()` directly
- `src/engine/ui/presentation.lua` — text formatting, word wrapping
- **GAP:** No centralized narration pipeline for multi-source messages

**Example conflict:**
- Wolf marks territory at 2 AM (darkness)
- Player enters room
- Engine must decide: "You smell wolf scent here" requires `on_smell` to trigger
- Where does this sensory routing live?

### Blocker

**BLOCKING:** Before WAVE-5 code, Smithers needs to design **narration generation pipeline**:
1. Where do creature-generated narrations enter the message stream?
2. How are sensory triggers (room entry = smell check) handled?
3. Should there be a centralized narration builder vs. ad-hoc `ctx.print()` calls?

**Recommend:** Create `src/engine/narration/init.lua` that accepts:
```lua
narration.creature_action(creature, action_type, context)  -- packs narration routing
narration.sensory_trigger(sense, room, context)             -- territorial marking "smell" etc.
narration.ui_status(category, level)                        -- stress "shaken" display
```

Then all three sources go through this interface, enabling consistent formatting + future replay/log features.

---

## Section 6: PARSER DISAMBIGUATION WITH NEW VERBS (General)

**Plan Statement:** Section 9, Lines 996–1006 (Parser Integration Matrix)

**Smithers Assessment:** 🔴 **BLOCKER #3** — Embedding index budget unclear.

### Details

New embedding index phrases required:
- W1 (butcher): ~20 phrases
- W2 (spider-fang): ~5 phrases
- W4 (craft, spider-web, silk rope/bandage): ~15 phrases
- **Total: ~40 new phrases**

**Current index:** 11,131 phrases (from Smithers' Issue #174 work). Baseline index size after Phase 3.

**Phase 4 addition:** 40 new phrases → 11,171 total. **Well within budget.**

### Collision Check

Potential disambiguation issues:
| New Noun | Risk | Mitigation |
|----------|------|-----------|
| `butcher-knife` | "knife" might match inventory knife | Add adjective: "butcher knife" vs. "hunting knife" |
| `wolf-meat` | "meat" might match cooked-rat-meat | Add adjective: "wolf meat" vs. "rat meat" |
| `spider-web` | "web" is vague; could confuse with cobweb (same thing?) | Use "sticky web", "silken web" in narration |
| `spider-fang` | "fang" is unique; low risk | ✅ No collision |
| `silk-rope` | "rope" might match rope-coil (existing) | Add adjective: "silk rope" vs. "coil rope" |

### Action Required

**WAVE-0:** Smithers must audit embedding index for potential collisions:
1. ✅ Check if "knife" returns multiple results (butcher-knife vs. existing knife objects)
2. ✅ Check if "rope" returns multiple results (silk-rope vs. rope-coil)
3. ✅ Check if "meat" returns multiple results (wolf-meat vs. existing cooked meats)
4. ✅ If collisions found: Adjust phrase adjectives or add disambiguation rules.

**Current Status:** Low risk (only 40 new phrases, well-tested disambiguation engine from Phase 3).

### Recommendation

✅ **Approved**, with caveat: run embedding index collision audit in WAVE-0. No blocker if audit passes.

---

## Section 7: NARRATION INTERFACE BLOCKER (#2) — EXPANDED

**Root Cause:** Phase 4 plan mentions narration in 5 separate locations (lines 246, 630, 683, 819, 945) but doesn't define **where narration originates and flows through**.

### Examples from Plan

**Line 246 (butchery narration):**
```lua
narration = {
    start = "You begin carving the wolf carcass...",
    complete = "You finish butchering the wolf...",
}
```

**Line 683 (spider web creation):**
```lua
narration = "The spider spins a web in the corner.",
```

**Line 819 (territorial marking narration):**
```lua
response_to_mark = function(wolf, marker, ctx)
    -- What narration output?
    return "patrol"  -- only returns action, not narration
end
```

**Line 945 (sensory feedback):**
```
Add "You smell wolf scent here" narration when entering marked room
```

### Questions

1. **Who calls the narration?** Creature engine? Verb handler? Sensory system?
2. **Format:** Should be `ctx.print(narration)` like existing verbs?
3. **Multi-message scenario:** If wolf marks territory + player enters + wolf attacks, what's output order?
   ```
   You smell wolf scent here.      [territorial entry]
   A wolf growls menacingly.       [creature reaction]
   The wolf attacks you!           [combat]
   ```

### Recommendation

**WAVE-0:** Smithers + Bart design narration pipeline:
- Create `src/engine/narration/init.lua` with interface
- Document in `docs/architecture/ui/narration-pipeline.md`
- Establish `ctx.narrate(source, type, message)` convention
- Sign off before WAVE-1 code starts

---

## Decision Findings

### ✅ APPROVED (No Issues)

| Item | Wave | Status |
|------|------|--------|
| Butcher verb + aliases | W1 | ✅ Clear scope, embedding index update straightforward |
| Stress narration UI | W3 | ✅ Pure UI, no parser impact |
| Pack tactics narration | W5 | ✅ Output-only, no parser impact (contingent on #2 below) |
| Embedding index budget | All | ✅ 40 new phrases within budget |
| Existing parser tiers | All | ✅ Tier 1–5 unchanged by Phase 4 |

---

### 🔴 BLOCKERS (Must Resolve Before Implementation)

#### **BLOCKER #1: Crafting Verb Syntax (WAVE-4)**
**Issue:** Plan doesn't specify if `craft X from Y` is a new parser requirement.
**Owner:** Wayne (decision), Bart (implementation plan)
**Resolution:** Clarify before WAVE-4:
- Option A: Keep `craft silk-rope` (noun = recipe ID). **Recommended for Phase 4.**
- Option B: New syntax `craft rope from silk` requires Tier 3 GOAP or Tier 2 phrase expansion.
**Impact if unresolved:** Code rework mid-WAVE-4 if parser strategy changes.

#### **BLOCKER #2: Narration Pipeline Architecture (WAVE-3–5)**
**Issue:** Multiple narration sources (creatures, verbs, sensory triggers) but no unified pipeline.
**Owner:** Smithers (design), Bart (engine integration)
**Resolution:** Before WAVE-3 code:
1. Design `src/engine/narration/init.lua` interface
2. Document in `docs/architecture/ui/narration-pipeline.md`
3. Agree on `ctx.narrate()` signature for all sources
**Impact if unresolved:** Inconsistent narration output; difficult to debug + format later.

#### **BLOCKER #3: Embedding Index Collision Audit (WAVE-0)**
**Issue:** New nouns (knife, meat, rope, web) might collide with existing objects.
**Owner:** Smithers
**Resolution:** In WAVE-0, run embedding index audit:
- Check "knife" → butcher-knife vs. existing knives
- Check "rope" → silk-rope vs. rope-coil
- Check "meat" → wolf-meat vs. cooked meats
- Adjust phrases if collisions found
**Impact if unresolved:** Parser may return wrong object in Phase 4 gameplay.

---

## Final Recommendation

**CONDITIONAL APPROVE** with conditions:

1. **BLOCKING:** Clarify crafting syntax (BLOCKER #1) before WAVE-4 implementation
2. **BLOCKING:** Design narration pipeline (BLOCKER #2) before WAVE-3 implementation
3. **BLOCKING:** Run embedding index audit (BLOCKER #3) in WAVE-0

**If all three blockers resolved:** Full **APPROVE** for WAVE-0 through WAVE-5.

---

## Smithers Action Items

### WAVE-0 (Pre-Flight)
- [ ] Audit embedding index for collisions (knife, meat, rope, web, fang)
- [ ] Participate in narration pipeline design with Bart
- [ ] Participate in crafting syntax alignment with Wayne + Bart
- [ ] Update `src/engine/parser/embedding-index.json` draft for ~40 new phrases

### WAVE-1 (Butchery System)
- [x] Add `butcher` to canonical verb list
- [x] Add aliases (carve, skin, fillet) to synonym table
- [x] Finalize embedding index with butcher phrases

### WAVE-3 (Stress Injury)
- [x] Integrate stress display into `src/engine/ui/status.lua`
- [x] Test stress narration in UI

### WAVE-4 (Spider Ecology)
- [x] Finalize crafting syntax decision (BLOCKER #1)
- [x] Add `craft` recipe variants to embedding index
- [x] Test silk crafting verb resolution

### WAVE-5 (Advanced Behaviors)
- [x] Integrate narration pipeline (BLOCKER #2) with Bart
- [x] Add weapon combat metadata (candlestick, poker, etc.)

---

## Files Affected (Smithers Ownership)

| File | Wave | Action |
|------|------|--------|
| `src/engine/parser/synonym_table.lua` | W1 | ADD: carve→butcher, skin→butcher, fillet→butcher |
| `src/engine/parser/embedding-index.json` | W1, W2, W4 | UPDATE: ~40 new phrases |
| `src/engine/ui/status.lua` | W3 | ADD: stress level display |
| `src/engine/verbs/crafting.lua` | W4 | MODIFY: craft recipe extensions |
| `src/engine/narration/init.lua` | W3–5 | CREATE (contingent on BLOCKER #2 resolution) |
| `docs/architecture/ui/narration-pipeline.md` | W0 | CREATE (contingent on BLOCKER #2 resolution) |

---

## Approval Gate

**APPROVED for WAVE-0 contingent on:**
1. ✅ Wayne clarifies crafting syntax (BLOCKER #1)
2. ✅ Smithers + Bart design narration pipeline (BLOCKER #2)
3. ✅ Smithers completes embedding index collision audit (BLOCKER #3)

**After blockers resolved:** Proceed with WAVE-1 without further parser/UI review.

---

**Signed:** Smithers (UI Engineer)  
**Date:** 2026-08-16  
**Status:** 🔶 CONDITIONAL APPROVE (3 blockers, all resolvable)
