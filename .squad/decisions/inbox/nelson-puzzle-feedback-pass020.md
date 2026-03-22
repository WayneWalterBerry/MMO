# Puzzle Feedback — Pass 020
**Date:** 2026-03-21  
**Tester:** Nelson  
**Context:** Comprehensive play test attempt

---

## Summary

**Tests Completed:** 0 puzzle tests  
**Reason:** Blocked at critical path before reaching puzzle content

---

## Critical Path Feedback

### The Darkness Opening (Puzzle 000?)

**What Works:**
- ✅ Atmospheric — waking in total darkness is compelling
- ✅ Clear guidance — "Try 'feel' to explore the darkness"
- ✅ Intuitive progression — feel → discover → open → take
- ✅ Prose quality exceptional throughout

**What's Broken:**
- 🔴 **BLOCKER:** Container contents not revealed when examining
- Player opens drawer but has NO way to discover matchbox inside
- This breaks the entire puzzle chain

**Design Question:**
- Match burn time is ~1 turn (too short to type look before it dies)
- Is this intentional? Forces player to find candle?
- If so, consider adding hint: "The match won't last long — find a candle!"
- Otherwise players will waste all matches trying to see room

**Player Experience (if bug were fixed):**
1. Wake in darkness ← Great hook ✅
2. Feel around, discover furniture ← Intuitive ✅
3. Open nightstand ← Works ✅
4. **Examine drawer to find matchbox** ← BROKEN ❌
5. Light match ← Beautiful prose ✅
6. Match dies too fast to use ← Frustrating? 🤔
7. Find candle for sustained light ← Haven't reached this

**Recommendation:**
Once BUG-065 is fixed, the opening puzzle flow should be solid. The match burn time might need balancing or clearer hints.

---

## Puzzle 015: Candle Extinguish (Draft)

**Status:** NOT TESTED THIS PASS  
**Prior Result (Pass-017):** ✅ WORKING (BUG-060 fixed)  
**No feedback changes.**

---

## Puzzle 016: Wine Drinking FSM

**Status:** NOT TESTED THIS PASS  
**Prior Result (Pass-017):** 🔴 BROKEN (BUG-061 NOT fixed)  
**Prior Failure:** 0/6 tests passed  
**Recommendation:** Needs dedicated retest after BUG-065 resolved

---

## Injury/Bandage/Poison Systems (NEW)

**Status:** UNABLE TO TEST  
**Reason:** Blocked at critical path, cannot navigate to weapon/item locations

**Questions for Future Test:**
- Are injury descriptions satisfying?
- Is per-turn damage drain too fast/slow?
- Do bandages feel meaningful?
- Is poison damage balanced?
- Are there enough clues about healing?

**Recommendation:** Schedule dedicated injury system test (Pass-021) after navigation unblocked.

---

## Overall Assessment

**Cannot provide puzzle feedback** because I'm stuck in the dark bedroom due to BUG-065.

The game **feels** like it would be fun IF the critical path worked. The prose is excellent, the FSM systems (match lighting) are elegant, and the atmosphere is compelling.

But right now, it's unplayable for a new user who doesn't know to type `get matchbox` blindly.

**Priority:** Fix BUG-065, then re-run comprehensive test.

---

**Submitted by:** Nelson  
**To:** Squad (Effe, Clive, Jasper, Kate)  
**Urgency:** HIGH — Blocks all further testing
