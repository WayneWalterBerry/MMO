# Smithers — Phase 3 Plan Review (Parser/UI/Verb Perspective)

**Date:** 2026-08-16
**Reviewer:** Smithers (Parser & UI Engineer)
**Document:** `plans/npc-combat/npc-combat-implementation-phase3.md` v1.0
**Verdict:** ✅ **CONDITIONAL APPROVE**

---

## Summary

The Phase 3 plan is well-structured and demonstrates Bart learned from Phase 2 (proactive module split, GUID pre-assignment, backward-compatible opt-in patterns). My Smithers-owned deliverables (WAVE-3 cook verb, WAVE-4 kick alias + combat sound, WAVE-5 weapon metadata) are clearly scoped and follow established patterns. I have **zero blockers** but **five concerns** that need resolution before or during implementation.

---

## 1. Verb Additions — APPROVE with Concerns

### kick (WAVE-4) — ✅ Clean

The plan specifies `handlers["kick"] = handlers["hit"]` (~2 LOC in init.lua). This is exactly the alias pattern already used for punch/bash/bonk/thump/smack/bang/slap/whack/headbutt → hit. **No issues.** I'll add it at line ~481 alongside the existing `punch` alias.

### cook (WAVE-3) — ⚠️ CONCERN C-1: Missing Aliases in Handler Registration

The plan shows aliases `roast`, `bake`, `grill` on the handler in crafting.lua. Good. **Missing from the plan:**
- `sear` — natural cooking synonym
- `fry` — common player input

**Recommendation:** Add `sear` and `fry` as cook aliases. Low cost, prevents "fry rat" → "I don't understand." These are the kinds of inputs the parser benchmark catches.

### cook (WAVE-3) — ⚠️ CONCERN C-2: Empty Noun Error Message

The plan shows the `cook` handler body but doesn't specify the empty-noun error. The `sew` pattern uses `"Sew what? (Try: sew cloth with needle)"`. We need:
```lua
if noun == "" then
    print("Cook what? (Try: cook rat)")
    return
end
```
**Recommendation:** Plan should specify the empty-noun message. I'll implement following the `sew` pattern.

### loot — ✅ NOT a New Verb (Clarification)

Despite the task description mentioning "loot," the plan does NOT introduce a `loot` verb handler. WAVE-2's "Loot Drops" uses existing `take` and `search` verbs on corpse containers. The existing `search` handler in `sensory.lua` (lines 827+) already handles container contents. **This is correct — no new "loot" verb needed.**

If Wayne wants `loot` as a player-facing alias, I'd recommend `handlers["loot"] = handlers["search"]` as a trivial addition. Not a blocker.

---

## 2. Parser Integration — APPROVE with Concerns

### ⚠️ CONCERN C-3: Embedding Index Update Plan is Vague

Appendix B correctly identifies that embedding index updates are needed per wave. But the plan does NOT assign an owner for the embedding index rebuild. This is my domain.

**What's needed per wave:**
- **W1:** ~30 new phrases (5 dead creatures × 6 verb variants: examine, look at, take, feel, smell, taste)
- **W2:** ~12 new phrases (gnawed-bone, silk-bundle × 6 verbs)
- **W3:** ~40 new phrases (cooked-rat-meat, grain-handful, flatbread × 6 verbs, PLUS "cook X" phrases for all cookable objects)
- **W4:** Minimal (kick already routes to hit; antidote-vial ~6 phrases)
- **W5:** ~6 phrases (brazier if Q3=B)

**Total: ~90 new embedding index phrases.**

**Recommendation:** Assign embedding index updates to Smithers, parallel-tracked per wave. Add to Appendix B: "Owner: Smithers" column. Without index updates, Tier 2 matching won't find new objects — players typing "examine dead rat" will get nil until the index is updated.

### Synonym Table Updates

The plan doesn't mention `src/engine/parser/synonym_table.lua`. New mappings needed:
```lua
roast = "cook",
bake  = "cook",
grill = "cook",
sear  = "cook",
fry   = "cook",
```
Without these, Tier 2 will fail on "roast rat" because the embedding index uses canonical "cook" as the verb. The synonym table maps non-canonical verbs to canonical forms before Tier 2 scoring.

### Tier 1 Exact Dispatch — ✅ No Issues

`cook` will be registered as a handler, so Tier 1 exact dispatch will match "cook rat" directly. `kick` likewise routes via alias. No preprocess pipeline changes needed.

### GOAP / Context Window — ✅ No Issues

The `cook` verb requires `fire_source` tool. This is the same pattern as `light candle` requiring `fire_source`. GOAP (Tier 3) already handles prerequisite chaining for tool requirements. "Cook rat" → prerequisite: find fire source → "You need a fire source to cook this." No new GOAP rules needed.

---

## 3. Narration Quality — APPROVE

### Death Sequences

