# Phase 5 Review — Smithers (Parser/UI Engineer)

**Reviewer:** Smithers  
**Date:** 2026-03-28  
**Plan:** `plans/npc-combat/npc-combat-implementation-phase5.md`  
**Review Scope:** Parser pipeline, verb dispatch, UI/narration, embedding index, room presence, error messaging, headless compatibility

---

## Executive Summary

Phase 5 plan is **well-structured and parser-UI aware**. Smithers tasks are clearly scoped across PRE-WAVE (bug triage), WAVE-1 (room presence + embedding updates), WAVE-2 (pack narration), and WAVE-3 (salt verb + aliases). **No blockers identified**; all parser touch-points are accounted for.

**Total Smithers scope:** ~180–250 LOC of new code + documentation updates.

---

## Detailed Review

### PRE-WAVE: Bug Triage

#### ✅ Silk Disambiguation Fix

**Status:** Good — clearly scoped.

- **Task:** Update `silk-bundle.lua` and `silk-rope.lua` keywords with distinct adjective prefixes
- **Parser touch:** Embedding index update if needed
- **Concern:** Plan mentions "Update embedding index **if needed**" — ambiguous. **RECOMMENDATION:** Make explicit: update embedding for any new keywords added to silk objects to prevent future Tier 2 collisions.
- **Headless:** N/A (no user-facing text change)

#### ✅ Craft Recipe Lookup Fix

**Status:** Good — verb ownership clear.

- **Task:** Debug recipe ID format in `src/engine/verbs/crafting.lua`
- **Parser touch:** None (recipe lookup is internal to verb handler)
- **Confidence:** High — consistent with Phase 4 verb ownership (Smithers)
- **Headless:** No impact on text output

#### ⚠️ Verb Aliases & Embedding Index Strategy

**Concern:** Plan doesn't explicitly mention reviewing OR updating `embedding-index.json` for existing verbs during bug fixes. If silk keywords change, embedding entries may become stale.

**Recommendation:** Document a checklist in PRE-WAVE: after fixing silk/craft bugs, audit `embedding-index.json` for:
1. Any old "silk" entries that now conflict with new keywords
2. Any recipe verb aliases that should be in embedding

---

### WAVE-1: Level 2 Foundation

#### ✅ Room Presence Strings

**Status:** Good — Smithers owns this, clean scope.

- **Task:** "Add `room_presence` strings for all new objects placed in Level 2 rooms (salt, provisions, cold-water, scattered bones, web obstacles)"
- **What's needed:** Sensory descriptions for:
  - Salt (deep-storage shelf)
  - Provisions (deep-storage shelves)
  - Cold water (underground-stream)
  - Scattered bones (wolf-den)
  - Web obstacles (spider-cavern)
- **Parser impact:** None (room presence is UI, not parser input)
- **Sensory consistency:** ✅ Each object MUST have `on_feel` (primary sense in darkness). Plan implicitly assumes this; no risk.
- **Recommendation:** Coordinate with Flanders on salt object definition — ensure Flanders provides `on_feel`, `on_taste`, `on_smell` for salt before Smithers writes room presence strings for it.

#### ✅ Embedding Index Update (Level 2 Nouns)

**Status:** Good — nouns identified implicitly.

- **New nouns:** werewolf, wolf (already exists), spider (already exists), salt (WAVE-3), catacombs, cellar, stone, water, bones, webs, lair, den
- **Action:** Add Level 2-specific nouns to `src/assets/parser/embedding-index.json` during WAVE-1
- **Priority:** Medium (Tier 2 will fall back to Tier 3 GOAP if noun not in index, so not blocking)
- **Recommendation:** Batch with WAVE-3 updates (salt aliases) to minimize embedding index changes. **Two passes:**
  - WAVE-1: Add room/geography nouns (catacombs, cellar, lair, den, etc.)
  - WAVE-3: Add salt + preservation aliases

#### ✅ Test Coverage

**Status:** Good — Nelson's tests adequate.

- Coverage includes room loading, brass-key transition, creature placement
- No parser-specific tests needed (embedding index validation happens at GATE-4)

---

### WAVE-2: Pack Tactics

#### ✅ Pack Narration

**Status:** Good — verb ownership clear.

- **Task:** Add coordinated attack narration to `src/engine/verbs/combat.lua`
- **Required messages:**
  - "The alpha wolf lunges first..."
  - "The pack follows in sequence..."
  - "The omega wolf retreats, whimpering."
- **Parser impact:** None (narration is output, not parser input)
- **Concern:** Plan says "Distinct messages" but doesn't specify:
  - Should narration vary by attack outcome (hit/miss)?
  - Should different creatures (wolf vs werewolf) have different narration?
  - Does narration need to respect `--headless` mode suppression?
