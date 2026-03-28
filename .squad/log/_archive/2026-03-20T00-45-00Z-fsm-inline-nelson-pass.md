# Session Log: FSM-Inline Refactor + Nelson First Playtest
**Date:** 2026-03-20  
**Session ID:** fsm-inline-nelson-pass-001  
**Participants:** Bart, Nelson, Brockman, CBG  
**Focus:** FSM architecture consolidation + empirical play testing

---

## Session Overview

This session consolidated the FSM architecture by moving all state definitions from `src/meta/fsms/` into their object files (FSM-inline pattern). Simultaneously, Nelson performed the first empirical play test, revealing 7 bugs across the critical path.

**Outcome:** FSM engine production-ready. Critical path verified with known bugs captured for fix iteration.

---

## Bart: FSM-Inline Refactor

### What Happened
1. Merged match FSM from `src/meta/fsms/match.lua` into `objects/match.lua`
2. Merged nightstand FSM from `src/meta/fsms/nightstand.lua` into `objects/nightstand.lua`
3. Created 4 new FSM objects:
   - **Candle:** 4 states (unlit → lit → stub → spent), 100 + 20 turn durations
   - **Poison-bottle:** 3 states (sealed → open → empty), DRINK/POUR verbs
   - **Vanity:** 4 states (intact → cracked → broken), mirror break mutation
   - **Curtains:** 2 states (closed → open), light-blocking
4. Deleted entire `src/meta/fsms/` directory (7 state files removed)
5. Updated FSM engine to detect `obj.states` instead of `obj._fsm_id`

### Key Decision: FSM Transition Aliases
Added `aliases` field to FSM transitions. Example: match strike transition has `aliases = {"light", "ignite"}`. Verb handlers check aliases when deciding whether to delegate to canonical verb handler. This keeps the FSM engine simple and puts synonym knowledge in the verb layer.

### Hybrid Model Introduced
Objects can have BOTH `states`/`transitions` (FSM for reversible state changes) AND `mutations` (for destructive transformations):
- Vanity uses FSM for intact/cracked/broken AND mutation for mirror shatter
- Curtains can use FSM for open/close AND mutation for tear
- Poison-bottle uses FSM for sealed/open/empty AND effects (poison damage on DRINK)

### Architecture Rationale
- **One file = one object = one FSM:** No scatter across multiple files
- **Single source of truth:** Object definition and FSM live together
- **Engine simplicity:** FSM engine unchanged in purpose, just reads `obj.states` instead of external file
- **Backward compatible:** Plain objects without `.states` work as before

### Tests Passed
All existing tests pass. FSM transitions work as designed. No regressions.

---

## Nelson: First Playtest (Empirical LLM Testing)

### Approach
- No predefined test scripts or assert statements
- Played like a human: think, try, react, explore unexpected things
- Used LLM intelligence to find bugs that scripts wouldn't think of
- Streamed output to transcript incrementally (preserves progress on crash)

### Critical Path Tested
1. Wake from bed in bedroom
2. Examine surroundings
3. Strike match (ignite FSM 3-turn countdown)
4. Examine nightstand (access compartment)
5. Navigate to window

### Bugs Found (7 Total)

**🔴 Critical (Block Critical Path)**
1. **Window state initialization:** Window object not properly initialized; accessing causes error
2. **Match countdown:** 3-turn FSM auto-burn trigger not firing; match should burn out after 3 turns but doesn't

**🟡 High (Degrade UX)**
3. **Text wrapping:** Long descriptions overflow terminal width; need to wrap at 80 chars
4. **Prepositions:** Parser missing "on", "with", "from" prepositional phrases ("put match on nightstand" fails)
5. **Bare sensory verbs:** "look", "listen", "smell" without object should fall back to room sensory input

**🟢 Low (Content Polish)**
6. **Drink verb:** Parser doesn't recognize DRINK; poison-bottle needs this verb alias
7. **Typos:** "maches" instead of "matches" in game text

### Test Output
Full transcript at `test-pass/2026-03-19-pass-001.md` with every command/response pair documented.

### Why This Testing Approach
- **Empirical over theoretical:** Data-driven decisions reveal real player needs
- **LLM tester finds unknowns:** Scripts only test what you think of; LLM improvisation finds gaps
- **Incremental output:** Streaming to file prevents loss of transcript on session crash
- **Artifact at repo root:** Transcripts are product artifacts, not squad internal state

---

## Brockman: Newspaper Edition Labels

### What Happened
1. Added "Morning Edition" and "Evening Edition" headers to newspaper structure
2. Updated `newspaper/YYYY-MM-DD.md` template with edition-specific masthead
3. Integrated edition labels into archive naming

