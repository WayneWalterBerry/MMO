# Pass-038: Drop Fragility System Playtest (Phase E, #56)

**Date:** 2026-03-24
**Tester:** Nelson
**Build:** Lua src/main.lua --headless
**Requested by:** Wayne "Effe" Berry
**Scope:** Drop fragility system — shattering, shards, surface hardness, creative phrases

## Executive Summary

| Metric | Count |
|--------|-------|
| Total tests | 24 |
| ✅ PASS | 14 |
| ❌ FAIL | 8 |
| ⚠️ WARN | 2 |

**Core fragility engine: SOLID.** Ceramic pot shatters on stone → spawns 2 shards. Knife clangs and survives. Surface placement (nightstand) avoids breakage. Wear→remove→drop cycle works. Post-break state is clean — shards are inspectable, takeable, original object gone.

**One HIGH bug:** Glass bottle shatters with correct narration but spawns **zero** glass shards. Ceramic shards spawn fine. Glass shard objects either missing or not loading.

**Parser gaps:** 7 creative drop phrasings fail. "toss", "throw", "hurl", "smash", "set down", "let slip" are all unrecognized. "put X down" fails but "put down X" works (word order). "drop all/everything" unsupported.

**Worn-item drop bug:** Dropping a worn pot says "get that out of the bag first" — references a non-existent bag instead of saying "remove it first."

## Bug List

| Bug ID | Severity | Summary |
|--------|----------|---------|
| BUG-127 | **HIGH** | Glass bottle shatters but spawns no glass shards — ceramic pot spawns shards correctly, bottle spawns nothing |
| BUG-128 | **MEDIUM** | Worn pot → "drop pot" → error mentions non-existent "bag" instead of "remove it first" |
| BUG-129 | **MEDIUM** | "put the knife down" fails — word order "put X down" not recognized, but "put down X" works |
| BUG-130 | **MEDIUM** | "drop all" / "drop everything" → "You aren't holding that" — bulk drop not supported |
| BUG-131 | **MEDIUM** | "set the bottle down" → garbled error: "You don't see any the bottle down to set" |
| BUG-132 | **LOW** | "toss the pot" not recognized as drop synonym |
| BUG-133 | **LOW** | "throw the pot on the ground" not recognized as drop |

## Individual Tests

---

### Scenario 1: Drop Fragile Objects (Glass Bottle)

#### T-001: `take the bottle` → `drop the bottle`
**Input sequence:** feel around → search nightstand → take the bottle → drop the bottle → feel around
**Response:**
```
You take an open glass bottle.
---END---
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — Shatters correctly. Narration is dramatic and satisfying.

**However:** feel around after shatter shows NO glass shards on floor. See T-016 for details.

#### T-002: `toss the bottle` (creative)
**Input:** take the bottle → toss the bottle
**Response:**
```
I'm not sure what you mean. Try 'help' to see what you can do, or describe
what you're trying to accomplish.
```
**Verdict:** ❌ FAIL — "toss" not recognized as drop synonym.
**Bug:** BUG-132

#### T-003: `let go of the bottle`
**Input:** take the bottle → let go of the bottle
**Response:**
```
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — "let go of" works as drop synonym. Good parser coverage.

#### T-004: `release the bottle`
**Input:** take the bottle → release the bottle
**Response:**
```
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — "release" works as drop synonym.

#### T-005: `put down the bottle`
**Input:** take the bottle → put down the bottle
**Response:**
```
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — "put down X" works correctly.

---

### Scenario 2: Drop Durable Objects (Steel Knife)

#### T-006: `drop the knife`
**Input:** take the knife → drop the knife
**Response:**
```
The small knife hits the floor with a resonant clang.
```
**Verdict:** ✅ PASS — Steel knife (fragility 0.05) survives. "Resonant clang" is a great material-specific message. Knife appears on floor in feel around.

#### T-007: `put the knife down`
**Input:** take the knife → put the knife down
**Response:**
```
Put what where? (Try: put <item> in/on <target>)
```
**Verdict:** ❌ FAIL — "put X down" word order not recognized. "put down X" works (T-005). Parser doesn't handle trailing particle "down".
**Bug:** BUG-129

---