- **Headless mode compatibility:** ✅ All text output should suppress in headless. Assumption: narration uses same `print()` dispatch as other combat output, which respects headless flag.
- **Recommendation:** Ensure narration is routed through `context:emit()` or equivalent, not raw `print()`, so headless suppression works. Verify with Bart on combat emit patterns.

---

### WAVE-3: Salt Preservation System

#### ✅ Salt Verb Handler + Aliases

**Status:** Good — comprehensive scope.

- **Owner:** Smithers
- **Files:** Modify `src/engine/verbs/crafting.lua` (or create `preservation.lua` if crafting > 500 LOC)
- **Verb:** `salt`
- **Aliases:** `preserve`, `cure`, `rub salt on`
- **Logic:**
  1. Requires salt object in one hand
  2. Requires meat object in other hand
  3. Validates target has `preservable = true`
  4. Triggers mutation on meat
  5. Consumes salt (1 use)
- **Parser impact:** Strong — verb dispatcher recognizes `salt` + aliases
- **Error messages (implicit):**
  - "You don't have salt in hand"
  - "You need to be holding the meat"
  - "You can't salt that"
  - "The salt crumbles away as you work..." (narration on success)
- **Recommendation:** Clarify error message wording in verb definition before coding. E.g., should "You don't have salt" say "preservative" or "salt"? Should it say "in one hand" explicitly?
- **Headless compatibility:** ✅ Error messages and success narration must route through context emit, not print

#### ✅ Embedding Index: Salt Aliases

**Status:** Good — clear requirement.

- **Task:** Add `salt`, `preserve`, `cure`, `rub salt` to embedding index
- **Concern:** "Verify no collision with existing entries" — good practice, but no explicit audit checklist
- **Recommendation:** Audit Phase 4 verbs + embedding for:
  - Does `preserve` already exist? (preservation context)
  - Does `cure` already exist? (injury/poison context — YES, cure poison exists)
  - Does `salt` alias with food/cook? (unlikely, but check)
- **Action:** Before finalizing embedding, search existing verbs for semantic overlap with preserve/cure/salt
- **Headless impact:** None (embedding index is parser-side, not user-visible)

#### ✅ Salt Object Definition

**Status:** Good — Flanders owns object, Smithers just updates embedding.

- **File:** `src/meta/objects/salt.lua` (Flanders, WAVE-3)
- **Parser concern:** Object keywords must not collide with existing salt references (unlikely)
- **Keywords expected:** `salt`, `rock salt`, `salt crystals`, `mineral`, `preservative`
- **UI requirements:** None for Smithers (Flanders defines all sensory fields)

#### ✅ Preservation Narration

**Status:** Good — scoped similarly to pack narration.

- **Task:** "Preservation narration (salting process, salted-meat descriptions)"
- **What's needed:**
  - Success message: "You rub salt into the wolf meat. It glistens with crystalline preservative..." (example from plan)
  - Salted-meat sensory updates: `on_feel`, `on_taste`, `on_smell` differ from fresh
- **Parser impact:** None (narration is output)
- **Concern:** Plan doesn't specify if Smithers writes meat descriptions OR just ensures narration flow. **RECOMMENDATION:** Clarify: Smithers writes verb narration only; Flanders defines salted-meat sensory fields (on_feel, etc.). No overlap.
- **Headless compatibility:** ✅ Must route through context emit

#### ⚠️ Tool System Integration

**Concern:** Plan mentions "Requires: salt object in one hand, meat object in other hand." and "tool requirement (container)" in multiple places.

- **Q1:** Is salt checked via `provides_tool = "preservative"` (Principle 8 — engine checks, not verb)?
- **Q2:** If salt is consumable with `uses = 3`, does verb code handle decrement, or does engine?
- **Clarification in plan:** "Salt object → tool system: `provides_tool = "preservative"` checked by `find_tool_in_hands()`" — **GOOD**, explicit engine integration
- **Recommendation:** Verify `find_tool_in_hands()` exists and correctly decrements consumable `uses`. If not, file task for Bart.

---

### Verb Aliases & Keyword Strategy

#### ✅ Existing verb coverage

- **Silk:** disambiguated in PRE-WAVE (no new aliases needed, just better keywords)
- **Salt:** three aliases defined (preserve, cure, rub salt on) — good coverage for natural language
- **Pack narration:** verb is `attack` (existing), narration enhancement only

#### ⚠️ Alias collision risk

**Concern:** `preserve` and `cure` are semantically close to existing verbs.