The plan leaves creature death narration to `mutations.die.message` on each creature file (Flanders' domain). This is correct — narration is data-driven per Principle 8. **My concern:** Flanders should follow the established combat narration style: second-person, sensory, anatomically descriptive, multi-sentence for major events. Example from existing narration.lua:

> "You drive your fist into your ribs. Air explodes from your lungs."

Death narration should match this register. Not a blocker — Flanders knows the style.

### Cooking Narration

The plan provides an excellent example:
> "You hold the rat over the flames. The fur singes away and the flesh darkens."

This matches the engine's established prose style perfectly. Multi-sentence, sensory (visual + tactile implied), second-person. ✅

### Error Messages

The plan specifies `fail_message_no_tool = "You need a fire source to cook this."` — follows standard error pattern ("You need Y to do X."). ✅

---

## 4. UI Impact — ✅ MINIMAL

### Status Bar — No Changes Needed

The status bar (`ui/status.lua`, 81 LOC) displays: level name, room name, game time, and health. Phase 3 adds no new status bar elements. Health already updates when injuries change. Stress injury effects are visible through the existing health display. **No status bar modifications required.**

### Inventory Display — No Changes Needed

Creature loot drops become standard room objects or container contents. The existing `inventory` and `search` verbs already handle display. Cooked food is a standard small-item. No inventory UI changes needed.

### ⚠️ CONCERN C-4: Spoilage State Visibility

Dead creature corpses have a spoilage FSM (fresh → bloated → rotten → bones). The plan doesn't specify how spoilage state is surfaced to the player. Options:
- Room presence text changes per state (best — data-driven via `states.{state}.room_presence`)
- Smell changes per state (good — `states.{state}.on_smell`)
- Visual description changes (good — `states.{state}.description`)

**Recommendation:** Ensure Flanders defines per-state `room_presence`, `description`, `on_smell`, and `on_feel` for each spoilage FSM state on the dead creature objects. The engine already renders state-specific text — no engine changes needed, but the object data must include it.

---

## 5. Restriction System — APPROVE with Concern

### ⚠️ CONCERN C-5: Stress `precise_actions` Restriction Scope Undefined for Cook

The stress injury restricts `precise_actions`. The existing `get_restrictions()` function merges all active injury restrictions into a flat table. Currently, `precise_actions` is checked by:
- `spider-venom.lua` (paralyzed state)
- `rabies.lua` (excitable + furious states)

**The plan doesn't specify which verbs check `precise_actions`.** If `cook` requires fine motor skills (holding food over flame), should stress block cooking? The plan says stress restricts `precise_actions` but doesn't list which Phase 3 verbs are "precise."

**Recommendation:** Define explicitly which verbs are precision-gated. My suggestion:
- `cook` → YES, precision-gated (handling food near fire while shaking is dangerous)
- `kick` → NO (gross motor, not precision)
- `eat` → NO (already has its own restriction check)
- `sew` → Already precision-gated (existing)

I'll implement the restriction check in the cook handler if Bart/Wayne confirms. Pattern is trivial:
```lua
local restricts = injury_mod.get_restrictions(ctx.player)
if restricts.precise_actions then
    print("Your hands are shaking too badly to cook safely.")
    return
end
```

---

## Blockers: NONE

## Concerns Summary

| ID | Severity | Wave | Description | Resolution |
|----|----------|------|-------------|------------|
| C-1 | Low | W3 | Missing `sear`/`fry` cook aliases | Add to alias list; I'll implement |
| C-2 | Low | W3 | Empty-noun error message not specified for cook | I'll follow `sew` pattern |
| C-3 | Medium | W1-W5 | Embedding index update ownership unassigned | Assign to Smithers per wave |
| C-4 | Medium | W1 | Spoilage state visibility not specified on dead creature objects | Ensure per-state sensory text in Flanders' object definitions |
| C-5 | Low | W4 | `precise_actions` scope undefined for new verbs | Define precision-gated verb list |

---

## Smithers' Deliverables Confirmed

| Wave | Task | Est. LOC | Risk |
|------|------|----------|------|
| W3 | `cook` verb handler + aliases in crafting.lua | ~55 | ⚠️ crafting.lua hits ~684 LOC (629+55). Flag for split. |
| W3 | Cookable check + food effects in survival.lua eat handler | ~30 | Low |
| W3 | Embedding index: food keywords (~40 phrases) | ~40 phrases | Low |
| W4 | `kick` alias in init.lua | ~2 | Zero |
| W4 | Combat sound emission in combat/init.lua | ~15 | Low |
| W4 | Synonym table update (roast/bake/grill/sear/fry → cook) | ~6 | Zero |
| W5 | Weapon combat metadata on existing objects | ~15 | Low |
| W1-W5 | Embedding index updates per wave | ~90 phrases total | Medium (must track) |

**Note on crafting.lua LOC:** The risk register (Section 8) correctly flags this — cook adds ~55 LOC to a 629 LOC file → ~684 LOC. I concur with flagging for split in WAVE-5 or Phase 4 pre-flight. Not a blocker for Phase 3.

---

**Verdict: ✅ CONDITIONAL APPROVE** — No blockers. Resolve C-3 (embedding index ownership) before WAVE-1 starts. Other concerns can be resolved during implementation.