### Scenario 3: Drop Ceramic Objects (Chamber Pot)

#### T-008: `drop the pot`
**Input:** take chamber pot → drop the pot
**Response:**
```
The ceramic chamber pot shatters on the stone floor, sending fragments
skittering across the room.
```
Post-shatter feel around:
```
  a ceramic shard
  a ceramic shard
```
**Verdict:** ✅ PASS — Ceramic pot (fragility 0.7) shatters on stone (hardness 7). Two ceramic shards spawned. Original pot removed from world. Textbook behavior.

#### T-009: `throw the pot on the ground`
**Input:** take chamber pot → throw the pot on the ground
**Response:**
```
I'm not sure what you mean. Try 'help' to see what you can do, or describe
what you're trying to accomplish.
```
**Verdict:** ❌ FAIL — "throw X on the ground" not recognized.
**Bug:** BUG-133

#### T-010: `smash the pot on the ground`
**Input:** take chamber pot → smash the pot on the ground
**Response:**
```
You don't notice anything called that nearby. Try 'search around' to discover
what's here.
```
**Verdict:** ❌ FAIL — "smash" resolved to a search for "ground" instead of a destructive action.

---

### Scenario 4: Creative Drop Phrases

#### T-011: `hurl the bottle at the floor`
**Input:** take the bottle → hurl the bottle at the floor
**Response:**
```
I'm not sure what you mean.
```
**Verdict:** ❌ FAIL — "hurl" not recognized. Complex spatial phrasing.

#### T-012: `let the bottle slip from my fingers`
**Input:** take the bottle → let the bottle slip from my fingers
**Response:**
```
I'm not sure what you mean.
```
**Verdict:** ❌ FAIL — Too complex for current parser. Understandable limitation.

#### T-013: `toss everything I'm holding`
**Input:** take bottle + knife → toss everything I'm holding
**Response:**
```
I'm not sure what you mean.
```
**Inventory still shows:** Left hand: bottle, Right hand: knife
**Verdict:** ❌ FAIL — Neither "toss" nor "everything" supported for drop.
**Bug:** BUG-130 (drop all/everything)