- **Does `cure` conflict with `cure poison`?** Likely yes (injury verb). Plan doesn't mention precedence.
- **Does `preserve` conflict with existing preservation mechanics?** Unclear.
- **Recommendation:** Audit verb dispatch order in `src/engine/verbs/init.lua`:
  - If salt is checked first (most specific), collision unlikely
  - If cure/preserve dispatches are fuzzy-matched (Tier 5), order matters
  - Recommend explicit priority: `salt` verb > `cure poison` verb (both use Tier 2 embedding)

---

### Embedding Index Strategy

#### ✅ Index updates scoped

- PRE-WAVE: silk (if needed)
- WAVE-1: Level 2 nouns (catacombs, werewolf, lair, etc.)
- WAVE-3: salt aliases

#### ⚠️ Index maintenance process unclear

**Concern:** Plan doesn't specify:
1. **Who validates** embedding index quality after updates? (Nelson? Smithers?)
2. **When is it tested?** GATE-1 / GATE-3 / GATE-4?
3. **What's the fallback** if a new noun isn't in index?

**Clarification from plan:** "Embedding index updated (L2 nouns, salt, werewolf) — `lua test/parser/test-embedding-index.lua`" (GATE-4)

**Good:** Explicit test gate. **Concern:** Test is at GATE-4 (end of WAVE-4), which is too late if embedding gaps block Tier 2 noun resolution earlier.

**Recommendation:** Run embedding index tests earlier — after WAVE-1 (GATE-1) to verify Level 2 nouns resolve before pack tactics (WAVE-2) and salt (WAVE-3) depend on them.

---

### Room Presence & Sensory System

#### ✅ Sensory consistency (implicit)

- Plan assumes all objects have `on_feel` (dark-sense primary)
- No explicit requirement for Smithers to validate, but good to spot-check werewolf loot objects (Flanders responsibility)

#### ✅ Room descriptions

- Plan specifies room description template: "Permanent features only: walls, floor, atmosphere"
- Smithers responsible for `room_presence` strings for movable/creature objects — good separation
- No conflict between Moe (room descriptions) and Smithers (room presence)

---

### Error Messages & UX

#### ⚠️ Error message consistency

**Concern:** Plan doesn't define error messages for:
1. Silk disambiguation failures (PRE-WAVE) — what if both silk objects still match?
2. Recipe lookup failures (PRE-WAVE) — current error message acceptable?
3. Salt verb failures:
   - No salt in hand: "You don't have a preservative"? "You don't have salt"?
   - No meat in hand: "You need to be holding the meat"?
   - Meat not preservable: "That can't be preserved"?
   - Salt consumed: "The salt dissolves into the meat"?

**Recommendation:** Before WAVE-3 coding, define error message templates in a commit or document. Ensures consistency with Phase 4 verb tone and helps with localization.

#### ✅ Headless mode handling

- Plan explicitly mentions `--headless` in test scenarios (2.1–2.5)
- All narration must route through context emit, not raw print
- **No issues identified** — Smithers aware of headless requirement

---

### Parser Pipeline Integration

#### ✅ Tier 1 (Exact Verb Dispatch)

- Salt verb fits standard tier 1: `salt target`
- No new dispatch rules needed

#### ✅ Tier 2 (Embedding-based Matching)

- Salt aliases in embedding index improves Tier 2 hit rate
- Werewolf and Level 2 nouns in index (future-proofs Tier 2 for new encounters)

#### ✅ Tier 3 (GOAP Planning)

- No GOAP implications for Phase 5 verbs (salt, pack narration)
- Existing player planning (get knife → find wolf → butcher → salt) doesn't require new GOAP predicates

#### ✅ Tier 4–5 (Context & Fuzzy)

- No new requirements identified

---

### Cross-Wave Dependencies

#### ✅ No parser conflicts

- Silk fixes (PRE-WAVE) ✅ independent
- Pack narration (WAVE-2) ✅ independent of verb parsing
- Salt verb (WAVE-3) ✅ depends on WAVE-1 (Level 2 foundation exists) but not parsing
- Embedding updates (W1, W3) ✅ no timing conflicts

#### ✅ File ownership clear

| File | Smithers | Agent |
|------|----------|-------|
| `src/engine/verbs/crafting.lua` | ✅ MODIFY (PRE-WAVE + WAVE-3) | owned by Smithers |
| `src/engine/verbs/combat.lua` | ✅ MODIFY (WAVE-2) | owned by Smithers |
| `src/assets/parser/embedding-index.json` | ✅ MODIFY (PRE-WAVE, W1, W3) | owned by Smithers |
| `src/meta/objects/silk-{bundle,rope}.lua` | ✅ MODIFY (PRE-WAVE) | scoped to Smithers |