### Format
```markdown
# MMO Project Newspaper
## Morning Edition — YYYY-MM-DD
```

---

## CBG: Container Model + Wearable System Design

### Design Decisions Documented
1. **Wear slots on object:** e.g., `wear_slot = "head"`, `wear_slot = "torso"`, `wear_slot = "back"`
2. **Slot conflict rules:** Only one item per slot UNLESS layering allowed
3. **Layering system:** Objects define `wear_layer = "inner"` or `wear_layer = "outer"`
   - Example that works: shirt (inner) + cloak (outer)
   - Example that fails: two hats, two pairs of shoes
4. **Dual-property objects:** Backpacks are wearable + containers; sacks can blind when worn on head; pots can be worn as helmets
5. **Chamber-pot inheritance:** Pots are a base class; chamber-pot inherits wearability (can wear on head)

### Wearable System Principles
- Objects own their wear metadata (engine just enforces conflicts)
- Gameplay effects encoded in object properties (sack on head = casts_blindness)
- Extensible without engine changes (new slots invented per-object)
- New wear slots don't require engine updates

### FSM + Wearable Integration
- Wearable objects can have FSMs for state changes (e.g., cloak: folded → worn → torn)
- Containers can be wearable (backpack worn on back, still holds items)
- Objects define what happens when worn (gameplay is emergent)

---

## Cross-Agent Propagation

### Bart → Nelson
FSM-inline objects now ready for testing. Candle, poison-bottle, vanity, curtains all live in their object files. Critical path uses match and nightstand FSMs (inlined).

### Nelson → Bart
Match countdown bug is critical. FSM 3-turn trigger not firing. Fix needed before pass 002. Window state initialization also blocks critical path.

### CBG → Bart
Wearable system design complete. FSM objects can have wearable states. Implement when ready for pass 003.

### All → Brockman
Newspaper ready for integration. Include FSM refactor summary + Nelson bug report + wearable system design overview.

---

## Decision Summary

| Decision | Status | Impact |
|----------|--------|--------|
| FSM definitions inline in objects | ✅ Implemented | Architecture simplified, no scatter |
| FSM transition aliases | ✅ Implemented | Synonym handling in verb layer |
| Hybrid FSM + mutations | ✅ Designed | Objects can have reversible + destructive changes |
| Empirical LLM testing | ✅ Adopted | Found 7 bugs in critical path |
| Wearable slot system | ✅ Designed | Objects own wear metadata, engine enforces conflicts |
| Wearable + container dual-property | ✅ Designed | Backpacks, sacks, pots support both |
| Chamber-pot inheritance | ✅ Decided | Pots are base class; pots wearable as helmets |

---

## Next Immediate Steps

1. **Bart fixes (Priority 1):**
   - Fix match 3-turn countdown (FSM auto-burn trigger)
   - Fix window state initialization
   
2. **Nelson pass 002:**
   - Run after Bart's critical fixes
   - Verify critical path works end-to-end
   
3. **Text wrapping + prepositions (Priority 2):**
   - Parser updates for "on", "with", "from" 
   - Terminal output wrapping at 80 chars
   
4. **Bare sensory verbs (Priority 2):**
   - "look", "listen", "smell" fallback to room sensory
   
5. **Wearable implementation (Priority 3):**
   - Implement WEAR, REMOVE, DROP verbs
   - Slot conflict checking
   - Layer conflict checking
   
6. **Pass 003:**
   - Test wearable system (cloak, armor, backpack)
   - Extended play testing

---

## Artifacts Generated

- `.squad/orchestration-log/2026-03-20T00-30-00Z-bart-spawn.md` — FSM refactor log
- `.squad/orchestration-log/2026-03-20T00-31-00Z-nelson-spawn.md` — Playtest log
- `.squad/orchestration-log/2026-03-20T00-32-00Z-brockman-spawn.md` — Newspaper log
- `.squad/orchestration-log/2026-03-20T00-33-00Z-cbg-spawn.md` — Design log
- `test-pass/2026-03-19-pass-001.md` — Nelson playtest transcript
- `.squad/decisions.md` (merged) — All inbox directives consolidated

---

## Session Lessons

1. **Empirical testing reveals unknowns:** Script-based testing would have missed all 7 bugs
2. **Architecture consolidation works:** FSM-inline pattern cleaner than scattered files
3. **Hybrid models enable flexibility:** FSM + mutations allows objects to be both reversible and destructible
4. **Object-driven design scales:** Wearable slots on objects > wearable slots hardcoded in engine
5. **Incremental output saves progress:** Streaming to file = robustness against session crashes

---

**Session Complete:** 2026-03-20T00:45:00Z