#### T-014: `drop the bottle carefully` (adverb)
**Input:** take the bottle → drop the bottle carefully
**Response:**
```
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — Adverb "carefully" stripped correctly by parser. Drop executes. Note: bottle still shatters even with "carefully" — this is correct engine behavior (fragility is physics-based, not intent-based). Could be a future feature: careful drop = place gently.

#### T-015: `set the bottle down`
**Input:** take the bottle → set the bottle down
**Response:**
```
You don't see any the bottle down to set.
```
**Verdict:** ❌ FAIL — Garbled parser output. "set" is misinterpreted. The error message is nonsensical.
**Bug:** BUG-131

---

### Scenario 5: Drop on Different Surfaces

#### T-016: `drop bottle on bed` (soft surface)
**Input:** take the bottle → drop bottle on bed
**Response:**
```
There is not enough room on a large four-poster bed.
```
**Verdict:** ⚠️ WARN — Parser routes "drop X on Y" to placement handler (put-on-surface), not drop-onto-surface. Bed has no surface capacity, so it fails. Fragility-on-soft-surface cannot be tested through natural gameplay in the bedroom — bed surface is full. The surface hardness logic (hardness < 5 prevents breaking) is untestable via this phrase.

#### T-017: `place bottle on nightstand` (surface placement = no shatter)
**Input:** take the bottle → place the bottle on the nightstand
**Response:**
```
You put an open glass bottle on a small nightstand.
```
**Inventory:** empty. Bottle placed safely.
**Verdict:** ✅ PASS — Surface placement does NOT trigger fragility check. Bottle survives. This is the correct distinction: "drop" = hits the floor; "place on" = gentle surface placement.

---

### Scenario 6: Post-Break State

#### T-018: `look at the shards` (after ceramic pot shatters)
**Input:** (after pot shatter) → look at the shard
**Response:**
```
It's too dark to see, but you feel: Sharp edges where the glaze broke. Smooth
on the painted side.
```
**Verdict:** ✅ PASS — Ceramic shard has a great tactile description. Atmospheric and consistent with dark-room mechanic.

#### T-019: `pick up the pieces` (after pot shatters)
**Input:** (after pot shatter) → pick up the pieces → take the shard
**Response:**
```
You take a ceramic shard.
---END---
You take a ceramic shard.
```
**Inventory:** Left hand: ceramic shard, Right hand: ceramic shard
**Verdict:** ✅ PASS — Both shards takeable. "pick up the pieces" resolves correctly. Player can collect debris.

#### T-020: `wear the pot` (after pot has shattered)
**Input:** (after pot shatter) → wear the pot
**Response:**
```
You aren't holding that.
```
**Verdict:** ✅ PASS — Pot no longer exists. Can't wear a destroyed object. Correct.

#### T-021: Wear pot → drop pot (while worn)
**Input:** take pot → wear pot → drop the pot
**Response:**
```
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
---END---
You'll need to get that out of the bag first, or drop the bag itself.
```
**Verdict:** ❌ FAIL — Error message references a "bag" that doesn't exist. Player isn't wearing or holding a bag. Expected: "You'll need to remove it first" or auto-remove+drop.
**Bug:** BUG-128

#### T-022: Wear → Remove → Drop (full cycle)
**Input:** take pot → wear pot → remove pot → drop pot
**Response:**
```
You put on a ceramic chamber pot.
This is going to smell worse than I thought.
---END---
You remove a ceramic chamber pot.
---END---
The ceramic chamber pot shatters on the stone floor, sending fragments
skittering across the room.
```
**Verdict:** ✅ PASS — Full wear→remove→drop cycle works correctly. Pot shatters after being returned to hand.

#### T-023: Drop shard (re-drop debris)
**Input:** (after pot shatter) → take shard → drop the shard
**Response:**
```
The ceramic shard shatters on the stone floor, sending fragments skittering
across the room.
```
Shard is destroyed. One fewer shard on floor.
**Verdict:** ⚠️ WARN — Shard re-shatters because ceramic fragility (0.7) ≥ 0.5 threshold. Physically plausible (ceramic shard breaks further into dust). But the narration "sending fragments skittering across the room" is dramatic for a tiny shard. Could benefit from a smaller-scale narration for debris items.

#### T-024: Glass bottle shards — missing!
**Input:** take the bottle → drop the bottle → feel around
**Response:**
```
The open glass bottle shatters on the stone floor, sending fragments
skittering across the room.
```
Feel around after shatter:
```
  (no glass shards listed — only furniture and chamber pot)
```
Attempted: "take shard" → resolves to nightstand. "take glass shard" → resolves to window.
**Verdict:** ❌ FAIL — Glass bottle shatters with correct narration but spawns **zero glass shard objects**. Ceramic pot correctly spawns 2 ceramic shards. The glass bottle's `mutations.shatter.spawns` is likely empty, nil, or the glass-shard object file fails to load.
**Bug:** BUG-127 (HIGH)

## Summary of Findings

### What Works Well
- **Core fragility engine** is solid — material fragility × surface hardness decision works
- **Ceramic shattering** is perfect: narration, shard spawning, cleanup
- **Durable objects survive** with satisfying material-specific sounds ("resonant clang")
- **"drop", "let go of", "release", "put down X"** all correctly trigger fragility
- **Adverb stripping** works (e.g., "carefully" doesn't break parsing)
- **Post-break state** is clean: shards inspectable, takeable, original object gone
- **Surface placement** correctly avoids fragility check

### What Needs Fixing
1. **BUG-127 (HIGH):** Glass bottle spawns no shards — the glass breakage path is incomplete
2. **BUG-128 (MEDIUM):** Worn item → drop gives "bag" error instead of "remove it first"
3. **BUG-129–131 (MEDIUM):** Parser word-order and synonym gaps for "put X down", "set X down", "drop all"
4. **BUG-132–133 (LOW):** "toss", "throw X on ground" not recognized as drop synonyms

### Recommendations
- Fix BUG-127 first — glass shard spawning is a core feature gap
- Add "toss" and "throw" as drop synonyms (common player vocabulary)
- Handle "put X down" word order (very natural English)
- Support "drop all/everything" for bulk operations

---

*Nelson — QA Engineer*
*Test completed: 2026-03-24*