**No conflicts** — parallel waves (W2 + W3) don't touch Smithers files.

---

## Headless Mode Compatibility

### ✅ Explicit headless test scenarios

Plan includes 5 LLM scenarios with `--headless`:
1. Level 2 Exploration (GATE-1)
2. Werewolf Encounter (GATE-1/GATE-4)
3. Salt Preservation (GATE-3/GATE-4)
4. Pack Tactics (GATE-2/GATE-4)
5. Full Phase 5 Loop (GATE-4)

**Good:** Headless is not afterthought; it's part of pass/fail criteria.

### ⚠️ Headless text validation

**Concern:** Expected patterns in scenarios are reasonable, but plan doesn't specify:
1. Should narration appear in headless? (Recommendation: yes, but not prompts)
2. What about `---END---` delimiter? (Assumption: added by engine, not verbs)
3. Should error messages appear in headless? (Recommendation: yes)

**Recommendation:** Clarify with Nelson: in WAVE-4 LLM testing, what output is expected in headless for:
- Successful salt verb: narration + state change confirmation?
- Failed salt verb: error message?
- Pack combat: attack narration per turn?

---

## Documentation & Contracts

### ✅ Plan level adequacy

- Parser-UI responsibilities clearly assigned
- File ownership table unambiguous
- Test coverage specified

### ⚠️ No parsing documentation updates

**Concern:** Plan doesn't mention updating `docs/architecture/parser/` with new verb details or alias strategy.

**Recommendation:** After Phase 5 complete, update:
- `docs/architecture/parser/verb-system.md` with salt verb case study
- `docs/architecture/parser/embedding-index.md` with Phase 5 new nouns + aliases
- (Brockman / Smithers responsibility — document in WAVE-4)

---

## Summary of Findings

| Category | Status | Notes |
|----------|--------|-------|
| **Verb dispatch (salt)** | ✅ | Clear scope, three aliases, good precedent |
| **Embedding index** | ⚠️ | Updates needed (W1, W3); recommend earlier testing (before W2) |
| **Room presence** | ✅ | Well-scoped, no conflicts, sensory consistency assumed |
| **Pack narration** | ✅ | Clear scope, verb ownership confirmed |
| **Error messages** | ⚠️ | Not defined; recommend error template doc before WAVE-3 |
| **Headless mode** | ✅ | Explicit test scenarios, no compatibility issues |
| **File conflicts** | ✅ | No overlaps, parallel waves independent |
| **Parser pipeline** | ✅ | No new tiers needed, Tier 1-2 sufficient |
| **Documentation** | ⚠️ | Parser docs (post-GATE-4) not mentioned; recommend addition |

---

## Recommendations

### Before PRE-WAVE Start

1. **Define error message templates** for salt verb (and silk/craft bug fixes)
2. **Audit embedding index** for `preserve` and `cure` collisions with existing verbs
3. **Clarify embedding test gate** — move to GATE-1, not GATE-4

### During PRE-WAVE

1. After silk keyword update, run embedding index rebuild
2. Document precedence: if `preserve` matches both "salt" and "cure poison", which fires? (Recommend salt if more specific)

### During WAVE-1

1. Add Level 2 nouns to embedding index (catacombs, werewolf, lair, etc.)
2. Test embedding at GATE-1 (not GATE-4)

### During WAVE-3

1. Coordinate with Flanders on salt object sensory fields before writing room presence
2. Ensure salt verb error handling covers consumable depletion (`uses` decrement)

### During WAVE-4

1. Update parser documentation with salt verb + alias case study
2. Validate headless mode with Nelson LLM scenarios

---

## Risk Register (Smithers Perspective)

| # | Risk | Impact | Mitigation |
|---|------|--------|-----------|
| S1 | Embedding index stale → Tier 2 misses `salt` verb in W3 | Low–Med | Test embedding at GATE-1, not GATE-4 |
| S2 | `preserve`/`cure` alias collision with injury system | Low | Audit verb dispatch order; explicit priority in PRE-WAVE |
| S3 | Salt consumable uses not decremented → breaks replayability | Med | Verify tool system handles decrement; test in WAVE-3 |
| S4 | Narration not headless-aware → breaks automated testing | Low | Ensure all emit() calls route via context, spot-check in WAVE-2 |
| S5 | Room presence strings for werewolf loot conflict with Flanders definitions | Low | Coordinate sensory fields with Flanders early (PRE-WAVE communication) |

---

## Approval

✅ **Smithers recommends GATE PASSAGE** for Phase 5 as planned, with recommendations above noted for concurrent action.

**Sign-off:** This plan is actionable. Smithers can execute PRE-WAVE independently; no blockers identified.

---

**END OF REVIEW**
